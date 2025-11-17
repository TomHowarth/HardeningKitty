#!/usr/bin/env python3
"""
HardeningKitty-Linux - Linux System Hardening Tool
Refactored from Windows HardeningKitty for Rocky Linux

Based on CIS Benchmarks, DISA STIG, and security best practices
Author: Refactored for Linux
License: MIT
"""

import sys
import os
import argparse
import csv
import json
from datetime import datetime
from pathlib import Path

# Import local modules
from lib import audit, hardening, backup, reporting, utils, methods


__version__ = "1.0.0"
__author__ = "HardeningKitty-Linux Team"


class HardeningKitty:
    """Main HardeningKitty class for Linux system hardening"""

    def __init__(self, args):
        self.args = args
        self.findings = []
        self.results = []
        self.stats = {
            'passed': 0,
            'low': 0,
            'medium': 0,
            'high': 0,
            'error': 0,
            'total': 0
        }

        # Default finding list path
        self.default_finding_list = Path(__file__).parent / "lists_linux" / "finding_list_cis_rocky_8_server_l1.csv"

        # Validate privilege requirements
        if args.mode in ['hailmary', 'restore'] and os.geteuid() != 0:
            utils.log_error("This mode requires root privileges. Please run with sudo.")
            sys.exit(1)

    def load_finding_list(self, file_path=None):
        """Load finding list from CSV file"""
        if file_path is None:
            file_path = self.default_finding_list

        if not os.path.exists(file_path):
            utils.log_error(f"Finding list not found: {file_path}")
            sys.exit(1)

        utils.log_info(f"Loading finding list: {file_path}")

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                self.findings = list(reader)

            utils.log_success(f"Loaded {len(self.findings)} findings")
            return True
        except Exception as e:
            utils.log_error(f"Failed to load finding list: {e}")
            sys.exit(1)

    def apply_filters(self):
        """Apply filters to finding list"""
        if not self.args.filter:
            return

        original_count = len(self.findings)

        # Filter by ID
        if self.args.filter_id:
            self.findings = [f for f in self.findings if f['ID'] == self.args.filter_id]

        # Filter by category
        if self.args.filter_category:
            self.findings = [f for f in self.findings if self.args.filter_category.lower() in f['Category'].lower()]

        # Filter by severity
        if self.args.filter_severity:
            self.findings = [f for f in self.findings if f['Severity'].lower() == self.args.filter_severity.lower()]

        # Filter by method
        if self.args.filter_method:
            self.findings = [f for f in self.findings if f['Method'].lower() == self.args.filter_method.lower()]

        utils.log_info(f"Filtered from {original_count} to {len(self.findings)} findings")

    def run_audit_mode(self):
        """Run audit mode - assess current configuration"""
        utils.log_header("HardeningKitty-Linux - Audit Mode")
        utils.log_info(f"Version: {__version__}")
        utils.log_info(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        utils.log_info("")

        # Load finding list
        self.load_finding_list(self.args.finding_list)
        self.apply_filters()

        # Run audit
        utils.log_info("Starting system audit...")
        utils.log_info("")

        self.results = audit.run_audit(self.findings, self.args.emoji)

        # Calculate statistics
        self.calculate_stats()

        # Display results
        self.display_results()

        # Generate reports
        if self.args.report:
            reporting.generate_csv_report(self.results, self.args.report)

        if self.args.log:
            reporting.generate_log_file(self.results, self.args.log)

    def run_config_mode(self):
        """Run config mode - export current configuration"""
        utils.log_header("HardeningKitty-Linux - Config Mode")
        utils.log_info(f"Version: {__version__}")
        utils.log_info("")

        # Load finding list
        self.load_finding_list(self.args.finding_list)
        self.apply_filters()

        # Export configuration
        config_data = backup.export_configuration(self.findings)

        # Save to file if backup requested
        if self.args.backup:
            backup_file = self.args.backup_file or f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            backup.save_backup(config_data, backup_file)
            utils.log_success(f"Configuration saved to: {backup_file}")

        # Display configuration
        if not self.args.quiet:
            utils.log_info("Current Configuration:")
            for item in config_data:
                print(f"  {item['ID']} - {item['Name']}: {item['CurrentValue']}")

    def run_hailmary_mode(self):
        """Run HailMary mode - apply hardening settings"""
        utils.log_header("HardeningKitty-Linux - HailMary Mode")
        utils.log_warning("WARNING: This mode will modify system configuration!")
        utils.log_info("")

        # Confirm action unless --yes flag is provided
        if not self.args.yes:
            response = input("Are you sure you want to proceed? (yes/no): ")
            if response.lower() not in ['yes', 'y']:
                utils.log_info("Operation cancelled.")
                sys.exit(0)

        # Create backup before changes
        if not self.args.skip_backup:
            utils.log_info("Creating system backup...")
            self.load_finding_list(self.args.finding_list)
            config_data = backup.export_configuration(self.findings)
            backup_file = self.args.backup_file or f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            backup.save_backup(config_data, backup_file)
            utils.log_success(f"Backup saved to: {backup_file}")
            utils.log_info("")

        # Load finding list
        self.load_finding_list(self.args.finding_list)
        self.apply_filters()

        # Apply hardening
        utils.log_info("Applying hardening settings...")
        results = hardening.apply_hardening(self.findings)

        # Display results
        utils.log_info("")
        utils.log_header("Hardening Results")

        success_count = sum(1 for r in results if r['applied'])
        failed_count = len(results) - success_count

        utils.log_success(f"Successfully applied: {success_count}")
        if failed_count > 0:
            utils.log_warning(f"Failed to apply: {failed_count}")

        # Generate reports
        if self.args.report:
            reporting.generate_hardening_report(results, self.args.report)

        if self.args.log:
            reporting.generate_log_file(results, self.args.log)

        utils.log_info("")
        utils.log_info("Hardening complete. Please review the results and reboot if necessary.")

    def run_restore_mode(self):
        """Run restore mode - restore from backup"""
        utils.log_header("HardeningKitty-Linux - Restore Mode")
        utils.log_warning("WARNING: This will restore system configuration from backup!")
        utils.log_info("")

        if not self.args.backup_file:
            utils.log_error("No backup file specified. Use --backup-file option.")
            sys.exit(1)

        # Confirm action unless --yes flag is provided
        if not self.args.yes:
            response = input(f"Restore from {self.args.backup_file}? (yes/no): ")
            if response.lower() not in ['yes', 'y']:
                utils.log_info("Operation cancelled.")
                sys.exit(0)

        # Load backup
        config_data = backup.load_backup(self.args.backup_file)

        # Restore configuration
        utils.log_info("Restoring configuration...")
        results = backup.restore_configuration(config_data)

        # Display results
        success_count = sum(1 for r in results if r['restored'])
        failed_count = len(results) - success_count

        utils.log_success(f"Successfully restored: {success_count}")
        if failed_count > 0:
            utils.log_warning(f"Failed to restore: {failed_count}")

        utils.log_info("")
        utils.log_info("Restore complete. Please review the results and reboot if necessary.")

    def calculate_stats(self):
        """Calculate statistics from results"""
        for result in self.results:
            status = result.get('result', 'error').lower()

            if status == 'passed':
                self.stats['passed'] += 1
            elif status == 'low':
                self.stats['low'] += 1
            elif status == 'medium':
                self.stats['medium'] += 1
            elif status == 'high':
                self.stats['high'] += 1
            else:
                self.stats['error'] += 1

            self.stats['total'] += 1

    def display_results(self):
        """Display audit results with statistics and scoring"""
        utils.log_info("")
        utils.log_header("Audit Results Summary")
        utils.log_info("")

        # Display statistics
        if self.args.emoji:
            print(f"  Total Checks: {self.stats['total']}")
            print(f"  😻 Passed:   {self.stats['passed']}")
            print(f"  😿 Low:      {self.stats['low']}")
            print(f"  🙀 Medium:   {self.stats['medium']}")
            print(f"  😾 High:     {self.stats['high']}")
            if self.stats['error'] > 0:
                print(f"  ❌ Error:    {self.stats['error']}")
        else:
            print(f"  Total Checks: {self.stats['total']}")
            print(f"  [+] Passed:   {self.stats['passed']}")
            print(f"  [!] Low:      {self.stats['low']}")
            print(f"  [!!] Medium:  {self.stats['medium']}")
            print(f"  [!!!] High:   {self.stats['high']}")
            if self.stats['error'] > 0:
                print(f"  [X] Error:    {self.stats['error']}")

        # Calculate score
        max_points = self.stats['total'] * 4
        achieved_points = (self.stats['passed'] * 4) + (self.stats['low'] * 2) + (self.stats['medium'] * 1)

        if max_points > 0:
            score = (achieved_points / max_points) * 5 + 1
        else:
            score = 1.0

        utils.log_info("")
        utils.log_header(f"HardeningKitty Score: {score:.2f} / 6.0")
        utils.log_info("")

        # Display detailed results if verbose
        if self.args.verbose:
            utils.log_info("Detailed Results:")
            for result in self.results:
                status = result.get('result', 'error')
                emoji = utils.get_result_emoji(status) if self.args.emoji else f"[{status.upper()}]"
                print(f"  {emoji} {result['ID']} - {result['Name']}: {result.get('current_value', 'N/A')}")

    def run(self):
        """Main execution method"""
        mode_map = {
            'audit': self.run_audit_mode,
            'config': self.run_config_mode,
            'hailmary': self.run_hailmary_mode,
            'restore': self.run_restore_mode
        }

        mode_func = mode_map.get(self.args.mode)
        if mode_func:
            mode_func()
        else:
            utils.log_error(f"Unknown mode: {self.args.mode}")
            sys.exit(1)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='HardeningKitty-Linux - Linux System Hardening Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic audit
  sudo python3 hardeningkitty.py --mode audit

  # Audit with specific finding list
  sudo python3 hardeningkitty.py --mode audit --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv

  # Apply hardening with backup
  sudo python3 hardeningkitty.py --mode hailmary --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv --backup

  # Create configuration backup
  sudo python3 hardeningkitty.py --mode config --backup --backup-file /root/system_backup.json

  # Restore from backup
  sudo python3 hardeningkitty.py --mode restore --backup-file /root/system_backup.json

  # Filter by severity
  sudo python3 hardeningkitty.py --mode audit --filter-severity High
        """
    )

    # Mode selection
    parser.add_argument(
        '--mode',
        choices=['audit', 'config', 'hailmary', 'restore'],
        default='audit',
        help='Operational mode (default: audit)'
    )

    # Finding list
    parser.add_argument(
        '--finding-list',
        type=str,
        help='Path to finding list CSV file'
    )

    # Filtering options
    parser.add_argument(
        '--filter-id',
        type=str,
        help='Filter by finding ID'
    )

    parser.add_argument(
        '--filter-category',
        type=str,
        help='Filter by category'
    )

    parser.add_argument(
        '--filter-severity',
        type=str,
        choices=['High', 'Medium', 'Low'],
        help='Filter by severity level'
    )

    parser.add_argument(
        '--filter-method',
        type=str,
        help='Filter by method'
    )

    # Output options
    parser.add_argument(
        '--report',
        type=str,
        help='Generate CSV report file'
    )

    parser.add_argument(
        '--log',
        type=str,
        help='Generate log file'
    )

    parser.add_argument(
        '--emoji',
        action='store_true',
        help='Enable emoji support in output'
    )

    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose output'
    )

    parser.add_argument(
        '--quiet',
        action='store_true',
        help='Minimal output'
    )

    # Backup options
    parser.add_argument(
        '--backup',
        action='store_true',
        help='Create backup before changes'
    )

    parser.add_argument(
        '--backup-file',
        type=str,
        help='Backup file path'
    )

    parser.add_argument(
        '--skip-backup',
        action='store_true',
        help='Skip backup creation (not recommended)'
    )

    # HailMary options
    parser.add_argument(
        '--yes',
        action='store_true',
        help='Automatically answer yes to prompts'
    )

    # Version
    parser.add_argument(
        '--version',
        action='version',
        version=f'HardeningKitty-Linux {__version__}'
    )

    # Store filter flag
    parser.add_argument(
        '--filter',
        action='store_true',
        help='Enable filtering (used internally)'
    )

    args = parser.parse_args()

    # Set filter flag if any filter option is provided
    if args.filter_id or args.filter_category or args.filter_severity or args.filter_method:
        args.filter = True

    # Create and run HardeningKitty instance
    try:
        hk = HardeningKitty(args)
        hk.run()
    except KeyboardInterrupt:
        print("\n")
        utils.log_warning("Operation cancelled by user.")
        sys.exit(130)
    except Exception as e:
        utils.log_error(f"Unexpected error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
