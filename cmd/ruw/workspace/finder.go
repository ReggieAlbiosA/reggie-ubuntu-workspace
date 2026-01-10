package workspace

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	expectedRemote = "github.com/ReggieAlbiosA/reggie-ubuntu-workspace"
)

// Workspace represents a valid workspace directory
type Workspace struct {
	Path   string
	Remote string
}

// Config paths
var (
	ConfigDir      = filepath.Join(os.Getenv("HOME"), ".config", "ruw")
	CachedPathFile = filepath.Join(ConfigDir, "workspace-path")
)

// FindWorkspace locates the workspace directory
func FindWorkspace() (*Workspace, error) {
	// Try cached location first
	if ws, err := findCached(); err == nil {
		return ws, nil
	}

	// Search common locations
	for _, path := range searchPaths() {
		if ws, err := validateWorkspace(path); err == nil {
			// Cache successful find
			if err := cacheWorkspace(ws); err != nil {
				// Non-fatal, just log
				fmt.Fprintf(os.Stderr, "Warning: failed to cache workspace path: %v\n", err)
			}
			return ws, nil
		}
	}

	return nil, fmt.Errorf("workspace not found in any common location.\nSearched:\n%s\n\nPlease ensure the workspace is cloned to one of these locations.",
		strings.Join(searchPaths(), "\n"))
}

// findCached attempts to load workspace from cached path
func findCached() (*Workspace, error) {
	data, err := os.ReadFile(CachedPathFile)
	if err != nil {
		return nil, fmt.Errorf("no cached path: %w", err)
	}

	path := strings.TrimSpace(string(data))
	return validateWorkspace(path)
}

// validateWorkspace checks if a path is a valid workspace
func validateWorkspace(path string) (*Workspace, error) {
	// Check if directory exists
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return nil, fmt.Errorf("directory does not exist: %s", path)
	}

	// Check for setup.sh
	setupPath := filepath.Join(path, "setup.sh")
	if _, err := os.Stat(setupPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("setup.sh not found at %s", path)
	}

	// Check git remote
	remote, err := getGitRemote(path)
	if err != nil {
		return nil, fmt.Errorf("failed to get git remote: %w", err)
	}

	if !strings.Contains(remote, expectedRemote) {
		return nil, fmt.Errorf("incorrect remote: expected %s, got %s", expectedRemote, remote)
	}

	return &Workspace{
		Path:   path,
		Remote: remote,
	}, nil
}

// getGitRemote retrieves the git remote URL for a path
func getGitRemote(path string) (string, error) {
	cmd := exec.Command("git", "remote", "get-url", "origin")
	cmd.Dir = path
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("git command failed: %w", err)
	}

	return strings.TrimSpace(string(output)), nil
}

// searchPaths returns common workspace locations to search
func searchPaths() []string {
	home := os.Getenv("HOME")
	return []string{
		filepath.Join(home, "Documents", "reggie-ubuntu-workspace"),
		filepath.Join(home, "reggie-ubuntu-workspace"),
		filepath.Join(home, "workspace", "reggie-ubuntu-workspace"),
		filepath.Join(home, "dev", "reggie-ubuntu-workspace"),
		filepath.Join(home, "projects", "reggie-ubuntu-workspace"),
	}
}

// cacheWorkspace saves the workspace path to cache
func cacheWorkspace(ws *Workspace) error {
	if err := os.MkdirAll(ConfigDir, 0755); err != nil {
		return fmt.Errorf("failed to create config dir: %w", err)
	}

	if err := os.WriteFile(CachedPathFile, []byte(ws.Path), 0644); err != nil {
		return fmt.Errorf("failed to write cache file: %w", err)
	}

	return nil
}

// ClearCache removes the cached workspace path
func ClearCache() error {
	if err := os.Remove(CachedPathFile); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to clear cache: %w", err)
	}
	return nil
}
