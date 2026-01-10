#!/usr/bin/env python3
"""
Git Identity Manager - Manage multiple git identities with ease

Provides a Python interface for managing git identities with structured
data, validation, and better error handling than bash.
"""

import json
import os
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Optional, Dict


@dataclass
class GitIdentity:
    """Represents a git identity configuration"""
    email: str
    name: str
    label: str

    def __post_init__(self):
        """Validate identity data"""
        if not self.email or '@' not in self.email:
            raise ValueError(f"Invalid email: {self.email}")
        if not self.name:
            raise ValueError("Name cannot be empty")
        if not self.label:
            raise ValueError("Label cannot be empty")

    def __str__(self) -> str:
        return f"{self.label} ({self.email})"


class GitIdentityManager:
    """Manages git identities"""

    def __init__(self, config_file: Optional[Path] = None):
        """
        Initialize Git Identity Manager

        Args:
            config_file: Path to config file (default: ~/.git-identities.json)
        """
        if config_file is None:
            config_file = Path.home() / ".git-identities.json"

        self.config_file = config_file
        self._identities: List[GitIdentity] = []
        self._load()

    def _load(self):
        """Load identities from config file"""
        if not self.config_file.exists():
            self._identities = []
            return

        try:
            with open(self.config_file, 'r') as f:
                data = json.load(f)

            self._identities = [
                GitIdentity(**identity)
                for identity in data.get('identities', [])
            ]

        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in {self.config_file}: {e}", file=sys.stderr)
            self._identities = []
        except Exception as e:
            print(f"Error loading identities: {e}", file=sys.stderr)
            self._identities = []

    def _save(self):
        """Save identities to config file"""
        try:
            # Ensure directory exists
            self.config_file.parent.mkdir(parents=True, exist_ok=True)

            data = {
                'identities': [asdict(identity) for identity in self._identities]
            }

            with open(self.config_file, 'w') as f:
                json.dump(data, f, indent=2)

        except Exception as e:
            print(f"Error saving identities: {e}", file=sys.stderr)
            raise

    def list_identities(self) -> List[GitIdentity]:
        """
        Get all identities

        Returns:
            List of GitIdentity objects
        """
        return self._identities.copy()

    def add_identity(self, email: str, name: str, label: str) -> GitIdentity:
        """
        Add a new identity

        Args:
            email: Git email address
            name: Git user name
            label: Human-readable label

        Returns:
            Created GitIdentity object

        Raises:
            ValueError: If identity already exists or invalid data
        """
        # Check if email already exists
        if any(i.email == email for i in self._identities):
            raise ValueError(f"Identity with email {email} already exists")

        # Create and validate
        identity = GitIdentity(email=email, name=name, label=label)

        # Add and save
        self._identities.append(identity)
        self._save()

        return identity

    def remove_identity(self, email: str) -> bool:
        """
        Remove an identity by email

        Args:
            email: Email of identity to remove

        Returns:
            True if removed, False if not found
        """
        initial_count = len(self._identities)
        self._identities = [i for i in self._identities if i.email != email]

        if len(self._identities) < initial_count:
            self._save()
            return True

        return False

    def get_identity(self, email: str) -> Optional[GitIdentity]:
        """
        Get identity by email

        Args:
            email: Email to search for

        Returns:
            GitIdentity if found, None otherwise
        """
        for identity in self._identities:
            if identity.email == email:
                return identity
        return None

    def get_current_identity(self) -> Optional[GitIdentity]:
        """
        Get currently configured git identity

        Returns:
            Current GitIdentity if set, None otherwise
        """
        try:
            email = subprocess.run(
                ["git", "config", "--global", "user.email"],
                capture_output=True,
                text=True,
                check=False
            ).stdout.strip()

            name = subprocess.run(
                ["git", "config", "--global", "user.name"],
                capture_output=True,
                text=True,
                check=False
            ).stdout.strip()

            if email and name:
                # Find matching identity or create temporary one
                for identity in self._identities:
                    if identity.email == email:
                        return identity

                # Return temporary identity for current config
                return GitIdentity(email=email, name=name, label="Current")

            return None

        except Exception as e:
            print(f"Error getting current identity: {e}", file=sys.stderr)
            return None

    def set_identity(self, email: str, scope: str = "global") -> bool:
        """
        Set git identity as active

        Args:
            email: Email of identity to activate
            scope: Git config scope - "global" or "local"

        Returns:
            True if successful, False otherwise
        """
        identity = self.get_identity(email)
        if not identity:
            print(f"Error: Identity with email {email} not found", file=sys.stderr)
            return False

        try:
            # Set git config
            subprocess.run(
                ["git", "config", f"--{scope}", "user.email", identity.email],
                check=True,
                capture_output=True
            )

            subprocess.run(
                ["git", "config", f"--{scope}", "user.name", identity.name],
                check=True,
                capture_output=True
            )

            print(f"✓ Activated identity: {identity}")
            return True

        except subprocess.CalledProcessError as e:
            print(f"Error setting git config: {e}", file=sys.stderr)
            return False

    def interactive_select(self) -> Optional[GitIdentity]:
        """
        Interactive identity selection

        Returns:
            Selected GitIdentity or None if cancelled
        """
        identities = self.list_identities()

        if not identities:
            print("No identities configured.")
            return None

        print("\n━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  Select Git Identity")
        print("━━━━━━━━━━━━━━━━━━━━━━━━")

        current = self.get_current_identity()
        if current:
            print(f"\nCurrent: {current}\n")

        for i, identity in enumerate(identities, 1):
            marker = "→" if current and identity.email == current.email else " "
            print(f"{marker} {i}) {identity}")

        print("\na) Add new identity")
        print("q) Cancel")

        while True:
            choice = input("\nChoice: ").strip().lower()

            if choice == 'q':
                return None

            if choice == 'a':
                return self._interactive_add()

            try:
                index = int(choice) - 1
                if 0 <= index < len(identities):
                    return identities[index]
                else:
                    print(f"Invalid choice. Please enter 1-{len(identities)}")
            except ValueError:
                print("Invalid input. Please enter a number, 'a', or 'q'")

    def _interactive_add(self) -> Optional[GitIdentity]:
        """Interactive add identity"""
        print("\n━━━━ Add New Identity ━━━━")

        email = input("Email: ").strip()
        if not email:
            print("Cancelled.")
            return None

        name = input("Name: ").strip()
        if not name:
            print("Cancelled.")
            return None

        label = input("Label: ").strip()
        if not label:
            print("Cancelled.")
            return None

        try:
            identity = self.add_identity(email, name, label)
            print(f"✓ Added identity: {identity}")
            return identity
        except ValueError as e:
            print(f"Error: {e}")
            return None

    def print_status(self):
        """Print all identities and current status"""
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  Git Identities")
        print("━━━━━━━━━━━━━━━━━━━━━━━━")

        current = self.get_current_identity()
        if current:
            print(f"\n✓ Current: {current}")

        identities = self.list_identities()

        if not identities:
            print("\nNo identities configured.")
            print("Add one with: git_identity.py add")
        else:
            print(f"\nConfigured identities ({len(identities)}):")
            for identity in identities:
                marker = "→" if current and identity.email == current.email else " "
                print(f"{marker} {identity}")

        print("\n━━━━━━━━━━━━━━━━━━━━━━━━\n")


