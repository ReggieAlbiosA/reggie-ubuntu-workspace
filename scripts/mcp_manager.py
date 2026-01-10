#!/usr/bin/env python3
"""
MCP Manager - Manage Claude Code MCP servers with proper data structures

This provides a Python interface to manage MCP servers, with better
error handling and data validation than raw bash string parsing.
"""

import json
import subprocess
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import List, Optional, Dict, Any


class MCPStatus(Enum):
    """MCP server status"""
    CONNECTED = "connected"
    FAILED = "failed"
    MISSING = "missing"
    UNKNOWN = "unknown"


@dataclass
class MCPServer:
    """Represents an MCP server configuration"""
    name: str
    status: MCPStatus
    transport: Optional[str] = None
    url: Optional[str] = None
    command: Optional[str] = None

    def __str__(self) -> str:
        status_emoji = {
            MCPStatus.CONNECTED: "✓",
            MCPStatus.FAILED: "✗",
            MCPStatus.MISSING: "○",
            MCPStatus.UNKNOWN: "?",
        }
        emoji = status_emoji.get(self.status, "?")
        return f"{emoji} {self.name}: {self.status.value}"


class MCPManager:
    """Manages Claude Code MCP servers"""

    EXPECTED_SERVERS = ["better-auth", "sequential-thinking", "github"]

    def __init__(self, scope: str = "user"):
        """
        Initialize MCP Manager

        Args:
            scope: MCP scope - "user" or "system"
        """
        self.scope = scope

    def list_servers(self) -> List[MCPServer]:
        """
        List all MCP servers and their status

        Returns:
            List of MCPServer objects
        """
        try:
            result = subprocess.run(
                ["claude", "mcp", "list"],
                capture_output=True,
                text=True,
                check=False
            )

            if result.returncode != 0:
                print(f"Warning: claude mcp list failed: {result.stderr}", file=sys.stderr)
                return self._get_expected_as_missing()

            servers = self._parse_mcp_list(result.stdout)
            return servers

        except FileNotFoundError:
            print("Error: claude command not found", file=sys.stderr)
            return self._get_expected_as_missing()
        except Exception as e:
            print(f"Error listing MCP servers: {e}", file=sys.stderr)
            return self._get_expected_as_missing()

    def _parse_mcp_list(self, output: str) -> List[MCPServer]:
        """
        Parse output from 'claude mcp list'

        Args:
            output: Raw output from claude mcp list

        Returns:
            List of parsed MCPServer objects
        """
        servers = []

        for line in output.strip().split('\n'):
            if not line.strip() or line.startswith('#'):
                continue

            # Parse format: "name: status [details]"
            if ':' in line:
                parts = line.split(':', 1)
                name = parts[0].strip()
                rest = parts[1].strip() if len(parts) > 1 else ""

                # Determine status
                if "Connected" in rest or "connected" in rest:
                    status = MCPStatus.CONNECTED
                elif "Failed" in rest or "failed" in rest:
                    status = MCPStatus.FAILED
                else:
                    status = MCPStatus.UNKNOWN

                servers.append(MCPServer(name=name, status=status))

        return servers

    def _get_expected_as_missing(self) -> List[MCPServer]:
        """Get expected servers marked as missing"""
        return [
            MCPServer(name=name, status=MCPStatus.MISSING)
            for name in self.EXPECTED_SERVERS
        ]

    def get_server_status(self, name: str) -> MCPStatus:
        """
        Get status of a specific server

        Args:
            name: Server name

        Returns:
            MCPStatus enum value
        """
        servers = self.list_servers()
        for server in servers:
            if server.name == name:
                return server.status
        return MCPStatus.MISSING

    def get_missing_servers(self) -> List[str]:
        """
        Get list of missing expected servers

        Returns:
            List of server names that are missing or failed
        """
        servers = self.list_servers()
        server_dict = {s.name: s for s in servers}

        missing = []
        for expected in self.EXPECTED_SERVERS:
            if expected not in server_dict:
                missing.append(expected)
            elif server_dict[expected].status != MCPStatus.CONNECTED:
                missing.append(expected)

        return missing

    def add_server(self, name: str, config: Dict[str, Any]) -> bool:
        """
        Add an MCP server

        Args:
            name: Server name
            config: Server configuration dict with keys:
                   - transport: "http" or None
                   - url: URL for http transport
                   - command: Command to run for stdio transport

        Returns:
            True if successful, False otherwise
        """
        try:
            # Remove existing if present
            self.remove_server(name)

            cmd = ["claude", "mcp", "add", name, "--scope", self.scope]

            if config.get("transport") == "http":
                cmd.extend(["--transport", "http", config["url"]])
            else:
                cmd.append("--")
                cmd.extend(config["command"].split())

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=False
            )

            if result.returncode == 0:
                print(f"✓ Added MCP server: {name}")
                return True
            else:
                print(f"✗ Failed to add {name}: {result.stderr}", file=sys.stderr)
                return False

        except Exception as e:
            print(f"Error adding server {name}: {e}", file=sys.stderr)
            return False

    def remove_server(self, name: str) -> bool:
        """
        Remove an MCP server

        Args:
            name: Server name

        Returns:
            True if successful or not exists, False on error
        """
        try:
            result = subprocess.run(
                ["claude", "mcp", "remove", name, "--scope", self.scope],
                capture_output=True,
                text=True,
                check=False
            )
            # Success even if server didn't exist
            return True
        except Exception as e:
            print(f"Error removing server {name}: {e}", file=sys.stderr)
            return False

    def install_standard_servers(self, github_token: Optional[str] = None) -> Dict[str, bool]:
        """
        Install all standard MCP servers

        Args:
            github_token: GitHub personal access token for github MCP

        Returns:
            Dict mapping server names to success status
        """
        results = {}

        # Better Auth
        results["better-auth"] = self.add_server(
            "better-auth",
            {
                "transport": "http",
                "url": "https://mcp.chonkie.ai/better-auth/better-auth-builder/mcp"
            }
        )

        # Sequential Thinking
        results["sequential-thinking"] = self.add_server(
            "sequential-thinking",
            {
                "command": "npx @modelcontextprotocol/server-sequential-thinking"
            }
        )

        # GitHub (requires token)
        if github_token:
            results["github"] = self.add_server(
                "github",
                {
                    "command": "npx @modelcontextprotocol/server-github"
                }
            )
        else:
            print("⚠ Skipping GitHub MCP (no token provided)", file=sys.stderr)
            results["github"] = False

        return results

    def print_status(self):
        """Print status of all MCP servers"""
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  MCP Server Status")
        print("━━━━━━━━━━━━━━━━━━━━━━━━")

        servers = self.list_servers()

        if not servers:
            print("No MCP servers found")
            return

        for server in servers:
            print(f"  {server}")

        missing = self.get_missing_servers()
        if missing:
            print(f"\n⚠  Missing servers: {', '.join(missing)}")

        print("━━━━━━━━━━━━━━━━━━━━━━━━\n")


