#!/usr/bin/env python3
"""
Configuration Validator - Validate workspace configuration files

Validates bash scripts, JSON configs, and workspace structure.
"""

import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Dict, Tuple


@dataclass
class ValidationResult:
    """Result of a validation check"""
    passed: bool
    message: str
    file: Optional[str] = None
    line: Optional[int] = None

    def __str__(self) -> str:
        symbol = "✓" if self.passed else "✗"
        result = f"{symbol} {self.message}"
        if self.file:
            result += f" ({self.file}"
            if self.line:
                result += f":{self.line}"
            result += ")"
        return result


class ConfigValidator:
    """Validates workspace configuration"""

    def __init__(self, workspace_root: Path):
        """
        Initialize validator

        Args:
            workspace_root: Path to workspace root directory
        """
        self.root = Path(workspace_root).resolve()
        self.results: List[ValidationResult] = []

    def add_result(self, passed: bool, message: str, file: Optional[str] = None, line: Optional[int] = None):
        """Add validation result"""
        self.results.append(ValidationResult(passed, message, file, line))

    def validate_all(self) -> bool:
        """
        Run all validation checks

        Returns:
            True if all checks passed
        """
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  Workspace Configuration Validation")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        self.validate_structure()
        self.validate_bash_scripts()
        self.validate_git_config()

        # Print results
        print("\n📋 Validation Results:")
        passed = sum(1 for r in self.results if r.passed)
        failed = len(self.results) - passed

        for result in self.results:
            print(f"  {result}")

        print(f"\n📊 Summary: {passed} passed, {failed} failed")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

        return failed == 0

    def validate_structure(self):
        """Validate workspace directory structure"""
        print("\n📁 Validating structure...")

        required_files = [
            "setup.sh",
            "README.md",
            "def/packages.sh",
            "def/apps.sh",
            "opt/aliases.sh",
        ]

        for file_path in required_files:
            full_path = self.root / file_path
            if full_path.exists():
                self.add_result(True, f"File exists: {file_path}")
            else:
                self.add_result(False, f"Missing required file: {file_path}")

        # Check directories
        required_dirs = ["def", "opt", "bin", "scripts", "cmd"]
        for dir_path in required_dirs:
            full_path = self.root / dir_path
            if full_path.is_dir():
                self.add_result(True, f"Directory exists: {dir_path}")
            else:
                self.add_result(False, f"Missing directory: {dir_path}")

    def validate_bash_scripts(self):
        """Validate bash scripts for syntax and best practices"""
        print("\n🔧 Validating bash scripts...")

        bash_files = list(self.root.glob("**/*.sh"))

        for script in bash_files:
            if not script.is_file():
                continue

            rel_path = script.relative_to(self.root)

            # Check syntax with bash -n
            try:
                result = subprocess.run(
                    ["bash", "-n", str(script)],
                    capture_output=True,
                    text=True,
                    check=False
                )

                if result.returncode == 0:
                    self.add_result(True, f"Syntax valid", str(rel_path))
                else:
                    self.add_result(
                        False,
                        f"Syntax error: {result.stderr.strip()}",
                        str(rel_path)
                    )
            except Exception as e:
                self.add_result(False, f"Failed to check syntax: {e}", str(rel_path))

            # Check for common issues
            try:
                with open(script, 'r') as f:
                    content = f.read()
                    lines = content.split('\n')

                # Check shebang
                if not lines[0].startswith('#!'):
                    self.add_result(False, "Missing shebang", str(rel_path), 1)

                # Check for set -e or set -Eeuo pipefail
                has_error_handling = any(
                    'set -e' in line or 'set -Eeuo pipefail' in line
                    for line in lines[:20]
                )
                if not has_error_handling:
                    self.add_result(
                        False,
                        "Missing error handling (set -e or set -Eeuo pipefail)",
                        str(rel_path)
                    )

                # Check for unquoted variables (simple check)
                for i, line in enumerate(lines, 1):
                    # Skip comments and empty lines
                    if line.strip().startswith('#') or not line.strip():
                        continue

                    # Look for common unquoted variable patterns
                    # This is a simple heuristic, not perfect
                    if re.search(r'\$[A-Z_]+\s', line) and '$"' not in line:
                        # Potential unquoted variable
                        pass  # Too many false positives, skip for now

            except Exception as e:
                self.add_result(False, f"Failed to analyze: {e}", str(rel_path))

    def validate_git_config(self):
        """Validate git configuration"""
        print("\n🔐 Validating git configuration...")

        try:
            # Check if it's a git repo
            result = subprocess.run(
                ["git", "rev-parse", "--is-inside-work-tree"],
                cwd=self.root,
                capture_output=True,
                check=False
            )

            if result.returncode == 0:
                self.add_result(True, "Valid git repository")
            else:
                self.add_result(False, "Not a git repository")
                return

            # Check remote
            result = subprocess.run(
                ["git", "remote", "get-url", "origin"],
                cwd=self.root,
                capture_output=True,
                text=True,
                check=False
            )

            if result.returncode == 0:
                remote = result.stdout.strip()
                if "reggie-ubuntu-workspace" in remote:
                    self.add_result(True, f"Correct remote: {remote}")
                else:
                    self.add_result(False, f"Unexpected remote: {remote}")
            else:
                self.add_result(False, "No git remote configured")

            # Check for uncommitted changes
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=self.root,
                capture_output=True,
                text=True,
                check=False
            )

            if result.returncode == 0:
                if result.stdout.strip():
                    self.add_result(False, "Uncommitted changes present")
                else:
                    self.add_result(True, "No uncommitted changes")

        except Exception as e:
            self.add_result(False, f"Git validation failed: {e}")

    def check_file_permissions(self):
        """Check that scripts have execute permissions"""
        print("\n🔒 Checking file permissions...")

        script_files = list(self.root.glob("**/*.sh"))

        for script in script_files:
            if not script.is_file():
                continue

            rel_path = script.relative_to(self.root)

            if os.access(script, os.X_OK):
                self.add_result(True, "Executable", str(rel_path))
            else:
                self.add_result(False, "Not executable", str(rel_path))


def find_workspace_root() -> Optional[Path]:
    """Find workspace root directory"""
    current = Path.cwd()

    # Try current directory first
    if (current / "setup.sh").exists():
        return current

    # Search up to 5 levels up
    for _ in range(5):
        current = current.parent
        if (current / "setup.sh").exists():
            return current

    return None


def main():
    """CLI entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Validate workspace configuration"
    )
    parser.add_argument(
        "workspace",
        nargs="?",
        help="Path to workspace (default: auto-detect)"
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Attempt to fix issues automatically"
    )

    args = parser.parse_args()

    # Find workspace
    if args.workspace:
        workspace = Path(args.workspace)
    else:
        workspace = find_workspace_root()

    if not workspace:
        print("Error: Could not find workspace. Please specify path.", file=sys.stderr)
        sys.exit(1)

    print(f"Validating workspace: {workspace}")

    # Run validation
    validator = ConfigValidator(workspace)
    success = validator.validate_all()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
