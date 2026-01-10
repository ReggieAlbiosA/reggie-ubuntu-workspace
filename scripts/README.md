# Python Utilities

Professional Python utilities for enhanced workspace management with proper data structures, type safety, and error handling.

## Why Python?

These Python scripts complement the Bash scripts by providing:
- ✅ **Structured data handling** (JSON, dataclasses)
- ✅ **Type safety** with type hints
- ✅ **Better error handling** and validation
- ✅ **Easier testing** and maintenance
- ✅ **Complex logic** that would be clunky in Bash

## Available Utilities

### 1. MCP Manager (`mcp_manager.py`)

Manage Claude Code MCP servers with proper data structures.

**Features:**
- List MCP server status
- Add/remove servers
- Install standard MCP servers
- Structured error handling
- Better than bash string parsing

**Usage:**
```bash
# Show status of all MCP servers
./scripts/mcp_manager.py status

# List servers
./scripts/mcp_manager.py list

# Install all standard servers
./scripts/mcp_manager.py install --github-token YOUR_TOKEN

# Remove a server
./scripts/mcp_manager.py remove --name github
```

**Integration with Bash:**
```bash
# In opt/claude-code.sh
python3 scripts/mcp_manager.py status
```

---

### 2. Git Identity Manager (`git_identity.py`)

Manage multiple git identities with structured data (JSON-based).

**Features:**
- Store identities in JSON format
- Interactive selection
- Validation and error checking
- Better than pipe-delimited files

**Usage:**
```bash
# Show current status
./scripts/git_identity.py status

# Add new identity
./scripts/git_identity.py add user@example.com "User Name" "Work"

# Interactive selection
./scripts/git_identity.py select

# Set active identity
./scripts/git_identity.py set user@example.com

# List all identities
./scripts/git_identity.py list

# Remove identity
./scripts/git_identity.py remove user@example.com
```

**Config format** (`~/.git-identities.json`):
```json
{
  "identities": [
    {
      "email": "work@company.com",
      "name": "John Doe",
      "label": "Work"
    },
    {
      "email": "personal@email.com",
      "name": "John Doe",
      "label": "Personal"
    }
  ]
}
```

**Migration from old format:**
```bash
# Old format: ~/.git-identities (pipe-delimited)
# work@company.com|John Doe|Work

# Convert to new format:
python3 -c "
import json
identities = []
with open('$HOME/.git-identities') as f:
    for line in f:
        email, name, label = line.strip().split('|')
        identities.append({'email': email, 'name': name, 'label': label})

with open('$HOME/.git-identities.json', 'w') as f:
    json.dump({'identities': identities}, f, indent=2)
"
```

---

### 3. Configuration Validator (`config_validator.py`)

Validate workspace configuration files and structure.

**Features:**
- Validate bash script syntax
- Check directory structure
- Validate git configuration
- Check file permissions
- Comprehensive reporting

**Usage:**
```bash
# Validate current workspace
./scripts/config_validator.py

# Validate specific workspace
./scripts/config_validator.py /path/to/workspace

# Check and attempt fixes
./scripts/config_validator.py --fix
```

**Checks performed:**
- ✅ Required files exist
- ✅ Required directories exist
- ✅ Bash scripts have valid syntax
- ✅ Scripts have proper error handling
- ✅ Scripts are executable
- ✅ Git repository is valid
- ✅ Git remote is correct
- ✅ No uncommitted changes (warning)

---

## Integration Patterns

### Pattern 1: Bash calls Python for data processing

```bash
#!/bin/bash
# opt/claude-code.sh

# Use Python for MCP management
if command -v python3 >/dev/null; then
    python3 scripts/mcp_manager.py status
else
    # Fallback to bash implementation
    claude mcp list | grep ...
fi
```

### Pattern 2: Python validates, Bash executes

```bash
#!/bin/bash
# setup.sh

# Validate configuration before running
if command -v python3 >/dev/null; then
    if ! python3 scripts/config_validator.py; then
        echo "Configuration validation failed!"
        exit 1
    fi
fi

# Continue with setup...
```

### Pattern 3: Python provides structured output