def main():
    """CLI entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Manage Claude Code MCP servers"
    )
    parser.add_argument(
        "command",
        choices=["list", "status", "add", "remove", "install"],
        help="Command to run"
    )
    parser.add_argument(
        "--name",
        help="Server name (for add/remove)"
    )
    parser.add_argument(
        "--scope",
        default="user",
        choices=["user", "system"],
        help="MCP scope"
    )
    parser.add_argument(
        "--github-token",
        help="GitHub token (for install)"
    )

    args = parser.parse_args()

    manager = MCPManager(scope=args.scope)

    if args.command == "list":
        servers = manager.list_servers()
        for server in servers:
            print(server)

    elif args.command == "status":
        manager.print_status()

    elif args.command == "add":
        if not args.name:
            print("Error: --name required for add command", file=sys.stderr)
            sys.exit(1)
        # Simple add - would need more args for full config
        print(f"Adding {args.name}...")

    elif args.command == "remove":
        if not args.name:
            print("Error: --name required for remove command", file=sys.stderr)
            sys.exit(1)
        manager.remove_server(args.name)

    elif args.command == "install":
        results = manager.install_standard_servers(
            github_token=args.github_token
        )

        print("\nInstallation Results:")
        for name, success in results.items():
            status = "✓" if success else "✗"
            print(f"  {status} {name}")


if __name__ == "__main__":
    main()
