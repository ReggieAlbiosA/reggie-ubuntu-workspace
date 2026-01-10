# ruw - Reggie Ubuntu Workspace CLI

A professional CLI tool for managing the Reggie Ubuntu Workspace, written in Go.

## Features

- 🔍 **Smart workspace discovery** - Automatically finds your workspace
- 🚀 **Easy updates** - Run `ruw update` from anywhere
- 📊 **Status checking** - View workspace status and git info
- 🏥 **Health checks** - Verify system dependencies
- ✅ **Robust error handling** - Clear error messages
- 🧪 **Well-tested** - Comprehensive test coverage
- 📦 **Single binary** - No dependencies, just one executable

## Installation

### Prerequisites

Install Go (1.21 or later):
```bash
sudo snap install go --classic
```

### Build and Install

```bash
cd cmd/ruw
make install
```

This will:
1. Download dependencies
2. Build the binary
3. Install to `~/.local/bin/ruw`

Make sure `~/.local/bin` is in your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Update Workspace

```bash
# Interactive update
ruw update

# Auto-accept all prompts
ruw update -y

# Update core only (skip optional modules)
ruw update --skip-optional
```

### Check Status

```bash
ruw status
```

Shows:
- Workspace location
- Git branch and status
- Uncommitted changes
- Sync status with remote
- Available components

### Health Check

```bash
ruw doctor
```

Checks:
- Workspace validity
- Required commands (git, bash, curl, sudo)
- Optional tools (node, npm, claude, vscode, cursor)
- Git configuration

### Version Info

```bash
ruw version
```

## Development

### Build

```bash
make build
```

Binary will be in `build/ruw`

### Run Tests

```bash
make test
```

### Test with Coverage

```bash
make test-coverage
```

Opens coverage report in browser.

### Run Without Installing

```bash
# Run development version
make dev ARGS="status"

# Or directly with go
go run . status
```

### Development Workflow

```bash
# Format code
make fmt

# Run linters
make lint

# Clean build artifacts
make clean

# Watch for changes and rebuild (requires entr)
make watch ARGS="status"
```

## Architecture

```
cmd/ruw/
├── main.go              # Entry point
├── go.mod               # Go module definition
├── Makefile             # Build automation
├── cmd/                 # CLI commands
│   ├── root.go          # Root command
│   ├── update.go        # Update command
│   ├── status.go        # Status command
│   ├── doctor.go        # Health check command
│   └── version.go       # Version command
└── workspace/           # Workspace logic
    ├── finder.go        # Workspace discovery
    └── finder_test.go   # Tests
```

## Why Go?

**Improvements over Bash version:**

1. **Error Handling** - Proper error types, clear messages
2. **Type Safety** - Compile-time checks prevent bugs
3. **Testing** - Easy to write and run tests
4. **Distribution** - Single binary, no dependencies
5. **Performance** - Compiled, faster execution
6. **Maintainability** - Clear structure, easy to extend
7. **Cross-platform** - Could support macOS/Windows

## Comparison: Bash vs Go

### Bash (Original)
```bash
find_workspace() {
    if [ -f "$WORKSPACE_PATH_FILE" ]; then
        local cached_path=$(cat "$WORKSPACE_PATH_FILE")
        if [ -d "$cached_path" ] && [ -f "$cached_path/setup.sh" ]; then
            # ... nested ifs
        fi
    fi
}
```

Problems:
- ❌ Hard to test
- ❌ Error handling unclear
- ❌ Nested logic hard to follow
- ❌ No type safety

### Go (New)
```go
func FindWorkspace() (*Workspace, error) {
    if ws, err := findCached(); err == nil {
        return ws, nil
    }

    for _, path := range searchPaths() {
        if ws, err := validateWorkspace(path); err == nil {
            cache(ws)
            return ws, nil
        }
    }

    return nil, fmt.Errorf("workspace not found")
}
```

Benefits:
- ✅ Easy to test
- ✅ Clear error handling
- ✅ Clean, readable logic
- ✅ Type-safe

## Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `ruw update` | Update workspace | `ruw update -y` |
| `ruw status` | Show status | `ruw status` |
| `ruw doctor` | Health check | `ruw doctor` |
| `ruw version` | Show version | `ruw version` |
| `ruw help` | Show help | `ruw help update` |

## Configuration

Configuration is stored in `~/.config/ruw/`:
- `workspace-path` - Cached workspace location

## Troubleshooting

### Command not found
Make sure `~/.local/bin` is in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Workspace not found
Clear cache and try again:
```bash
rm -rf ~/.config/ruw
ruw status
```

### Build errors
Update Go dependencies:
```bash
make deps
```

## Contributing

1. Make changes
2. Run tests: `make test`
3. Format code: `make fmt`
4. Run linters: `make lint`
5. Build: `make build`

## License

Part of the Reggie Ubuntu Workspace project.