```bash
#!/bin/bash

# Get missing MCP servers as JSON
missing=$(python3 -c "
from scripts.mcp_manager import MCPManager
import json
manager = MCPManager()
print(json.dumps(manager.get_missing_servers()))
")

# Process in bash
for server in $(echo "$missing" | jq -r '.[]'); do
    echo "Installing $server..."
done
```

---

## Requirements

Python 3.7+ (built-in on Ubuntu 20.04+)

**No external dependencies!** All scripts use only Python standard library.

---

## Development

### Running Tests

```bash
# Python has built-in unittest
python3 -m pytest scripts/  # If you add tests

# Or use unittest
python3 -m unittest discover scripts/
```

### Type Checking

```bash
# Install mypy
pip3 install mypy

# Check types
mypy scripts/*.py
```

### Code Quality

```bash
# Format code
pip3 install black
black scripts/*.py

# Lint
pip3 install pylint
pylint scripts/*.py
```

---

## Architecture

```
scripts/
├── mcp_manager.py          # MCP server management
├── git_identity.py         # Git identity management
├── config_validator.py     # Configuration validation
└── lib/                    # Shared utilities (future)
    └── common.py
```

---

## Comparison: Bash vs Python

### Bash Approach (Old)
```bash
# Parse MCP list with grep
get_mcp_status() {
    local output="$(claude mcp list 2>/dev/null || true)"
    if grep -Fq "$name:" <<<"$output"; then
        if grep -Fq "Connected" <<<"$output"; then
            echo "connected"
        fi
    fi
}
```

**Problems:**
- ❌ Fragile string parsing
- ❌ No data validation
- ❌ Hard to test
- ❌ Breaks if format changes

### Python Approach (New)
```python
@dataclass
class MCPServer:
    name: str
    status: MCPStatus

def list_servers() -> List[MCPServer]:
    output = subprocess.run(["claude", "mcp", "list"], ...)
    return [parse_server(line) for line in output]
```

**Benefits:**
- ✅ Structured data
- ✅ Type-safe
- ✅ Easy to test
- ✅ Robust error handling

---

## Best Practices

1. **Use Python for:**
   - Data processing (JSON, YAML)
   - Complex validation logic
   - Structured data storage
   - API interactions

2. **Use Bash for:**
   - System commands (apt, git, curl)
   - File operations
   - Orchestration
   - Simple scripts

3. **Integration:**
   - Bash scripts check if Python is available
   - Fallback to bash if Python missing
   - Python scripts are standalone (can be called independently)

---

## Future Enhancements

Potential additions:
- [ ] Web interface (Flask/FastAPI)
- [ ] Remote workspace sync
- [ ] Backup/restore configurations
- [ ] Plugin system
- [ ] Auto-update checker
- [ ] Telemetry (optional)

---

## Examples

### Example 1: Check MCP Status from Bash

```bash
#!/bin/bash

# Check if better-auth is connected
if python3 scripts/mcp_manager.py list | grep -q "better-auth.*connected"; then
    echo "✓ MCP better-auth is ready"
else
    echo "Installing better-auth..."
    python3 scripts/mcp_manager.py install
fi
```

### Example 2: Validate Before Commit (Git Hook)

```bash
#!/bin/bash
# .git-hooks/pre-commit

# Validate configuration
if ! python3 scripts/config_validator.py; then
    echo "❌ Configuration validation failed!"
    echo "Fix issues before committing."
    exit 1
fi

echo "✓ Configuration valid"
```

### Example 3: Auto-select Git Identity

```bash
#!/bin/bash

# Detect repo and auto-select identity
repo_url=$(git remote get-url origin)

if [[ "$repo_url" == *"company.com"* ]]; then
    python3 scripts/git_identity.py set work@company.com
elif [[ "$repo_url" == *"github.com"* ]]; then
    python3 scripts/git_identity.py set personal@github.com
fi
```

---

## Contributing

When adding new Python utilities:

1. **Use dataclasses** for structured data
2. **Add type hints** for all functions
3. **Include docstrings** (Google style)
4. **Handle errors** gracefully
5. **Make scripts executable** (`chmod +x`)
6. **Add shebang** (`#!/usr/bin/env python3`)
7. **Write tests** (if complex logic)
8. **Update this README**

---

## License

Part of the Reggie Ubuntu Workspace project.
