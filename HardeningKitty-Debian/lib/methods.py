"""
Configuration retrieval and application methods for Linux systems
Implements Linux equivalents of Windows hardening methods
"""

import os
import re
from . import utils


class ConfigMethods:
    """Linux system configuration methods"""

    @staticmethod
    def get_sysctl(param):
        """Get sysctl kernel parameter value"""
        output, error = utils.run_command(f"sysctl -n {param}", check=False)
        if error:
            return None
        return output

    @staticmethod
    def set_sysctl(param, value):
        """Set sysctl kernel parameter"""
        # Set runtime value
        output, error = utils.run_command(f"sysctl -w {param}={value}", check=False)
        if error:
            return False

        # Persist to /etc/sysctl.conf or /etc/sysctl.d/
        sysctl_file = "/etc/sysctl.d/99-hardeningkitty.conf"

        # Read existing content
        content = utils.read_file(sysctl_file) or ""
        lines = content.split('\n')

        # Update or add parameter
        param_found = False
        new_lines = []

        for line in lines:
            if line.strip().startswith(param):
                new_lines.append(f"{param} = {value}")
                param_found = True
            else:
                new_lines.append(line)

        if not param_found:
            new_lines.append(f"{param} = {value}")

        # Write back
        return utils.write_file(sysctl_file, '\n'.join(new_lines))

    @staticmethod
    def get_config_file_value(file_path, key, separator='='):
        """Get value from configuration file"""
        content = utils.read_file(file_path)
        if not content:
            return None

        for line in content.split('\n'):
            line = line.strip()
            if line.startswith('#') or not line:
                continue

            if separator in line:
                parts = line.split(separator, 1)
                if len(parts) == 2 and parts[0].strip() == key:
                    return parts[1].strip().strip('"').strip("'")

        return None

    @staticmethod
    def set_config_file_value(file_path, key, value, separator='='):
        """Set value in configuration file"""
        # Backup original file
        utils.backup_file(file_path)

        content = utils.read_file(file_path) or ""
        lines = content.split('\n')

        # Update or add key
        key_found = False
        new_lines = []

        for line in lines:
            stripped = line.strip()

            # Check if this line contains our key (not commented)
            if not stripped.startswith('#') and stripped.startswith(key):
                new_lines.append(f"{key}{separator}{value}")
                key_found = True
            else:
                new_lines.append(line)

        if not key_found:
            new_lines.append(f"{key}{separator}{value}")

        return utils.write_file(file_path, '\n'.join(new_lines))

    @staticmethod
    def get_service_status(service_name):
        """Get systemd service status"""
        output, error = utils.run_command(f"systemctl is-enabled {service_name}", check=False)

        if output:
            return output  # enabled, disabled, masked, etc.
        return "not-found"

    @staticmethod
    def set_service_status(service_name, desired_state):
        """Set systemd service status"""
        valid_states = ['enabled', 'disabled', 'masked']

        if desired_state not in valid_states:
            return False

        if desired_state == 'enabled':
            cmd = f"systemctl enable {service_name}"
        elif desired_state == 'disabled':
            cmd = f"systemctl disable {service_name}"
        elif desired_state == 'masked':
            cmd = f"systemctl mask {service_name}"

        output, error = utils.run_command(cmd, check=False)
        return error is None

    @staticmethod
    def get_package_status(package_name):
        """Check if package is installed (Debian/Ubuntu)"""
        output, error = utils.run_command(f"dpkg -l {package_name} 2>/dev/null | grep '^ii'", check=False)

        if output and output.strip():
            return "installed"
        return "not-installed"

    @staticmethod
    def install_package(package_name):
        """Install package using apt (Debian/Ubuntu)"""
        # Update package list first
        utils.run_command("apt-get update -qq", check=False)
        output, error = utils.run_command(f"DEBIAN_FRONTEND=noninteractive apt-get install -y {package_name}", check=False)
        return error is None

    @staticmethod
    def remove_package(package_name):
        """Remove package using apt (Debian/Ubuntu)"""
        output, error = utils.run_command(f"DEBIAN_FRONTEND=noninteractive apt-get remove -y {package_name}", check=False)
        return error is None

    @staticmethod
    def get_permission(file_path):
        """Get file/directory permissions"""
        if not os.path.exists(file_path):
            return None

        stat_info = os.stat(file_path)
        mode = oct(stat_info.st_mode)[-3:]
        return mode

    @staticmethod
    def set_permission(file_path, mode):
        """Set file/directory permissions"""
        if not os.path.exists(file_path):
            return False

        try:
            os.chmod(file_path, int(mode, 8))
            return True
        except Exception as e:
            utils.log_error(f"Error setting permissions on {file_path}: {e}")
            return False

    @staticmethod
    def get_ownership(file_path):
        """Get file/directory ownership"""
        if not os.path.exists(file_path):
            return None

        stat_info = os.stat(file_path)

        try:
            import pwd
            import grp
            owner = pwd.getpwuid(stat_info.st_uid).pw_name
            group = grp.getgrgid(stat_info.st_gid).gr_name
            return f"{owner}:{group}"
        except:
            return f"{stat_info.st_uid}:{stat_info.st_gid}"

    @staticmethod
    def set_ownership(file_path, owner, group=None):
        """Set file/directory ownership"""
        if not os.path.exists(file_path):
            return False

        if group is None and ':' in owner:
            owner, group = owner.split(':', 1)

        cmd = f"chown {owner}"
        if group:
            cmd += f":{group}"
        cmd += f" {file_path}"

        output, error = utils.run_command(cmd, check=False)
        return error is None

    @staticmethod
    def get_mount_options(mount_point):
        """Get mount options for filesystem"""
        output, error = utils.run_command("mount", check=False)
        if not output:
            return None

        for line in output.split('\n'):
            if f" on {mount_point} " in line:
                # Extract options from: device on mount_point type fstype (options)
                match = re.search(r'\((.*?)\)', line)
                if match:
                    return match.group(1)

        return None

    @staticmethod
    def check_mount_option(mount_point, option):
        """Check if specific mount option is set"""
        options = ConfigMethods.get_mount_options(mount_point)
        if not options:
            return False

        return option in options.split(',')

    @staticmethod
    def get_apparmor_status():
        """Get AppArmor status (Debian/Ubuntu uses AppArmor instead of SELinux)"""
        output, error = utils.run_command("aa-status --enabled", check=False)
        if error:
            return "disabled"

        # Get detailed status
        output, error = utils.run_command("systemctl is-active apparmor", check=False)
        if output and output.strip() == "active":
            return "enforcing"
        return "disabled"

    @staticmethod
    def set_apparmor_mode(mode):
        """Set AppArmor mode (Debian/Ubuntu)"""
        valid_modes = ['enforcing', 'disabled']

        if mode.lower() not in valid_modes:
            return False

        if mode.lower() == 'enforcing':
            # Enable and start AppArmor
            output, error = utils.run_command("systemctl enable apparmor", check=False)
            if error:
                return False
            output, error = utils.run_command("systemctl start apparmor", check=False)
            return error is None
        else:
            # Disable AppArmor
            output, error = utils.run_command("systemctl stop apparmor", check=False)
            output, error = utils.run_command("systemctl disable apparmor", check=False)
            return error is None

    @staticmethod
    def get_auditd_rule(rule_pattern):
        """Check if auditd rule exists"""
        output, error = utils.run_command("auditctl -l", check=False)
        if not output:
            return None

        for line in output.split('\n'):
            if rule_pattern in line:
                return line.strip()

        return None

    @staticmethod
    def add_auditd_rule(rule):
        """Add auditd rule"""
        # Add to runtime
        output, error = utils.run_command(f"auditctl -a {rule}", check=False)
        if error:
            return False

        # Persist to rules file
        rules_file = "/etc/audit/rules.d/hardeningkitty.rules"
        content = utils.read_file(rules_file) or ""

        # Check if rule already exists
        if rule not in content:
            content += f"\n-a {rule}\n"
            return utils.write_file(rules_file, content)

        return True

    @staticmethod
    def get_ufw_rule(service_or_port):
        """Check if UFW rule exists (Debian/Ubuntu firewall)"""
        output, error = utils.run_command("ufw status", check=False)
        if not output:
            return None

        return service_or_port in output

    @staticmethod
    def add_ufw_rule(service=None, port=None, protocol='tcp'):
        """Add UFW firewall rule (Debian/Ubuntu)"""
        if service:
            # Common service names that UFW recognizes
            cmd = f"ufw allow {service}"
        elif port:
            cmd = f"ufw allow {port}/{protocol}"
        else:
            return False

        output, error = utils.run_command(cmd, check=False)
        return error is None

    @staticmethod
    def remove_ufw_rule(service=None, port=None, protocol='tcp'):
        """Remove UFW firewall rule (Debian/Ubuntu)"""
        if service:
            cmd = f"ufw delete allow {service}"
        elif port:
            cmd = f"ufw delete allow {port}/{protocol}"
        else:
            return False

        output, error = utils.run_command(cmd, check=False)
        return error is None

    @staticmethod
    def get_ufw_status():
        """Get UFW firewall status"""
        output, error = utils.run_command("ufw status", check=False)
        if output and "Status: active" in output:
            return "active"
        return "inactive"

    @staticmethod
    def set_ufw_status(desired_state):
        """Enable or disable UFW"""
        if desired_state.lower() == "active" or desired_state.lower() == "enabled":
            output, error = utils.run_command("ufw --force enable", check=False)
            return error is None
        elif desired_state.lower() == "inactive" or desired_state.lower() == "disabled":
            output, error = utils.run_command("ufw disable", check=False)
            return error is None
        return False

    @staticmethod
    def get_grub_parameter(param):
        """Get GRUB kernel parameter"""
        grub_file = "/etc/default/grub"
        content = utils.read_file(grub_file)

        if not content:
            return None

        for line in content.split('\n'):
            if line.strip().startswith('GRUB_CMDLINE_LINUX'):
                # Extract parameters
                match = re.search(r'GRUB_CMDLINE_LINUX="(.*?)"', line)
                if match:
                    cmdline = match.group(1)

                    # Look for specific parameter
                    for item in cmdline.split():
                        if item.startswith(f"{param}="):
                            return item.split('=', 1)[1]
                        elif item == param:
                            return "present"

        return None

    @staticmethod
    def set_grub_parameter(param, value=None):
        """Set GRUB kernel parameter"""
        grub_file = "/etc/default/grub"
        utils.backup_file(grub_file)

        content = utils.read_file(grub_file)
        if not content:
            return False

        lines = content.split('\n')
        new_lines = []

        for line in lines:
            if line.strip().startswith('GRUB_CMDLINE_LINUX'):
                match = re.search(r'GRUB_CMDLINE_LINUX="(.*?)"', line)
                if match:
                    cmdline = match.group(1)

                    # Remove existing parameter if present
                    params = [p for p in cmdline.split() if not p.startswith(f"{param}=") and p != param]

                    # Add new parameter
                    if value:
                        params.append(f"{param}={value}")
                    else:
                        params.append(param)

                    new_cmdline = ' '.join(params)
                    new_lines.append(f'GRUB_CMDLINE_LINUX="{new_cmdline}"')
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)

        # Write updated configuration
        if not utils.write_file(grub_file, '\n'.join(new_lines)):
            return False

        # Rebuild GRUB configuration
        output, error = utils.run_command("grub2-mkconfig -o /boot/grub2/grub.cfg", check=False)
        return error is None

    @staticmethod
    def get_modprobe_status(module):
        """Check if kernel module is blacklisted"""
        blacklist_files = [
            "/etc/modprobe.d/blacklist.conf",
            "/etc/modprobe.d/hardeningkitty.conf"
        ]

        for file_path in blacklist_files:
            content = utils.read_file(file_path)
            if content and f"blacklist {module}" in content:
                return "blacklisted"

        # Check if module is loaded
        output, error = utils.run_command(f"lsmod | grep {module}", check=False)
        if output:
            return "loaded"

        return "not-loaded"

    @staticmethod
    def blacklist_module(module):
        """Blacklist kernel module"""
        modprobe_file = "/etc/modprobe.d/hardeningkitty.conf"
        content = utils.read_file(modprobe_file) or ""

        if f"blacklist {module}" not in content:
            content += f"\nblacklist {module}\ninstall {module} /bin/true\n"
            return utils.write_file(modprobe_file, content)

        return True

    @staticmethod
    def get_pam_configuration(pam_file, module, control=None):
        """Get PAM module configuration"""
        file_path = f"/etc/pam.d/{pam_file}"
        content = utils.read_file(file_path)

        if not content:
            return None

        for line in content.split('\n'):
            line = line.strip()
            if line.startswith('#') or not line:
                continue

            parts = line.split()
            if len(parts) >= 3 and module in line:
                if control is None or parts[1] == control:
                    return line

        return None

    @staticmethod
    def set_pam_configuration(pam_file, module, control, options):
        """Set PAM module configuration"""
        file_path = f"/etc/pam.d/{pam_file}"
        utils.backup_file(file_path)

        content = utils.read_file(file_path) or ""
        lines = content.split('\n')
        new_lines = []
        module_found = False

        for line in lines:
            stripped = line.strip()

            # Update existing module line
            if not stripped.startswith('#') and module in stripped:
                new_lines.append(f"{control}\t{module}\t{options}")
                module_found = True
            else:
                new_lines.append(line)

        # Add module if not found
        if not module_found:
            new_lines.append(f"{control}\t{module}\t{options}")

        return utils.write_file(file_path, '\n'.join(new_lines))
