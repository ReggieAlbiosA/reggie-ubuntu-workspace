# Build and Install Guide

Complete guide to building and installing the enhanced workspace tools (Go + Python + Bash).

## Quick Start (5 minutes)

```bash
# 1. Install Go
sudo snap install go --classic

# 2. Build ruw CLI
cd cmd/ruw
make install

# 3. Verify installation
ruw version
ruw status

# 4. Use it!
ruw update
```

---

## Detailed Installation

### Step 1: Prerequisites

```bash
# Check current environment
python3 --version   # Should be 3.7+ (pre-installed on Ubuntu)
git --version       # Should be installed
bash --version      # Should be installed

# Install Go (if not already installed)
go version 2>/dev/null || sudo snap install go --classic

# Verify Go installation
go version   # Should show go1.21 or later
```

### Step 2: Clone Repository (if needed)

```bash
# If you don't have the workspace yet
cd ~/Documents
git clone https://github.com/ReggieAlbiosA/reggie-ubuntu-workspace.git
cd reggie-ubuntu-workspace
```

### Step 3: Build Go CLI Tool (`ruw`)

```bash
cd cmd/ruw

# Download Go dependencies
make deps

# Run tests (optional but recommended)
make test

# Build and install
make install
```

This will:
- Create `build/ruw` binary
- Copy to `~/.local/bin/ruw`
- Make it executable

### Step 4: Verify Installation

```bash
# Check ruw is in PATH
which ruw
# Should output: /home/USERNAME/.local/bin/ruw

# Test it works
ruw version
ruw status
ruw doctor
```

If "command not found", add to PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Step 5: Make Python Scripts Executable

```bash
cd ~/Documents/reggie-ubuntu-workspace

# Make all Python scripts executable
chmod +x scripts/*.py

# Test them
./scripts/mcp_manager.py --help
./scripts/git_identity.py --help
./scripts/config_validator.py --help
```

### Step 6: Run Initial Setup

```bash
# Option 1: Use new Go CLI (recommended)
ruw update

# Option 2: Use original bash script
./setup.sh
```

---

## Build Options

### Development Build

For development and testing:

```bash
cd cmd/ruw

# Build without installing
make build

# Run directly
./build/ruw status

# Run with go run (no build)
make dev ARGS="status"
```

### Release Build

For distribution:

```bash
cd cmd/ruw

# Create release binary with version info
make release

# Output: dist/ruw-VERSION-linux-amd64
```

### Build with Custom Version

```bash
cd cmd/ruw

# Build with specific version
VERSION=2.0.0 make build

# Verify
./build/ruw version
```

---

## Installation Locations

### Go Binary

```
~/.local/bin/ruw          # Installed binary
~/.config/ruw/            # Configuration directory
~/.config/ruw/workspace-path   # Cached workspace path
```

### Python Scripts

```
scripts/mcp_manager.py          # MCP management
scripts/git_identity.py         # Git identities
scripts/config_validator.py     # Configuration validation
~/.git-identities.json          # Git identities config (new format)
```

### Source Files

```
cmd/ruw/                  # Go source code
├── main.go               # Entry point
├── go.mod                # Go dependencies
├── Makefile              # Build automation
├── cmd/                  # Commands
│   ├── root.go
│   ├── update.go
│   ├── status.go
│   ├── doctor.go
│   └── version.go
└── workspace/            # Workspace logic
    ├── finder.go
    └── finder_test.go
```

---

## Verification

### Test All Components

```bash
# 1. Test Go CLI
ruw version
ruw status
ruw doctor

# 2. Test Python utilities
./scripts/mcp_manager.py status
./scripts/git_identity.py status
./scripts/config_validator.py

# 3. Test bash scripts
bash -n setup.sh
bash -n def/packages.sh
bash -n def/apps.sh
```

### Run Full Test Suite

```bash
# Go tests
cd cmd/ruw
make test
make test-coverage

# Python tests (if you add them)
python3 -m pytest scripts/

# Bash syntax checks
for script in **/*.sh; do
    bash -n "$script" || echo "Syntax error in $script"
done
```

---

## Updating

### Update Go CLI

```bash
cd cmd/ruw

# Pull latest changes
git pull

# Rebuild and reinstall
make install

# Verify new version
ruw version
```

### Update Python Scripts

```bash
# Pull latest changes
git pull

# Make executable (if needed)
chmod +x scripts/*.py

# Test
./scripts/mcp_manager.py --help
```

---

## Uninstalling

### Remove Go Binary

```bash
# Remove installed binary
rm ~/.local/bin/ruw

# Remove configuration
rm -rf ~/.config/ruw

# Remove build artifacts
cd cmd/ruw
make clean
```

### Remove Python Configs

```bash
# Remove git identities
rm ~/.git-identities.json
rm ~/.git-identities.bak
```

### Keep Workspace

The workspace itself (bash scripts, configs) stays in place.

---

## Troubleshooting

### "go: command not found"

