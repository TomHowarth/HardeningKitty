"""
Utility functions for HardeningKitty-Linux
"""

import sys
import os
from datetime import datetime


# ANSI color codes
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def log_header(message):
    """Print header message"""
    print(f"{Colors.BOLD}{Colors.CYAN}{'=' * 70}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.CYAN}{message.center(70)}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'=' * 70}{Colors.ENDC}")


def log_info(message):
    """Print info message"""
    print(f"{Colors.BLUE}[*]{Colors.ENDC} {message}")


def log_success(message):
    """Print success message"""
    print(f"{Colors.GREEN}[+]{Colors.ENDC} {message}")


def log_warning(message):
    """Print warning message"""
    print(f"{Colors.YELLOW}[!]{Colors.ENDC} {message}")


def log_error(message):
    """Print error message"""
    print(f"{Colors.RED}[X]{Colors.ENDC} {message}", file=sys.stderr)


def get_result_emoji(status):
    """Get emoji for result status"""
    emoji_map = {
        'passed': '😻',
        'low': '😿',
        'medium': '🙀',
        'high': '😾',
        'error': '❌'
    }
    return emoji_map.get(status.lower(), '❓')


def check_root():
    """Check if running as root"""
    return os.geteuid() == 0


def run_command(command, check=True):
    """Run shell command and return output"""
    import subprocess

    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30
        )

        if check and result.returncode != 0:
            return None, result.stderr

        return result.stdout.strip(), None

    except subprocess.TimeoutExpired:
        return None, "Command timeout"
    except Exception as e:
        return None, str(e)


def read_file(file_path):
    """Read file contents"""
    try:
        with open(file_path, 'r') as f:
            return f.read()
    except FileNotFoundError:
        return None
    except Exception as e:
        log_error(f"Error reading {file_path}: {e}")
        return None


def write_file(file_path, content, mode='w'):
    """Write content to file"""
    try:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, mode) as f:
            f.write(content)
        return True
    except Exception as e:
        log_error(f"Error writing {file_path}: {e}")
        return False


def backup_file(file_path):
    """Create backup of file"""
    if not os.path.exists(file_path):
        return None

    backup_path = f"{file_path}.bak.{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    try:
        import shutil
        shutil.copy2(file_path, backup_path)
        return backup_path
    except Exception as e:
        log_error(f"Error backing up {file_path}: {e}")
        return None


def parse_ini_file(file_path):
    """Parse INI-style configuration file"""
    config = {}
    current_section = None

    content = read_file(file_path)
    if not content:
        return config

    for line in content.split('\n'):
        line = line.strip()

        # Skip comments and empty lines
        if not line or line.startswith('#') or line.startswith(';'):
            continue

        # Section header
        if line.startswith('[') and line.endswith(']'):
            current_section = line[1:-1]
            config[current_section] = {}
            continue

        # Key-value pair
        if '=' in line:
            key, value = line.split('=', 1)
            key = key.strip()
            value = value.strip()

            if current_section:
                config[current_section][key] = value
            else:
                config[key] = value

    return config


def compare_values(current, expected, operator):
    """
    Compare values using specified operator

    Operators:
    - '=': Exact equality
    - '!=': Not equal
    - '<=': Less than or equal
    - '>=': Greater than or equal
    - 'contains': String contains
    - '=|0': Equal or zero/empty
    - '<=!0': Less than or equal AND not zero
    """

    # Handle None/empty values
    if current is None or current == '':
        current = ''
    if expected is None or expected == '':
        expected = ''

    # Convert to strings for comparison
    current_str = str(current).strip()
    expected_str = str(expected).strip()

    try:
        if operator == '=':
            return current_str == expected_str

        elif operator == '!=':
            return current_str != expected_str

        elif operator == 'contains':
            return expected_str.lower() in current_str.lower()

        elif operator == '=|0':
            return current_str == expected_str or current_str in ['0', '']

        elif operator == '<=':
            return float(current_str) <= float(expected_str)

        elif operator == '>=':
            return float(current_str) >= float(expected_str)

        elif operator == '<=!0':
            val = float(current_str)
            return val <= float(expected_str) and val != 0

        else:
            log_warning(f"Unknown operator: {operator}")
            return False

    except (ValueError, TypeError) as e:
        # If numeric comparison fails, fall back to string comparison
        if operator in ['<=', '>=', '<=!0']:
            return False
        return current_str == expected_str


def get_timestamp():
    """Get current timestamp"""
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')


def format_bytes(bytes_value):
    """Format bytes to human-readable format"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if bytes_value < 1024.0:
            return f"{bytes_value:.2f} {unit}"
        bytes_value /= 1024.0
    return f"{bytes_value:.2f} PB"


def is_service_exists(service_name):
    """Check if systemd service exists"""
    output, error = run_command(f"systemctl list-unit-files {service_name}.service", check=False)
    return output and service_name in output


def is_package_installed(package_name):
    """Check if package is installed"""
    output, error = run_command(f"rpm -q {package_name}", check=False)
    return output and not output.startswith('package') and not error
