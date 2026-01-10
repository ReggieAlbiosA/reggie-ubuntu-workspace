package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/ReggieAlbiosA/reggie-ubuntu-workspace/ruw/workspace"
	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

var (
	autoYes      bool
	skipOptional bool
)

// updateCmd represents the update command
var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update workspace configuration",
	Long: `Update your workspace by running setup.sh from the workspace directory.

This command will:
  1. Locate your workspace
  2. Run setup.sh with the specified flags
  3. Apply configuration updates`,
	Example: `  ruw update              # Interactive update
  ruw update -y           # Auto-accept all prompts
  ruw update --skip-optional  # Update core only`,
	RunE: runUpdate,
}

func init() {
	rootCmd.AddCommand(updateCmd)

	updateCmd.Flags().BoolVarP(&autoYes, "yes", "y", false, "auto-accept all prompts")
	updateCmd.Flags().BoolVar(&skipOptional, "skip-optional", false, "skip optional modules")
}

func runUpdate(cmd *cobra.Command, args []string) error {
	cyan := color.New(color.FgCyan)
	green := color.New(color.FgGreen)

	// Find workspace
	cyan.Println("🔍 Finding workspace...")
	ws, err := workspace.FindWorkspace()
	if err != nil {
		return fmt.Errorf("workspace not found: %w", err)
	}

	green.Printf("✓ Found workspace: %s\n", ws.Path)

	// Build setup.sh arguments
	setupArgs := []string{"setup.sh"}
	if autoYes {
		setupArgs = append(setupArgs, "-y")
	}
	if skipOptional {
		setupArgs = append(setupArgs, "--skip-optional")
	}

	// Show what we're running
	cyan.Printf("\n🚀 Running: bash %s\n\n", strings.Join(setupArgs, " "))

	// Run setup.sh
	setupCmd := exec.Command("bash", setupArgs...)
	setupCmd.Dir = ws.Path
	setupCmd.Stdout = os.Stdout
	setupCmd.Stderr = os.Stderr
	setupCmd.Stdin = os.Stdin

	if err := setupCmd.Run(); err != nil {
		return fmt.Errorf("setup.sh failed: %w", err)
	}

	green.Println("\n✓ Workspace updated successfully!")
	return nil
}
