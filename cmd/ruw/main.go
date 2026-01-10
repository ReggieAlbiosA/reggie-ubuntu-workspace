package main

import (
	"fmt"
	"os"

	"github.com/ReggieAlbiosA/reggie-ubuntu-workspace/ruw/cmd"
)

// Version information (set during build)
var (
	Version   = "1.0.0"
	GitCommit = "dev"
	BuildTime = "unknown"
)

func main() {
	// Set version info for commands
	cmd.Version = Version
	cmd.GitCommit = GitCommit
	cmd.BuildTime = BuildTime

	if err := cmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
