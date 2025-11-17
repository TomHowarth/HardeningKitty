"""
Audit mode implementation for HardeningKitty-Linux
Assesses current system configuration against security benchmarks
"""

from . import utils, methods


def run_audit(findings, use_emoji=False):
    """
    Run audit on all findings
    Returns list of results
    """
    results = []
    config_methods = methods.ConfigMethods()

    for finding in findings:
        result = audit_finding(finding, config_methods, use_emoji)
        results.append(result)

        # Display result in real-time
        display_result(result, use_emoji)

    return results


def audit_finding(finding, config_methods, use_emoji=False):
    """
    Audit a single finding
    Returns result dictionary
    """
    result = {
        'ID': finding['ID'],
        'Name': finding['Name'],
        'Category': finding['Category'],
        'Method': finding['Method'],
        'Severity': finding['Severity'],
        'current_value': None,
        'expected_value': finding['RecommendedValue'],
        'result': 'error',
        'message': ''
    }

    try:
        # Get current value based on method
        current_value = get_current_value(finding, config_methods)
        result['current_value'] = current_value

        # Compare with expected value
        if current_value is None:
            result['result'] = 'error'
            result['message'] = 'Could not retrieve current value'
        else:
            matches = utils.compare_values(
                current_value,
                finding['RecommendedValue'],
                finding['Operator']
            )

            if matches:
                result['result'] = 'passed'
            else:
                # Use severity from finding
                result['result'] = finding['Severity'].lower()

    except Exception as e:
        result['result'] = 'error'
        result['message'] = str(e)

    return result


def get_current_value(finding, config_methods):
    """
    Get current value based on finding method
    """
    method = finding['Method']
    argument = finding.get('MethodArgument', '')
    config_path = finding.get('ConfigPath', '')
    config_key = finding.get('ConfigKey', '')

    try:
        if method == 'sysctl':
            return config_methods.get_sysctl(argument)

        elif method == 'config_file':
            return config_methods.get_config_file_value(config_path, config_key)

        elif method == 'service':
            return config_methods.get_service_status(argument)

        elif method == 'package':
            return config_methods.get_package_status(argument)

        elif method == 'permission':
            return config_methods.get_permission(config_path)

        elif method == 'ownership':
            return config_methods.get_ownership(config_path)

        elif method == 'mount':
            mount_point = config_path
            option = argument
            has_option = config_methods.check_mount_option(mount_point, option)
            return option if has_option else "missing"

        elif method == 'selinux':
            return config_methods.get_selinux_status()

        elif method == 'auditd':
            rule = config_methods.get_auditd_rule(argument)
            return "present" if rule else "absent"

        elif method == 'firewalld':
            zone = config_path or 'public'
            has_rule = config_methods.get_firewalld_rule(zone, argument)
            return "present" if has_rule else "absent"

        elif method == 'grub':
            return config_methods.get_grub_parameter(argument)

        elif method == 'modprobe':
            return config_methods.get_modprobe_status(argument)

        elif method == 'pam':
            pam_file = config_path
            module = argument
            config = config_methods.get_pam_configuration(pam_file, module)
            return "configured" if config else "not-configured"

        elif method == 'file_exists':
            import os
            return "exists" if os.path.exists(config_path) else "not-exists"

        elif method == 'command':
            # Execute custom command
            output, error = utils.run_command(argument, check=False)
            return output if output else None

        else:
            return f"unknown_method:{method}"

    except Exception as e:
        utils.log_error(f"Error getting value for {finding['ID']}: {e}")
        return None


def display_result(result, use_emoji=False):
    """Display single result"""
    status = result['result']

    if use_emoji:
        emoji = utils.get_result_emoji(status)
        status_str = emoji
    else:
        status_map = {
            'passed': '[+]',
            'low': '[!]',
            'medium': '[!!]',
            'high': '[!!!]',
            'error': '[X]'
        }
        status_str = status_map.get(status, '[?]')

    # Format output
    id_str = f"{result['ID']:>6}"
    name_str = f"{result['Name'][:60]:<60}"
    current_str = f"{str(result['current_value'])[:20]:>20}"
    expected_str = f"{str(result['expected_value'])[:20]:>20}"

    print(f"{status_str} {id_str} | {name_str} | {current_str} | {expected_str}")
