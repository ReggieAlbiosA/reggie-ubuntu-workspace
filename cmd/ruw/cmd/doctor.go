package cmd

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/ReggieAlbiosA/reggie-ubuntu-workspace/ruw/workspace"
	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

// doctorCmd checks system health
var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Check system health",
	Long: `Run health checks on your system to ensure all dependencies
and configurations are properly set up.

This checks:
  - Workspace location and validity
  - Required system commands
  - Git configuration
  - Shell configuration`,
	RunE: runDoctor,
}

func init() {
	rootCmd.AddCommand(doctorCmd)
}

func runDoctor(cmd *cobra.Command, args []string) error {
	cyan := color.New(color.FgCyan, color.Bold)
	green := color.New(color.FgGreen)
	red := color.New(color.FgRed)
	yellow := color.New(color.FgYellow)
	white := color.New(color.FgWhite, color.Bold)

	cyan.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	cyan.Println("  System Health Check")
	cyan.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	issues := 0

	// Check workspace
	white.Println("\n📁 Workspace")
	ws, err := workspace.FindWorkspace()
	if err != nil {
		red.Println("  ✗ Workspace not found")
		fmt.Printf("    %v\n", err)
		issues++
	} else {
		green.Println("  ✓ Workspace found")
		fmt.Printf("    Location: %s\n", ws.Path)
	}

	// Check required commands
	white.Println("\n🔧 Required Commands")
	requiredCommands := []string{"git", "bash", "curl", "sudo"}
	for _, cmdName := range requiredCommands {
		if checkCommand(cmdName) {
			green.Printf("  ✓ %s\n", cmdName)
		} else {
			red.Printf("  ✗ %s (not found)\n", cmdName)
			issues++
		}
	}

	// Check optional commands
	white.Println("\n🎨 Optional Commands")
	optionalCommands := []string{"node", "npm", "claude", "code", "cursor"}
	for _, cmdName := range optionalCommands {
		if checkCommand(cmdName) {
			green.Printf("  ✓ %s\n", cmdName)
		} else {
			yellow.Printf("  ○ %s (not installed)\n", cmdName)
		}
	}

	// Check Git configuration
	white.Println("\n🔐 Git Configuration")
	if name, err := getGitConfig("user.name"); err == nil && name != "" {
		green.Printf("  ✓ Git user.name: %s\n", name)
	} else {
		red.Println("  ✗ Git user.name not set")
		issues++
	}

	if email, err := getGitConfig("user.email"); err == nil && email != "" {
		green.Printf("  ✓ Git user.email: %s\n", email)
	} else {
		red.Println("  ✗ Git user.email not set")
		issues++
	}

	// Summary
	cyan.Println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	if issues == 0 {
		green.Println("✓ All checks passed! System is healthy.")
	} else {
		yellow.Printf("⚠  %d issue(s) found. Please address them for best experience.\n", issues)
	}
	cyan.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	return nil
}

func checkCommand(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func getGitConfig(key string) (string, error) {
	cmd := exec.Command("git", "config", "--global", key)
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}
