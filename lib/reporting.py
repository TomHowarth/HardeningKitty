"""
Reporting and logging functionality for HardeningKitty-Linux
"""

import csv
import json
from datetime import datetime
from . import utils


def generate_csv_report(results, report_file):
    """
    Generate CSV report from audit results
    """
    try:
        with open(report_file, 'w', newline='') as f:
            fieldnames = [
                'ID',
                'Category',
                'Name',
                'Severity',
                'Result',
                'CurrentValue',
                'RecommendedValue',
                'Operator',
                'Message'
            ]

            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            for result in results:
                writer.writerow({
                    'ID': result.get('ID', ''),
                    'Category': result.get('Category', ''),
                    'Name': result.get('Name', ''),
                    'Severity': result.get('Severity', ''),
                    'Result': result.get('result', ''),
                    'CurrentValue': result.get('current_value', ''),
                    'RecommendedValue': result.get('expected_value', ''),
                    'Operator': result.get('Operator', ''),
                    'Message': result.get('message', '')
                })

        utils.log_success(f"CSV report generated: {report_file}")
        return True

    except Exception as e:
        utils.log_error(f"Failed to generate CSV report: {e}")
        return False


def generate_log_file(results, log_file):
    """
    Generate log file from results
    """
    try:
        with open(log_file, 'w') as f:
            f.write("=" * 80 + "\n")
            f.write("HardeningKitty-Linux Audit Log\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 80 + "\n\n")

            # Summary statistics
            stats = calculate_statistics(results)

            f.write("Summary Statistics:\n")
            f.write(f"  Total Checks: {stats['total']}\n")
            f.write(f"  Passed:       {stats['passed']}\n")
            f.write(f"  Low:          {stats['low']}\n")
            f.write(f"  Medium:       {stats['medium']}\n")
            f.write(f"  High:         {stats['high']}\n")
            f.write(f"  Errors:       {stats['error']}\n")
            f.write(f"\n  Score:        {stats['score']:.2f} / 6.0\n")
            f.write("\n" + "=" * 80 + "\n\n")

            # Detailed results
            f.write("Detailed Results:\n\n")

            for result in results:
                f.write(f"ID: {result.get('ID', 'N/A')}\n")
                f.write(f"Name: {result.get('Name', 'N/A')}\n")
                f.write(f"Category: {result.get('Category', 'N/A')}\n")
                f.write(f"Severity: {result.get('Severity', 'N/A')}\n")
                f.write(f"Result: {result.get('result', 'N/A')}\n")
                f.write(f"Current Value: {result.get('current_value', 'N/A')}\n")
                f.write(f"Expected Value: {result.get('expected_value', 'N/A')}\n")

                if result.get('message'):
                    f.write(f"Message: {result.get('message')}\n")

                f.write("-" * 80 + "\n\n")

        utils.log_success(f"Log file generated: {log_file}")
        return True

    except Exception as e:
        utils.log_error(f"Failed to generate log file: {e}")
        return False


def generate_hardening_report(results, report_file):
    """
    Generate hardening report
    """
    try:
        with open(report_file, 'w', newline='') as f:
            fieldnames = [
                'ID',
                'Category',
                'Name',
                'Method',
                'ExpectedValue',
                'Applied',
                'Message'
            ]

            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            for result in results:
                writer.writerow({
                    'ID': result.get('ID', ''),
                    'Category': result.get('Category', ''),
                    'Name': result.get('Name', ''),
                    'Method': result.get('Method', ''),
                    'ExpectedValue': result.get('expected_value', ''),
                    'Applied': 'Yes' if result.get('applied') else 'No',
                    'Message': result.get('message', '')
                })

        utils.log_success(f"Hardening report generated: {report_file}")
        return True

    except Exception as e:
        utils.log_error(f"Failed to generate hardening report: {e}")
        return False


def generate_json_report(results, report_file):
    """
    Generate JSON report from results
    """
    try:
        report_obj = {
            'version': '1.0',
            'generated': datetime.now().isoformat(),
            'statistics': calculate_statistics(results),
            'results': results
        }

        with open(report_file, 'w') as f:
            json.dump(report_obj, f, indent=2)

        utils.log_success(f"JSON report generated: {report_file}")
        return True

    except Exception as e:
        utils.log_error(f"Failed to generate JSON report: {e}")
        return False


def calculate_statistics(results):
    """
    Calculate statistics from results
    """
    stats = {
        'passed': 0,
        'low': 0,
        'medium': 0,
        'high': 0,
        'error': 0,
        'total': 0,
        'score': 0.0
    }

    for result in results:
        status = result.get('result', 'error').lower()

        if status == 'passed':
            stats['passed'] += 1
        elif status == 'low':
            stats['low'] += 1
        elif status == 'medium':
            stats['medium'] += 1
        elif status == 'high':
            stats['high'] += 1
        else:
            stats['error'] += 1

        stats['total'] += 1

    # Calculate score
    max_points = stats['total'] * 4
    achieved_points = (stats['passed'] * 4) + (stats['low'] * 2) + (stats['medium'] * 1)

    if max_points > 0:
        stats['score'] = (achieved_points / max_points) * 5 + 1
    else:
        stats['score'] = 1.0

    return stats