```bash
# Install Go
sudo snap install go --classic

# Verify
go version

# Restart terminal
source ~/.bashrc
```

### "make: command not found"

```bash
# Install build-essential
sudo apt update
sudo apt install build-essential

# Verify
make --version
```

### "ruw: command not found"

```bash
# Check if installed
ls ~/.local/bin/ruw

# If exists, add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# If not exists, install again
cd cmd/ruw
make install
```

### Build errors

```bash
# Clean and rebuild
cd cmd/ruw
make clean
make deps
make build

# Check Go version
go version   # Need 1.21+

# Update Go if needed
sudo snap refresh go --channel=latest/stable
```

### Tests failing

```bash
# Run verbose tests
cd cmd/ruw
go test -v ./...

# Run specific test
go test -v ./workspace -run TestValidateWorkspace
```

### Python script errors

```bash
# Check Python version
python3 --version   # Need 3.7+

# Make executable
chmod +x scripts/*.py

# Run with full path
python3 $(pwd)/scripts/mcp_manager.py status
```

---

## Development Setup

For contributors:

### 1. Install Development Tools

```bash
# Go tools
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Python tools
pip3 install --user black mypy pylint pytest
```

### 2. Configure Editor

**VS Code:**
```json
{
  "go.useLanguageServer": true,
  "go.lintTool": "golangci-lint",
  "go.formatTool": "goimports",
  "python.formatting.provider": "black",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true
}
```

### 3. Pre-commit Hook

```bash
# Install pre-commit hook
cp .git-hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

### 4. Watch Mode (Development)

```bash
# Watch and rebuild on changes (requires entr)
sudo apt install entr

cd cmd/ruw
make watch ARGS="status"
```

---

## Platform-Specific Notes

### Ubuntu 20.04+
- ✅ Python 3.8+ pre-installed
- ✅ Bash 5.0+ pre-installed
- ✅ Go via snap works perfectly

### Ubuntu 18.04
- ⚠️  Python 3.6 (works but 3.7+ recommended)
- ⚠️  May need to update Go manually

### Debian
- ✅ Similar to Ubuntu
- ⚠️  Use `apt` instead of `snap` for Go if preferred

### Other Linux
- ✅ Should work on any Linux with Go 1.21+
- ⚠️  Paths might differ
- ⚠️  Test thoroughly

---

## Performance

### Build Times

```
Initial build:      ~10 seconds
Incremental build:  ~2 seconds
Install:            < 1 second
Tests:              ~3 seconds
```

### Binary Size

```
ruw binary:         ~8-12 MB (statically linked)
Python scripts:     ~50 KB (source)
```

### Runtime Performance

```
ruw update:         Same as bash (calls setup.sh)
ruw status:         < 100ms
ruw doctor:         < 200ms
Python scripts:     < 500ms startup
```

---

## Distribution

### Share ruw Binary

```bash
# Build release
cd cmd/ruw
make release

# Share binary
cp dist/ruw-*-linux-amd64 /shared/location/ruw

# Users can install
chmod +x ruw
mv ruw ~/.local/bin/
```

### Package for Distribution

```bash
# Create tarball
tar -czf reggie-workspace-tools.tar.gz \
    cmd/ruw/build/ruw \
    scripts/*.py \
    README.md \
    INTEGRATION_GUIDE.md

# Users extract and install
tar -xzf reggie-workspace-tools.tar.gz
./install.sh
```

---

## Next Steps

After installation:

1. **Try the new tools:**
   ```bash
   ruw status
   ruw doctor
   ./scripts/mcp_manager.py status
   ```

2. **Read integration guide:**
   ```bash
   cat INTEGRATION_GUIDE.md
   ```

3. **Migrate your data:**
   ```bash
   # Convert git identities to JSON
   ./scripts/git_identity.py status
   ```

4. **Set up aliases:**
   ```bash
   # Add to ~/.bashrc
   alias ws='ruw status'
   alias wsu='ruw update'
   alias wsd='ruw doctor'
   ```

5. **Customize as needed:**
   - Modify Python scripts for your workflow
   - Add custom Go commands
   - Extend bash scripts

---

## Support

### Documentation

- **Go CLI:** `cmd/ruw/README.md`
- **Python Scripts:** `scripts/README.md`
- **Integration:** `INTEGRATION_GUIDE.md`
- **Main README:** `README.md`

### Getting Help

1. Check documentation
2. Run with verbose flag: `ruw -v status`
3. Check logs: `ruw doctor`
4. Open an issue on GitHub

### Contributing

Contributions welcome! See INTEGRATION_GUIDE.md for patterns and best practices.

---

## Changelog

### v1.0.0 - Enhanced Release
- ✅ Go CLI tool (`ruw`)
- ✅ Python utilities (MCP, Git Identity, Validator)
- ✅ Comprehensive documentation
- ✅ Integration guide
- ✅ Tests and validation

### v0.9.0 - Bash Only
- Original bash-only implementation

---

**You're all set! Enjoy your enhanced workspace! 🎉**
