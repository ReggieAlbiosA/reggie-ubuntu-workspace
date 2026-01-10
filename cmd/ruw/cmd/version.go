package cmd

import (
	"fmt"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

// versionCmd represents the version command
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version information",
	Long:  `Display the version, build time, and git commit of ruw.`,
	Run:   runVersion,
}

func init() {
	rootCmd.AddCommand(versionCmd)
}

func runVersion(cmd *cobra.Command, args []string) {
	cyan := color.New(color.FgCyan, color.Bold)
	white := color.New(color.FgWhite)

	cyan.Println("ruw - Reggie Ubuntu Workspace CLI")
	fmt.Println()
	white.Printf("Version:    %s\n", Version)
	white.Printf("Git Commit: %s\n", GitCommit)
	white.Printf("Build Time: %s\n", BuildTime)
}