def main():
    """CLI entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Manage git identities"
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # List command
    subparsers.add_parser("list", help="List all identities")

    # Status command
    subparsers.add_parser("status", help="Show current status")

    # Add command
    add_parser = subparsers.add_parser("add", help="Add new identity")
    add_parser.add_argument("email", help="Git email")
    add_parser.add_argument("name", help="Git name")
    add_parser.add_argument("label", help="Identity label")

    # Remove command
    remove_parser = subparsers.add_parser("remove", help="Remove identity")
    remove_parser.add_argument("email", help="Email of identity to remove")

    # Set command
    set_parser = subparsers.add_parser("set", help="Set active identity")
    set_parser.add_argument("email", help="Email of identity to activate")
    set_parser.add_argument("--scope", default="global", choices=["global", "local"])

    # Select command (interactive)
    subparsers.add_parser("select", help="Interactive identity selection")

    args = parser.parse_args()

    manager = GitIdentityManager()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    if args.command == "list":
        for identity in manager.list_identities():
            print(identity)

    elif args.command == "status":
        manager.print_status()

    elif args.command == "add":
        try:
            identity = manager.add_identity(args.email, args.name, args.label)
            print(f"✓ Added: {identity}")
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

    elif args.command == "remove":
        if manager.remove_identity(args.email):
            print(f"✓ Removed identity: {args.email}")
        else:
            print(f"Identity not found: {args.email}", file=sys.stderr)
            sys.exit(1)

    elif args.command == "set":
        if not manager.set_identity(args.email, args.scope):
            sys.exit(1)

    elif args.command == "select":
        identity = manager.interactive_select()
        if identity:
            if manager.set_identity(identity.email):
                print(f"\n✓ Activated: {identity}")
            else:
                sys.exit(1)


if __name__ == "__main__":
    main()
