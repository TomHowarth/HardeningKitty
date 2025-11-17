# Extracting Implementations to Separate Repositories

This guide explains how to extract the Python and PowerShell implementations into their own dedicated GitHub repositories.

## Current Structure

The repository now contains two self-contained implementations:

```
HardeningKitty/
├── HardeningKitty.psm1              # Windows version (original)
├── HardeningKitty-Python/           # Linux - Python implementation
│   └── [Complete standalone implementation]
├── HardeningKitty-PowerShell/       # Linux - PowerShell implementation
│   └── [Complete standalone implementation]
└── README_LINUX_IMPLEMENTATIONS.md  # Comparison guide
```

## Option 1: Create Separate Repositories Manually

### Extract Python Implementation

```bash
# 1. Create new repository on GitHub
# Repository name: HardeningKitty-Linux-Python

# 2. Clone the new empty repository
git clone https://github.com/YourUsername/HardeningKitty-Linux-Python.git
cd HardeningKitty-Linux-Python

# 3. Copy files from HardeningKitty-Python directory
cp -r /path/to/HardeningKitty/HardeningKitty-Python/* .

# 4. Initialize git and commit
git add .
git commit -m "Initial commit: HardeningKitty Python implementation for Linux"

# 5. Push to GitHub
git push origin main
```

### Extract PowerShell Implementation

```bash
# 1. Create new repository on GitHub
# Repository name: HardeningKitty-Linux-PowerShell

# 2. Clone the new empty repository
git clone https://github.com/YourUsername/HardeningKitty-Linux-PowerShell.git
cd HardeningKitty-Linux-PowerShell

# 3. Copy files from HardeningKitty-PowerShell directory
cp -r /path/to/HardeningKitty/HardeningKitty-PowerShell/* .

# 4. Initialize git and commit
git add .
git commit -m "Initial commit: HardeningKitty PowerShell implementation for Linux"

# 5. Push to GitHub
git push origin main
```

## Option 2: Use Git Subtree (Preserves History)

This method preserves the git history for each implementation.

### Extract Python Implementation with History

```bash
# 1. Clone the main repository
git clone https://github.com/TomHowarth/HardeningKitty.git
cd HardeningKitty

# 2. Checkout the reorganization branch
git checkout claude/reorganize-into-separate-repos-011CUdLShrPrTKceBNkp8urH

# 3. Use git subtree split to create a new branch with only Python directory
git subtree split --prefix=HardeningKitty-Python -b python-only

# 4. Create new repository on GitHub (HardeningKitty-Linux-Python)

# 5. Push the python-only branch to the new repository
git push https://github.com/YourUsername/HardeningKitty-Linux-Python.git python-only:main
```

### Extract PowerShell Implementation with History

```bash
# 1. From the same HardeningKitty repository
git checkout claude/reorganize-into-separate-repos-011CUdLShrPrTKceBNkp8urH

# 2. Use git subtree split for PowerShell directory
git subtree split --prefix=HardeningKitty-PowerShell -b powershell-only

# 3. Create new repository on GitHub (HardeningKitty-Linux-PowerShell)

# 4. Push the powershell-only branch to the new repository
git push https://github.com/YourUsername/HardeningKitty-Linux-PowerShell.git powershell-only:main
```

## Option 3: Use GitHub's Template Repository Feature

If you want users to easily create copies:

1. **Make the subdirectories available as templates**
2. **Create separate repositories**
3. **Mark them as template repositories** in GitHub settings

## Recommended Repository Names

### Python Implementation
- **Repository Name**: `HardeningKitty-Linux-Python`
- **Description**: "Security hardening tool for Rocky Linux (Python implementation). Implements CIS Benchmarks and DISA STIG."
- **Topics**: `security`, `hardening`, `linux`, `rocky-linux`, `cis-benchmark`, `python`, `rhel`, `audit`

### PowerShell Implementation
- **Repository Name**: `HardeningKitty-Linux-PowerShell`
- **Description**: "Security hardening tool for Rocky Linux (PowerShell Core implementation). Implements CIS Benchmarks and DISA STIG."
- **Topics**: `security`, `hardening`, `linux`, `rocky-linux`, `cis-benchmark`, `powershell`, `rhel`, `audit`

## Repository Structure After Extraction

### Python Repository Root
```
HardeningKitty-Linux-Python/
├── README.md                      # Main README (from HardeningKitty-Python/README.md)
├── hardeningkitty.py
├── lib/
├── lists_linux/
├── examples/
├── requirements.txt
├── LICENSE
├── LINUX_ARCHITECTURE.md
└── README_LINUX.md
```

### PowerShell Repository Root
```
HardeningKitty-Linux-PowerShell/
├── README.md                      # Main README (from HardeningKitty-PowerShell/README.md)
├── HardeningKitty-Linux.psm1
├── HardeningKitty-Linux.psd1
├── lists_linux/
├── examples_powershell/
├── LICENSE
└── README_POWERSHELL_LINUX.md
```

