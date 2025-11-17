"""
Backup and restore functionality for HardeningKitty-Linux
"""

import json
from datetime import datetime
from . import utils, audit, methods, hardening


def export_configuration(findings):
    """
    Export current system configuration for all findings
    Returns list of configuration items
    """
    config_data = []
    config_methods = methods.ConfigMethods()

    utils.log_info("Exporting current configuration...")

    for finding in findings:
        # Get current value using audit logic
        current_value = audit.get_current_value(finding, config_methods)

        config_item = {
            'ID': finding['ID'],
            'Name': finding['Name'],
            'Category': finding['Category'],
            'Method': finding['Method'],
            'MethodArgument': finding.get('MethodArgument', ''),
            'ConfigPath': finding.get('ConfigPath', ''),
            'ConfigKey': finding.get('ConfigKey', ''),
            'CurrentValue': current_value,
            'RecommendedValue': finding['RecommendedValue'],
            'Timestamp': datetime.now().isoformat()
        }

        config_data.append(config_item)

    return config_data


def save_backup(config_data, backup_file):
    """
    Save configuration backup to JSON file
    """
    try:
        backup_obj = {
            'version': '1.0',
            'created': datetime.now().isoformat(),
            'hostname': get_hostname(),
            'os_release': get_os_release(),
            'configuration': config_data
        }

        with open(backup_file, 'w') as f:
            json.dump(backup_obj, f, indent=2)

        utils.log_success(f"Backup saved: {backup_file}")
        return True

    except Exception as e:
        utils.log_error(f"Failed to save backup: {e}")
        return False


def load_backup(backup_file):
    """
    Load configuration backup from JSON file
    """
    try:
        with open(backup_file, 'r') as f:
            backup_obj = json.load(f)

        utils.log_info(f"Loaded backup from: {backup_obj.get('created', 'unknown date')}")
        utils.log_info(f"Hostname: {backup_obj.get('hostname', 'unknown')}")
        utils.log_info(f"OS: {backup_obj.get('os_release', 'unknown')}")

        return backup_obj.get('configuration', [])

    except FileNotFoundError:
        utils.log_error(f"Backup file not found: {backup_file}")
        return None
    except json.JSONDecodeError:
        utils.log_error(f"Invalid backup file format: {backup_file}")
        return None
    except Exception as e:
        utils.log_error(f"Failed to load backup: {e}")
        return None


def restore_configuration(config_data):
    """
    Restore system configuration from backup data
    """
    results = []
    config_methods = methods.ConfigMethods()

    utils.log_info("Restoring configuration from backup...")

    for item in config_data:
        result = restore_item(item, config_methods)
        results.append(result)

        # Display result
        status_str = '[+]' if result['restored'] else '[X]'
        print(f"{status_str} {item['ID']:>6} | {item['Name'][:50]:<50} | {item['CurrentValue']}")

    return results


def restore_item(item, config_methods):
    """
    Restore a single configuration item
    """
    result = {
        'ID': item['ID'],
        'Name': item['Name'],
        'restored': False,
        'message': ''
    }

    # Create a finding-like object for the hardening logic
    finding = {
        'ID': item['ID'],
        'Name': item['Name'],
        'Category': item['Category'],
        'Method': item['Method'],
        'MethodArgument': item['MethodArgument'],
        'ConfigPath': item['ConfigPath'],
        'ConfigKey': item['ConfigKey'],
        'RecommendedValue': item['CurrentValue']  # Use backed up value as "recommended"
    }

    try:
        # Use hardening logic to apply the backed-up value
        success = hardening.apply_value(finding, config_methods)

        if success:
            result['restored'] = True
            result['message'] = 'Successfully restored'
        else:
            result['restored'] = False
            result['message'] = 'Failed to restore'

    except Exception as e:
        result['restored'] = False
        result['message'] = str(e)

    return result


def get_hostname():
    """Get system hostname"""
    output, error = utils.run_command("hostname", check=False)
    return output if output else "unknown"


def get_os_release():
    """Get OS release information"""
    output, error = utils.run_command("cat /etc/os-release | grep PRETTY_NAME", check=False)

    if output:
        # Extract value from PRETTY_NAME="..."
        import re
        match = re.search(r'PRETTY_NAME="(.*?)"', output)
        if match:
            return match.group(1)

    return "unknown"
