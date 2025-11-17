"""
Hardening mode implementation for HardeningKitty-Linux
Applies security configuration changes to the system
"""

from . import utils, methods


def apply_hardening(findings):
    """
    Apply hardening settings for all findings
    Returns list of results
    """
    results = []
    config_methods = methods.ConfigMethods()

    for finding in findings:
        result = apply_finding(finding, config_methods)
        results.append(result)

        # Display result in real-time
        display_hardening_result(result)

    return results


def apply_finding(finding, config_methods):
    """
    Apply hardening for a single finding
    Returns result dictionary
    """
    result = {
        'ID': finding['ID'],
        'Name': finding['Name'],
        'Category': finding['Category'],
        'Method': finding['Method'],
        'expected_value': finding['RecommendedValue'],
        'applied': False,
        'message': ''
    }

    try:
        # Apply setting based on method
        success = apply_value(finding, config_methods)

        if success:
            result['applied'] = True
            result['message'] = 'Successfully applied'
        else:
            result['applied'] = False
            result['message'] = 'Failed to apply setting'

    except Exception as e:
        result['applied'] = False
        result['message'] = str(e)

    return result


def apply_value(finding, config_methods):
    """
    Apply value based on finding method
    """
    method = finding['Method']
    argument = finding.get('MethodArgument', '')
    config_path = finding.get('ConfigPath', '')
    config_key = finding.get('ConfigKey', '')
    recommended_value = finding['RecommendedValue']

    try:
        if method == 'sysctl':
            return config_methods.set_sysctl(argument, recommended_value)

        elif method == 'config_file':
            separator = '='
            # Check for different separators
            if ':' in config_key:
                separator = ':'

            return config_methods.set_config_file_value(
                config_path,
                config_key,
                recommended_value,
                separator
            )

        elif method == 'service':
            return config_methods.set_service_status(argument, recommended_value)

        elif method == 'package':
            if recommended_value == 'not-installed':
                return config_methods.remove_package(argument)
            elif recommended_value == 'installed':
                return config_methods.install_package(argument)
            return False

        elif method == 'permission':
            return config_methods.set_permission(config_path, recommended_value)

        elif method == 'ownership':
            if ':' in recommended_value:
                owner, group = recommended_value.split(':', 1)
                return config_methods.set_ownership(config_path, owner, group)
            else:
                return config_methods.set_ownership(config_path, recommended_value)

        elif method == 'mount':
            # Mount options require /etc/fstab modification
            return modify_fstab_option(config_path, argument, recommended_value)

        elif method == 'apparmor':
            return config_methods.set_apparmor_mode(recommended_value)

        elif method == 'selinux':
            # Fall back to AppArmor for Debian/Ubuntu
            return config_methods.set_apparmor_mode(recommended_value)

        elif method == 'auditd':
            if recommended_value.lower() in ['present', 'enabled']:
                return config_methods.add_auditd_rule(argument)
            return True  # Skip removal

        elif method == 'ufw':
            if recommended_value.lower() in ['present', 'enabled']:
                # Determine if it's a service or port
                if '/' in argument:  # port/protocol format
                    port, protocol = argument.split('/', 1)
                    return config_methods.add_ufw_rule(port=port, protocol=protocol)
                else:
                    return config_methods.add_ufw_rule(service=argument)
            else:
                if '/' in argument:
                    port, protocol = argument.split('/', 1)
                    return config_methods.remove_ufw_rule(port=port, protocol=protocol)
                else:
                    return config_methods.remove_ufw_rule(service=argument)

        elif method == 'ufw_status':
            return config_methods.set_ufw_status(recommended_value)

        elif method == 'firewalld':
            # Fall back to UFW for Debian/Ubuntu
            if recommended_value.lower() in ['present', 'enabled']:
                if '/' in argument:
                    port, protocol = argument.split('/', 1) if '/' in argument else (argument, 'tcp')
                    return config_methods.add_ufw_rule(port=port, protocol=protocol)
                else:
                    return config_methods.add_ufw_rule(service=argument)
            else:
                if '/' in argument:
                    port, protocol = argument.split('/', 1) if '/' in argument else (argument, 'tcp')
                    return config_methods.remove_ufw_rule(port=port, protocol=protocol)
                else:
                    return config_methods.remove_ufw_rule(service=argument)

        elif method == 'grub':
            return config_methods.set_grub_parameter(argument, recommended_value)

        elif method == 'modprobe':
            if recommended_value.lower() in ['blacklisted', 'disabled']:
                return config_methods.blacklist_module(argument)
            return True

        elif method == 'pam':
            # PAM configuration is complex, for now just log
            utils.log_warning(f"PAM configuration for {finding['Name']} requires manual intervention")
            return False

        elif method == 'command':
            # Execute custom command
            output, error = utils.run_command(argument, check=False)
            return error is None

        else:
            utils.log_warning(f"Unknown method: {method}")
            return False

    except Exception as e:
        utils.log_error(f"Error applying {finding['ID']}: {e}")
        return False


def modify_fstab_option(mount_point, option, action):
    """
    Modify /etc/fstab mount options
    """
    fstab_path = "/etc/fstab"
    utils.backup_file(fstab_path)

    content = utils.read_file(fstab_path)
    if not content:
        return False

    lines = content.split('\n')
    new_lines = []
    modified = False

    for line in lines:
        stripped = line.strip()

        # Skip comments and empty lines
        if stripped.startswith('#') or not stripped:
            new_lines.append(line)
            continue

        parts = stripped.split()

        # Check if this is the mount point we're looking for
        if len(parts) >= 4 and parts[1] == mount_point:
            # parts[3] contains mount options
            options = parts[3].split(',')

            if action.lower() in ['add', 'present']:
                if option not in options:
                    options.append(option)
                    modified = True
            elif action.lower() in ['remove', 'absent']:
                if option in options:
                    options.remove(option)
                    modified = True

            # Rebuild line
            parts[3] = ','.join(options)
            new_lines.append('\t'.join(parts[:4]) + '\t' + '\t'.join(parts[4:]))
        else:
            new_lines.append(line)

    if modified:
        return utils.write_file(fstab_path, '\n'.join(new_lines))

    return True


def display_hardening_result(result):
    """Display hardening result"""
    status_str = '[+]' if result['applied'] else '[X]'

    id_str = f"{result['ID']:>6}"
    name_str = f"{result['Name'][:60]:<60}"
    expected_str = f"{str(result['expected_value'])[:20]:>20}"
    message_str = result['message']

    print(f"{status_str} {id_str} | {name_str} | {expected_str} | {message_str}")