## Update Cross-References

After extracting to separate repositories, update references:

### In Python Repository

Update `README.md` to add:

```markdown
## Related Projects

- **Windows Version**: [HardeningKitty](https://github.com/TomHowarth/HardeningKitty) - Original Windows implementation
- **PowerShell Linux Version**: [HardeningKitty-Linux-PowerShell](https://github.com/YourUsername/HardeningKitty-Linux-PowerShell) - Alternative PowerShell implementation
```

### In PowerShell Repository

Update `README.md` to add:

```markdown
## Related Projects

- **Windows Version**: [HardeningKitty](https://github.com/TomHowarth/HardeningKitty) - Original Windows implementation
- **Python Linux Version**: [HardeningKitty-Linux-Python](https://github.com/YourUsername/HardeningKitty-Linux-Python) - Alternative Python implementation
```

### In Main Windows Repository

Update main `README.md` to add:

```markdown
## Linux Versions

HardeningKitty has been refactored for Rocky Linux in two implementations:

- **[HardeningKitty-Linux-Python](https://github.com/YourUsername/HardeningKitty-Linux-Python)** - Python implementation (lightweight, zero dependencies)
- **[HardeningKitty-Linux-PowerShell](https://github.com/YourUsername/HardeningKitty-Linux-PowerShell)** - PowerShell Core implementation (familiar syntax for Windows admins)

Both provide the same security hardening capabilities based on CIS Benchmarks and DISA STIG.
```

## GitHub Repository Settings

For each new repository:

1. **Settings → General**
   - Add description
   - Add topics/tags
   - Enable Issues
   - Enable Discussions (optional)

2. **Settings → Security**
   - Enable Dependabot alerts
   - Enable security advisories

3. **Settings → Pages** (optional)
   - Enable GitHub Pages for documentation

4. **Settings → Template repository** (optional)
   - Check "Template repository" if you want users to easily create copies

## CI/CD Considerations

After extraction, you may want to add:

### Python Repository
```yaml
# .github/workflows/python-tests.yml
name: Python Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.8'
      - name: Run tests
        run: |
          python -m pytest tests/
```

### PowerShell Repository
```yaml
# .github/workflows/powershell-tests.yml
name: PowerShell Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install PowerShell
        run: |
          wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb
          sudo dpkg -i powershell_7.4.0-1.deb_amd64.deb
      - name: Run tests
        run: |
          pwsh -Command "Import-Module ./HardeningKitty-Linux.psm1"
```

## Benefits of Separate Repositories

1. **Focused Issues**: Each implementation has its own issue tracker
2. **Independent Versioning**: Version numbers can evolve separately
3. **Clearer Purpose**: Users know immediately which implementation they're getting
4. **Easier Contribution**: Contributors can focus on one implementation
5. **Better Discoverability**: Easier to find via GitHub search
6. **Separate Stars/Forks**: Community engagement metrics per implementation

## Maintaining Compatibility

Even in separate repositories, maintain finding list compatibility:

1. **Finding List Format**: Keep the same CSV format
2. **Documentation**: Reference the shared format in both repos
3. **Sync Updates**: When adding new CIS benchmarks, update both
4. **Cross-Reference**: Link to the other implementation in README

## Complete Extraction Script

Here's a complete script to extract both:

```bash
#!/bin/bash

# Configuration
MAIN_REPO="https://github.com/TomHowarth/HardeningKitty.git"
PYTHON_REPO="https://github.com/YourUsername/HardeningKitty-Linux-Python.git"
POWERSHELL_REPO="https://github.com/YourUsername/HardeningKitty-Linux-PowerShell.git"
BRANCH="claude/reorganize-into-separate-repos-011CUdLShrPrTKceBNkp8urH"

# Extract Python
echo "Extracting Python implementation..."
git clone $MAIN_REPO temp-python
cd temp-python
git checkout $BRANCH
git subtree split --prefix=HardeningKitty-Python -b python-only
git push $PYTHON_REPO python-only:main
cd ..
rm -rf temp-python

# Extract PowerShell
echo "Extracting PowerShell implementation..."
git clone $MAIN_REPO temp-powershell
cd temp-powershell
git checkout $BRANCH
git subtree split --prefix=HardeningKitty-PowerShell -b powershell-only
git push $POWERSHELL_REPO powershell-only:main
cd ..
rm -rf temp-powershell

echo "Extraction complete!"
echo "Python repo: $PYTHON_REPO"
echo "PowerShell repo: $POWERSHELL_REPO"
```

## Summary

Both implementations are now self-contained and ready to be extracted into separate repositories. Choose the method that best fits your workflow:

- **Manual Copy**: Simple, fresh start
- **Git Subtree**: Preserves history
- **Template**: Easy for users to create copies

Each implementation can now evolve independently while maintaining compatibility through the shared finding list format.
