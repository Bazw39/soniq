package utils

import (
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

func MigrateConfigFolder() {
	if runtime.GOOS == "windows" {
		source := filepath.Join(os.Getenv("USERPROFILE"), ".spicetify")
		if _, err := os.Stat(source); err == nil {
			spinner, _ := Spinner.Start("Migrating config folder")
			destination := GetSoniqFolder()
			err := Copy(source, destination, true, nil)
			if err != nil {
				spinner.Fail("Failed to migrate config folder")
				Fatal(err)
			}
			os.RemoveAll(source)
			spinner.Success("Migrated config folder")
		}
	}
	// Migrate legacy Spicetify config into the new SONIQ location.
	// Non-destructive and idempotent: legacy data is copied, never deleted here.
	MigrateLegacyConfig()
}

// MigrateLegacyConfig copies supported settings from a legacy Spicetify
// installation into the SONIQ config directory. It never deletes the
// legacy data, is safe to run multiple times, and silently skips missing,
// partial, or malformed legacy configuration.
func MigrateLegacyConfig() {
	dest := GetSoniqFolder()
	legacyDirs := []string{legacyConfigDir(), filepath.Join(os.Getenv("USERPROFILE"), ".spicetify")}
	for _, src := range legacyDirs {
		if src == "" || src == dest {
			continue
		}
		if st, err := os.Stat(src); err != nil || !st.IsDir() {
			continue
		}
		// Only migrate when SONIQ has no config yet to avoid overwriting user data.
		if _, err := os.Stat(filepath.Join(dest, "config-xpui.ini")); err == nil {
			return
		}
		entries, err := os.ReadDir(src)
		if err != nil {
			continue
		}
		for _, e := range entries {
			name := e.Name()
			if name != "config-xpui.ini" && name != "Themes" && name != "Extensions" && name != "CustomApps" {
				continue
			}
			srcPath := filepath.Join(src, name)
			if e.IsDir() {
				_ = Copy(srcPath, filepath.Join(dest, name), true, nil)
			} else {
				_ = CopyFile(srcPath, dest)
			}
		}
		return
	}
}

// legacyConfigDir returns the historic Spicetify config location for migration lookups.
func legacyConfigDir() string {
	if v, ok := os.LookupEnv("SPICETIFY_CONFIG"); ok && len(v) > 0 {
		return v
	}
	switch runtime.GOOS {
	case "windows":
		return filepath.Join(os.Getenv("APPDATA"), "spicetify")
	case "linux", "darwin":
		parent := os.Getenv("XDG_CONFIG_HOME")
		if len(parent) == 0 {
			parent = filepath.Join(os.Getenv("HOME"), ".config")
		}
		return filepath.Join(parent, "spicetify")
	}
	return ""
}

func MigrateFolders() {
	backupPath := filepath.Join(GetSoniqFolder(), "Backup")
	extractedPath := filepath.Join(GetSoniqFolder(), "Extracted")

	if _, err := os.Stat(backupPath); err == nil {
		newBackupPath := GetStateFolder("Backup")
		oldAbs, err := filepath.Abs(backupPath)
		if err != nil {
			Fatal(err)
		}
		newAbs, err := filepath.Abs(newBackupPath)
		if err != nil {
			Fatal(err)
		}

		if oldAbs != newAbs {
			spinner, _ := Spinner.Start("Migrating backup folder")
			err := Copy(backupPath, newBackupPath, true, nil)
			if err != nil {
				spinner.Fail("Failed to migrate backup folder")
				Fatal(err)
			}
			os.RemoveAll(backupPath)
			spinner.Success("Migrated backup folder")
		}
	}

	if _, err := os.Stat(extractedPath); err == nil {
		newExtractedPath := GetStateFolder("Extracted")
		oldAbs, err := filepath.Abs(extractedPath)
		if err != nil {
			Fatal(err)
		}
		newAbs, err := filepath.Abs(newExtractedPath)
		if err != nil {
			Fatal(err)
		}
		if oldAbs != newAbs {
			spinner, _ := Spinner.Start("Migrating extracted folder")
			err := Copy(extractedPath, newExtractedPath, true, nil)
			if err != nil {
				spinner.Fail("Failed to migrate extracted folder")
				Fatal(err)
			}
			os.RemoveAll(extractedPath)
			spinner.Success("Migrated extracted folder")
		}
	}
}

func ReplaceEnvVarsInString(input string) string {
	var replacements []string
	for _, v := range os.Environ() {
		pair := strings.SplitN(v, "=", 2)
		replacements = append(replacements, "$"+pair[0], pair[1])
	}
	replacer := strings.NewReplacer(replacements...)
	return replacer.Replace(input)
}

// GetSoniqFolder returns the SONIQ configuration directory, creating it on
// first use. SONIQ_CONFIG overrides the default; SPICETIFY_CONFIG is honored
// as a fallback for migration scenarios.
func GetSoniqFolder() string {
	result, isAvailable := os.LookupEnv("SONIQ_CONFIG")
	if !isAvailable || len(result) == 0 {
		result, isAvailable = os.LookupEnv("SPICETIFY_CONFIG")
	}
	defer func() { CheckExistAndCreate(result) }()

	if isAvailable && len(result) > 0 {
		return result
	}

	if runtime.GOOS == "windows" {
		parent := os.Getenv("APPDATA")

		result = filepath.Join(parent, "soniq")
	} else if runtime.GOOS == "linux" {
		parent, isAvailable := os.LookupEnv("XDG_CONFIG_HOME")

		if !isAvailable || len(parent) == 0 {
			parent = filepath.Join(os.Getenv("HOME"), ".config")
			CheckExistAndCreate(parent)
		}

		result = filepath.Join(parent, "soniq")
	} else if runtime.GOOS == "darwin" {
		parent := filepath.Join(os.Getenv("HOME"), ".config")
		CheckExistAndCreate(parent)

		result = filepath.Join(parent, "soniq")
	}

	return result
}

func GetStateFolder(name string) string {
	result, isAvailable := os.LookupEnv("SONIQ_STATE")
	if !isAvailable || len(result) == 0 {
		result, isAvailable = os.LookupEnv("SPICETIFY_STATE")
	}
	defer func() { CheckExistAndCreate(result) }()

	if isAvailable && len(result) > 0 {
		return result
	}

	if runtime.GOOS == "windows" {
		parent := os.Getenv("APPDATA")

		result = filepath.Join(parent, "soniq")
	} else if runtime.GOOS == "linux" {
		parent, isAvailable := os.LookupEnv("XDG_STATE_HOME")

		if !isAvailable || len(parent) == 0 {
			parent = filepath.Join(os.Getenv("HOME"), ".local", "state")
			CheckExistAndCreate(parent)
		}

		result = filepath.Join(parent, "soniq")
	} else if runtime.GOOS == "darwin" {
		parent := filepath.Join(os.Getenv("HOME"), ".local", "state")
		CheckExistAndCreate(parent)

		result = filepath.Join(parent, "soniq")
	}

	return GetSubFolder(result, name)
}

// GetSubFolder checks if folder `name` is available in specified folder,
// else creates then returns the path.
func GetSubFolder(folder string, name string) string {
	dir := filepath.Join(folder, name)
	CheckExistAndCreate(dir)

	return dir
}

var userAppsFolder = GetSubFolder(GetSoniqFolder(), "CustomApps")
var userExtensionsFolder = GetSubFolder(GetSoniqFolder(), "Extensions")

// GetSpicetifyFolder is a deprecated alias of GetSoniqFolder retained for
// extension/tooling compatibility. New code should use GetSoniqFolder.
func GetSpicetifyFolder() string {
	return GetSoniqFolder()
}

// GetSONIQFolder is a deprecated alias of GetSoniqFolder.
func GetSONIQFolder() string {
	return GetSoniqFolder()
}

func GetCustomAppSubfolderPath(folderPath string) string {
	entries, err := os.ReadDir(folderPath)
	if err != nil {
		return ""
	}

	for _, entry := range entries {
		if entry.IsDir() {
			subfolderPath := filepath.Join(folderPath, entry.Name())
			indexPath := filepath.Join(subfolderPath, "index.js")

			if _, err := os.Stat(indexPath); err == nil {
				return subfolderPath
			}

			if subfolderPath := GetCustomAppSubfolderPath(subfolderPath); subfolderPath != "" {
				return subfolderPath
			}
		}
	}

	return ""
}

func GetCustomAppPath(name string) (string, error) {
	customAppFolderPath := filepath.Join(userAppsFolder, name)

	if _, err := os.Stat(customAppFolderPath); err == nil {
		customAppActualFolderPath := GetCustomAppSubfolderPath(customAppFolderPath)
		if customAppActualFolderPath != "" {
			return customAppActualFolderPath, nil
		}
		return customAppFolderPath, nil
	}

	customAppFolderPath = filepath.Join(GetExecutableDir(), "CustomApps", name)

	if _, err := os.Stat(customAppFolderPath); err == nil {
		customAppActualFolderPath := GetCustomAppSubfolderPath(customAppFolderPath)
		if customAppActualFolderPath != "" {
			return customAppActualFolderPath, nil
		}
		return customAppFolderPath, nil
	}

	return "", errors.New("custom app not found")
}

func GetExtensionPath(name string) (string, error) {
	extFilePath := filepath.Join(userExtensionsFolder, name)

	if _, err := os.Stat(extFilePath); err == nil {
		return extFilePath, nil
	}

	extFilePath = filepath.Join(GetExecutableDir(), "Extensions", name)

	if _, err := os.Stat(extFilePath); err == nil {
		return extFilePath, nil
	}

	return "", errors.New("extension not found")
}
