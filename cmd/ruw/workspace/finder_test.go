package workspace

import (
	"os"
	"path/filepath"
	"testing"
)

func TestSearchPaths(t *testing.T) {
	paths := searchPaths()

	if len(paths) == 0 {
		t.Error("searchPaths returned empty slice")
	}

	// All paths should contain workspace name
	for _, path := range paths {
		if !filepath.IsAbs(path) {
			t.Errorf("path is not absolute: %s", path)
		}
	}
}

func TestValidateWorkspace(t *testing.T) {
	// Test with current workspace (should be valid if running from it)
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}

	// Navigate up to find workspace root
	workspaceRoot := cwd
	for {
		setupPath := filepath.Join(workspaceRoot, "setup.sh")
		if _, err := os.Stat(setupPath); err == nil {
			break
		}
		parent := filepath.Dir(workspaceRoot)
		if parent == workspaceRoot {
			t.Skip("Not running from workspace, skipping test")
			return
		}
		workspaceRoot = parent
	}

	ws, err := validateWorkspace(workspaceRoot)
	if err != nil {
		t.Errorf("validateWorkspace failed for current workspace: %v", err)
	}

	if ws == nil {
		t.Error("validateWorkspace returned nil workspace")
	}

	if ws != nil && ws.Path != workspaceRoot {
		t.Errorf("workspace path mismatch: got %s, want %s", ws.Path, workspaceRoot)
	}
}

func TestValidateWorkspace_Invalid(t *testing.T) {
	tests := []struct {
		name string
		path string
	}{
		{"nonexistent directory", "/nonexistent/path"},
		{"temp directory", os.TempDir()},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := validateWorkspace(tt.path)
			if err == nil {
				t.Errorf("validateWorkspace should have failed for %s", tt.path)
			}
		})
	}
}

func TestCacheWorkspace(t *testing.T) {
	// Use temp directory for testing
	tempConfigDir := filepath.Join(os.TempDir(), "ruw-test")
	originalConfigDir := ConfigDir
	originalCachedPathFile := CachedPathFile

	ConfigDir = tempConfigDir
	CachedPathFile = filepath.Join(tempConfigDir, "workspace-path")

	defer func() {
		ConfigDir = originalConfigDir
		CachedPathFile = originalCachedPathFile
		os.RemoveAll(tempConfigDir)
	}()

	testWs := &Workspace{
		Path:   "/test/path",
		Remote: "https://github.com/test/repo.git",
	}

	if err := cacheWorkspace(testWs); err != nil {
		t.Fatalf("cacheWorkspace failed: %v", err)
	}

	// Verify cache file was created
	data, err := os.ReadFile(CachedPathFile)
	if err != nil {
		t.Fatalf("failed to read cache file: %v", err)
	}

	if string(data) != testWs.Path {
		t.Errorf("cached path mismatch: got %s, want %s", string(data), testWs.Path)
	}
}

func TestClearCache(t *testing.T) {
	// Use temp directory for testing
	tempConfigDir := filepath.Join(os.TempDir(), "ruw-test-clear")
	originalConfigDir := ConfigDir
	originalCachedPathFile := CachedPathFile

	ConfigDir = tempConfigDir
	CachedPathFile = filepath.Join(tempConfigDir, "workspace-path")

	defer func() {
		ConfigDir = originalConfigDir
		CachedPathFile = originalCachedPathFile
		os.RemoveAll(tempConfigDir)
	}()

	// Create a cache file
	testWs := &Workspace{Path: "/test/path"}
	if err := cacheWorkspace(testWs); err != nil {
		t.Fatalf("cacheWorkspace failed: %v", err)
	}

	// Clear cache
	if err := ClearCache(); err != nil {
		t.Fatalf("ClearCache failed: %v", err)
	}

	// Verify file was removed
	if _, err := os.Stat(CachedPathFile); !os.IsNotExist(err) {
		t.Error("cache file still exists after clear")
	}

	// Clearing non-existent cache should not error
	if err := ClearCache(); err != nil {
		t.Errorf("ClearCache failed on non-existent file: %v", err)
	}
}
