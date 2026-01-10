# Integration Guide: Bash + Go + Python

This guide shows how to use the hybrid architecture combining Bash, Go, and Python for maximum quality and maintainability.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Getting Started](#getting-started)
3. [Using the Go CLI (`ruw`)](#using-the-go-cli-ruw)
4. [Using Python Utilities](#using-python-utilities)
5. [Integration Patterns](#integration-patterns)
6. [Migration Guide](#migration-guide)
7. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
Reggie Ubuntu Workspace (Hybrid Architecture)
│
├── Bash Layer (Orchestration)
│   ├── setup.sh              # Main entry point
│   ├── def/*.sh              # System package management
│   └── opt/*.sh              # Optional configurations
│
├── Go Layer (CLI Tools)
│   └── cmd/ruw/              # Professional CLI tool
│       ├── workspace/        # Workspace discovery
│       └── cmd/              # Commands (update, status, doctor)
│
└── Python Layer (Data Processing)
    └── scripts/
        ├── mcp_manager.py           # MCP server management
        ├── git_identity.py          # Git identity management
        └── config_validator.py      # Configuration validation
```

### When to Use Each Language

| Task | Use | Why |
|------|-----|-----|
| System commands | **Bash** | Direct access to apt, snap, git, etc. |
| File operations | **Bash** | Native file manipulation |
| CLI tool | **Go** | Single binary, great UX, fast |
| Data processing | **Python** | JSON/structured data, validation |
| Complex logic | **Python** | Type safety, easier testing |
| Orchestration | **Bash** | Gluing tools together |

---

## Getting Started

### Prerequisites

```bash
# 1. Install Go (for ruw CLI)
sudo snap install go --classic

# 2. Python is already installed on Ubuntu
python3 --version  # Should be 3.7+

# 3. Clone the workspace (if not already done)
git clone https://github.com/ReggieAlbiosA/reggie-ubuntu-workspace.git
cd reggie-ubuntu-workspace
```

### Build and Install

```bash
# 1. Build Go CLI tool
cd cmd/ruw
make install
cd ../..

# 2. Make Python scripts executable (already done)
chmod +x scripts/*.py

# 3. Run initial setup
./setup.sh
```

---

## Using the Go CLI (`ruw`)

The `ruw` command is your primary interface to the workspace.

### Basic Commands

```bash
# Update workspace (replaces old bash ruw script)
ruw update              # Interactive
ruw update -y           # Auto-accept
ruw update --skip-optional   # Core only

# Check workspace status
ruw status

# Health check system dependencies
ruw doctor

# Show version
ruw version
```

### Examples

#### Example 1: Update from anywhere

```bash
# Old way (bash script)
cd ~/Documents/reggie-ubuntu-workspace
./setup.sh

# New way (Go binary)
ruw update    # Works from any directory!
```

#### Example 2: Health check before important work

```bash
# Before starting development
ruw doctor

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   System Health Check
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📁 Workspace
#   ✓ Workspace found
#     Location: /home/user/Documents/reggie-ubuntu-workspace
#
# 🔧 Required Commands
#   ✓ git
#   ✓ bash
#   ✓ curl
#   ✓ sudo
# ...
```

#### Example 3: Check workspace status

```bash
ruw status

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Workspace Status
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📁 Location: /home/user/Documents/reggie-ubuntu-workspace
# 🔗 Remote: https://github.com/ReggieAlbiosA/reggie-ubuntu-workspace.git
# 🌿 Branch: main
# 📝 Changes: Clean
# 🔄 Sync: Up to date
# ...
```

---

## Using Python Utilities

Python utilities provide structured data handling and validation.

### MCP Manager

```bash
# Check MCP server status
./scripts/mcp_manager.py status

# List all servers with status
./scripts/mcp_manager.py list

# Install all standard MCP servers
./scripts/mcp_manager.py install --github-token YOUR_TOKEN

# Remove a specific server
./scripts/mcp_manager.py remove --name github
```

### Git Identity Manager

```bash
# Interactive selection (easiest)
./scripts/git_identity.py select

# Add new identity
./scripts/git_identity.py add work@company.com "John Doe" "Work"

# List all identities
./scripts/git_identity.py list

# Set active identity
./scripts/git_identity.py set work@company.com

# Show current status
./scripts/git_identity.py status
```

### Configuration Validator

```bash
# Validate current workspace
./scripts/config_validator.py

# Validate specific path
./scripts/config_validator.py /path/to/workspace

# Attempt automatic fixes
./scripts/config_validator.py --fix
```

---

## Integration Patterns

### Pattern 1: Bash → Python (Data Processing)

Use Python when Bash string parsing becomes complex.

**Example: MCP Status Check**

```bash
#!/bin/bash
# opt/claude-code.sh (enhanced)

check_mcp_servers() {
    if command -v python3 >/dev/null; then
        # Use Python for structured data
        python3 scripts/mcp_manager.py status
    else
        # Fallback to bash
        claude mcp list | grep -E "Connected|Failed"
    fi
}
```

### Pattern 2: Bash → Go (CLI Operations)

Use Go for complex CLI logic.

**Example: Workspace Update**

```bash
#!/bin/bash
# bin/update-workspace.sh (wrapper)

# Use Go CLI if available, fallback to bash
if command -v ruw >/dev/null; then
    ruw update "$@"
else
    # Fallback to old bash implementation
    cd ~/Documents/reggie-ubuntu-workspace
    ./setup.sh "$@"
fi
```

### Pattern 3: Python → Bash (Execution)

Python validates, Bash executes.

**Example: Validated Installation**

```bash
#!/bin/bash
# setup.sh (enhanced)

# Validate configuration before running
if command -v python3 >/dev/null; then
    echo "Validating configuration..."
    if ! python3 scripts/config_validator.py; then
        echo "❌ Configuration validation failed!"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Continue with normal setup
echo "Running setup..."
```

### Pattern 4: Go → Bash (Legacy Support)

Go calls Bash scripts for system operations.

**Example: ruw update command**

```go
// cmd/ruw/cmd/update.go

func runUpdate(cmd *cobra.Command, args []string) error {
    ws, _ := workspace.FindWorkspace()

    // Call bash script for actual work
    setupCmd := exec.Command("bash", "setup.sh", "-y")
    setupCmd.Dir = ws.Path
    setupCmd.Stdout = os.Stdout

    return setupCmd.Run()
}
```

---

## Migration Guide

### Migrating from Old Bash `ruw` to Go `ruw`

The old bash script is at `bin/ruw` (backed up as `bin/ruw.sh.bak`).

**Steps:**

1. **Build Go version:**
   ```bash
   cd cmd/ruw
   make install
   ```

2. **Test it works:**
   ```bash
   ruw version
   ruw status
   ```

3. **Use Go version:**
   ```bash
   # Old
   ruw --local-update

   # New
   ruw update
   ```

4. **Keep bash version as backup:**
   ```bash
   # If needed, run old version
   bash bin/ruw.sh.bak --local-update
   ```

### Migrating Git Identities to JSON

Old format: `~/.git-identities` (pipe-delimited)
```
work@company.com|John Doe|Work
personal@email.com|John Doe|Personal
```

New format: `~/.git-identities.json`
```json
{
  "identities": [
    {"email": "work@company.com", "name": "John Doe", "label": "Work"},
    {"email": "personal@email.com", "name": "John Doe", "label": "Personal"}
  ]
}
```

**Migration script:**

```bash
#!/bin/bash

# Convert old format to new
python3 << 'PYTHON'
import json
from pathlib import Path

old_file = Path.home() / ".git-identities"
new_file = Path.home() / ".git-identities.json"

if not old_file.exists():
    print("No old file found")
    exit(0)

identities = []
with open(old_file) as f:
    for line in f:
        if '|' in line:
            email, name, label = line.strip().split('|')
            identities.append({
                "email": email,
                "name": name,
                "label": label
            })

with open(new_file, 'w') as f:
    json.dump({"identities": identities}, f, indent=2)

print(f"✓ Migrated {len(identities)} identities to {new_file}")

# Backup old file
old_file.rename(Path.home() / ".git-identities.bak")
print("✓ Old file backed up as ~/.git-identities.bak")
PYTHON
```

---

## Best Practices

### 1. Always Check for Tools

```bash
# Check if enhanced tools are available
if command -v ruw >/dev/null; then
    # Use Go version
    ruw status
else
    # Fallback to bash
    echo "Workspace: $(pwd)"
fi
```

### 2. Fail Gracefully

```bash
# Python script might not be available
if python3 scripts/config_validator.py 2>/dev/null; then
    echo "✓ Configuration valid"
else
    echo "⚠ Could not validate configuration (python3 not available)"
fi
```

### 3. Use Type Safety Where It Matters

For data processing and validation, prefer Python/Go over Bash:

```bash
# Bad: Complex bash string manipulation
status=$(claude mcp list | grep "$name" | cut -d: -f2 | tr -d ' ')

# Good: Use Python for structured parsing
status=$(python3 scripts/mcp_manager.py list --format=json | jq -r ".[] | select(.name==\"$name\") | .status")
```

### 4. Log Operations

```bash
# Log when using enhanced tools
echo "[ruw] Using Go CLI for workspace update" >&2
ruw update

# vs plain bash
echo "[setup] Running bash setup script" >&2
./setup.sh
```

---

## Troubleshooting

### Go binary not found

```bash
# Check if installed
which ruw

# If not found, add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Reinstall
cd cmd/ruw
make install
```

### Python script fails

```bash
# Check Python version
python3 --version   # Need 3.7+

# Make scripts executable
chmod +x scripts/*.py

# Run with python3 explicitly
python3 scripts/mcp_manager.py status
```

### Workspace not found

```bash
# Clear cache
rm -rf ~/.config/ruw

# Try finding workspace
ruw status

# If still fails, specify path
cd /path/to/workspace
ruw update
```

### MCP manager can't find claude

```bash
# Check claude installed
which claude

# If not, install
sudo npm install -g @anthropic-ai/claude-code

# Source bashrc
source ~/.bashrc
```

---

## Advanced Usage

### Custom Git Hooks with Python Validation

```bash
# .git-hooks/pre-commit

#!/bin/bash
set -e

echo "Running pre-commit checks..."

# 1. Validate configuration
if ! python3 scripts/config_validator.py; then
    echo "❌ Configuration invalid"
    exit 1
fi

# 2. Check bash syntax
for script in $(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$'); do
    if ! bash -n "$script"; then
        echo "❌ Syntax error in $script"
        exit 1
    fi
done

# 3. Auto-format Python files
for script in $(git diff --cached --name-only --diff-filter=ACM | grep '\.py$'); do
    if command -v black >/dev/null; then
        black "$script"
        git add "$script"
    fi
done

echo "✓ Pre-commit checks passed"
```

### Automated Workspace Health Monitoring

```bash
#!/bin/bash
# monitor-workspace.sh

# Run health check daily
while true; do
    ruw doctor > /tmp/workspace-health.log 2>&1

    if [ $? -ne 0 ]; then
        # Send notification
        notify-send "Workspace Health" "Issues detected. Run 'ruw doctor'"
    fi

    sleep 86400  # 24 hours
done
```

---

## Summary

### Quick Reference

| Task | Command | Layer |
|------|---------|-------|
| Update workspace | `ruw update` | Go |
| Check status | `ruw status` | Go |
| Health check | `ruw doctor` | Go |
| MCP management | `python3 scripts/mcp_manager.py status` | Python |
| Git identities | `python3 scripts/git_identity.py select` | Python |
| Validate config | `python3 scripts/config_validator.py` | Python |
| Install packages | `bash def/packages.sh` | Bash |
| Install apps | `bash def/apps.sh` | Bash |

### Architecture Benefits

| Benefit | How |
|---------|-----|
| **Better UX** | Go CLI with colors, progress, clear errors |
| **Type Safety** | Python dataclasses, Go structs |
| **Testing** | Easy to test Go/Python, harder for Bash |
| **Maintainability** | Clear structure, separation of concerns |
| **Distribution** | Single Go binary, no dependencies |
| **Flexibility** | Use each language for its strengths |

---

## Contributing

When adding features:

1. **Choose the right tool:**
   - System commands → Bash
   - CLI interface → Go
   - Data processing → Python

2. **Follow patterns:**
   - Check tool availability
   - Provide fallbacks
   - Handle errors gracefully

3. **Document integration:**
   - Update this guide
   - Add examples
   - Show both old and new ways

---

## Questions?

- **Go CLI issues:** See `cmd/ruw/README.md`
- **Python scripts:** See `scripts/README.md`
- **Bash scripts:** See main `README.md`
- **General questions:** Open an issue

---

**Happy workspace managing! 🚀**
