package cmd

import (
	"github.com/spf13/cobra"
)

var (
	Version   string
	GitCommit string
	BuildTime string
)

// rootCmd represents the base command
var rootCmd = &cobra.Command{
	Use:   "ruw",
	Short: "Reggie Ubuntu Workspace CLI - Manage your workspace from anywhere",
	Long: `ruw is a CLI tool for managing the Reggie Ubuntu Workspace.

It provides commands to update your workspace configuration, check status,
and manage your development environment from anywhere on your system.`,
	SilenceErrors: true,
	SilenceUsage:  true,
}

// Execute runs the root command
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	// Global flags
	rootCmd.PersistentFlags().BoolP("verbose", "v", false, "verbose output")
}
