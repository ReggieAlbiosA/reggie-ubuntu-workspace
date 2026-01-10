package cmd

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/ReggieAlbiosA/reggie-ubuntu-workspace/ruw/workspace"
	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

// statusCmd shows workspace status
var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show workspace status",
	Long:  `Display information about your workspace including location, git status, and configuration.`,
	RunE:  runStatus,
}

func init() {
	rootCmd.AddCommand(statusCmd)
}

func runStatus(cmd *cobra.Command, args []string) error {
	cyan := color.New(color.FgCyan, color.Bold)
	green := color.New(color.FgGreen)
	yellow := color.New(color.FgYellow)
	white := color.New(color.FgWhite, color.Bold)

	cyan.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	cyan.Println("  Workspace Status")
	cyan.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	// Find workspace
	ws, err := workspace.FindWorkspace()
	if err != nil {
		return fmt.Errorf("workspace not found: %w", err)
	}

	// Workspace location
	white.Print("\n📁 Location: ")
	fmt.Println(ws.Path)

	// Git remote
	white.Print("🔗 Remote: ")
	fmt.Println(ws.Remote)

	// Git branch
	branch, err := getGitBranch(ws.Path)
	if err == nil {
		white.Print("🌿 Branch: ")
		green.Println(branch)
	}

	// Git status
	if hasChanges, err := hasGitChanges(ws.Path); err == nil {
		white.Print("📝 Changes: ")
		if hasChanges {
			yellow.Println("Yes (uncommitted changes)")
		} else {
			green.Println("Clean")
		}
	}

	// Check if behind remote
	if behind, ahead, err := getGitBehindAhead(ws.Path); err == nil {
		if behind > 0 || ahead > 0 {
			white.Print("🔄 Sync: ")
			if ahead > 0 {
				yellow.Printf("%d commit(s) ahead ", ahead)
			}
			if behind > 0 {
				yellow.Printf("%d commit(s) behind", behind)
			}
			fmt.Println()
		} else {
			white.Print("🔄 Sync: ")
			green.Println("Up to date")
		}
	}

	// Check key components
	white.Println("\n📦 Components:")
	checkComponent(ws.Path, "setup.sh", "Main setup script")
	checkComponent(ws.Path, "def/packages.sh", "Package installer")
	checkComponent(ws.Path, "def/apps.sh", "App installer")
	checkComponent(ws.Path, "opt/aliases.sh", "Bash aliases")

	cyan.Println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	return nil
}

func getGitBranch(path string) (string, error) {
	cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
	cmd.Dir = path
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func hasGitChanges(path string) (bool, error) {
	cmd := exec.Command("git", "status", "--porcelain")
	cmd.Dir = path
	output, err := cmd.Output()
	if err != nil {
		return false, err
	}
	return len(output) > 0, nil
}

func getGitBehindAhead(path string) (behind, ahead int, err error) {
	cmd := exec.Command("git", "rev-list", "--left-right", "--count", "HEAD...@{upstream}")
	cmd.Dir = path
	output, err := cmd.Output()
	if err != nil {
		return 0, 0, err
	}

	parts := strings.Fields(string(output))
	if len(parts) == 2 {
		fmt.Sscanf(parts[0], "%d", &ahead)
		fmt.Sscanf(parts[1], "%d", &behind)
	}
	return
}

func checkComponent(basePath, relativePath, description string) {
	green := color.New(color.FgGreen)
	red := color.New(color.FgRed)

	fullPath := basePath + "/" + relativePath
	if fileExists(fullPath) {
		green.Printf("  ✓ %s\n", description)
	} else {
		red.Printf("  ✗ %s (missing)\n", description)
	}
}

func fileExists(path string) bool {
	cmd := exec.Command("test", "-f", path)
	return cmd.Run() == nil
}
