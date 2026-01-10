# Quick Reference Card

## Essential Commands

### Go CLI (`ruw`)
```bash
ruw update              # Update workspace
ruw update -y           # Update with auto-accept
ruw status              # Show workspace status
ruw doctor              # Health check
ruw version             # Show version
```

### Python Utilities
```bash
./scripts/mcp_manager.py status           # MCP status
./scripts/git_identity.py select          # Select git identity
./scripts/config_validator.py             # Validate config
```

### Bash Scripts (Original)
```bash
./setup.sh                    # Main setup
./def/apps.sh                 # Install apps
./def/packages.sh             # Install packages
bash opt/aliases.sh           # Setup aliases
```

---

## First Time Setup

```bash
# 1. Install Go
sudo snap install go --classic

# 2. Build ruw
cd cmd/ruw && make install && cd ../..

# 3. Run setup
ruw update

# 4. Test
ruw status && ruw doctor
```

---

## Daily Workflow

```bash
# Morning: Check status
ruw status

# Check health
ruw doctor

# Update when needed
ruw update

# Manage git identity
./scripts/git_identity.py select
```

---

## File Structure

```
reggie-ubuntu-workspace/
├── setup.sh                    # Main entry
├── bin/ruw (old bash)          # Legacy
├── cmd/ruw/                    # Go CLI ⭐
│   ├── main.go
│   ├── cmd/                    # Commands
│   └── workspace/              # Logic
├── scripts/                    # Python utilities ⭐
│   ├── mcp_manager.py
│   ├── git_identity.py
│   └── config_validator.py
├── def/                        # Bash install scripts
│   ├── packages.sh
│   └── apps.sh
└── opt/                        # Bash config scripts
    ├── aliases.sh
    ├── claude-code.sh
    └── git-identity.sh
```

---

## Language Usage Guide

| Task | Use | Command |
|------|-----|---------|
| Update workspace | **Go** | `ruw update` |
| Check status | **Go** | `ruw status` |
| MCP management | **Python** | `./scripts/mcp_manager.py` |
| Git identities | **Python** | `./scripts/git_identity.py` |
| Validation | **Python** | `./scripts/config_validator.py` |
| System packages | **Bash** | `./def/packages.sh` |
| Apps install | **Bash** | `./def/apps.sh` |

---

## Troubleshooting

### Command not found
```bash
# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Rebuild everything
```bash
cd cmd/ruw
make clean && make install
chmod +x ../../scripts/*.py
```

### Reset configuration
```bash
rm -rf ~/.config/ruw
rm ~/.git-identities.json
ruw status  # Will re-find workspace
```

---

## Documentation

- `BUILD_AND_INSTALL.md` - Complete build guide
- `INTEGRATION_GUIDE.md` - How everything works together
- `cmd/ruw/README.md` - Go CLI details
- `scripts/README.md` - Python utilities details
- `README.md` - Main project README

---

## Quick Tips

### Aliases
```bash
# Add to ~/.bashrc
alias ws='ruw status'
alias wsu='ruw update -y'
alias wsd='ruw doctor'
alias mcp='python3 scripts/mcp_manager.py'
alias git-id='python3 scripts/git_identity.py'
```

### Git Hook
```bash
# Validate before commit
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash
python3 scripts/config_validator.py || exit 1
EOF
chmod +x .git/hooks/pre-commit
```

### Cron Job
```bash
# Daily health check
0 9 * * * /usr/bin/ruw doctor > /tmp/workspace-health.log 2>&1
```

---

## Version Info

Check versions:
```bash
ruw version
python3 --version
go version
bash --version
```

Expected:
- Go: 1.21+
- Python: 3.7+
- Bash: 5.0+

---

## Getting Help

1. **Documentation:** Read guides in project root
2. **Help commands:** `ruw --help`, `./scripts/mcp_manager.py --help`
3. **Verbose mode:** `ruw -v status`
4. **Issues:** GitHub issues

---

**Print this card and keep it handy! 📋**
