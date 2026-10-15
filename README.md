<div align="center">

<img src=".github/assets/soniq-logo.png" alt="SONIQ logo" width="160">

# SONIQ

**SONIQ — The Ultimate Spotify Customization Framework**

*Made by NOX / VANTA / blasphemyw*

[![Latest version](https://img.shields.io/github/release/Bazw39/soniq/all.svg?colorB=97CA00&label=latest%20version)](https://github.com/Bazw39/soniq/releases/latest)

</div>

---

SONIQ is a command-line tool that customizes the official Spotify desktop client.
It supports Windows, macOS and Linux.

With SONIQ you can restyle the Spotify interface, extend it with JavaScript
extensions and custom apps, manage themes, and back up or restore the client
before and after applying changes.

> SONIQ is an independent third-party customization tool. It is not affiliated
> with, endorsed by, or sponsored by Spotify.

## Features

- Recolor the Spotify user interface with theme color schemes
- Inject custom CSS for advanced styling
- Inject JavaScript extensions to extend functionality, manipulate the UI and
  control the player
- Inject custom apps that live inside the Spotify client
- Manage themes, extensions and custom apps from one CLI
- Back up original Spotify files and restore them at any time
- Watch mode that reloads changes while you develop themes, extensions or apps
- Block the Spotify client from self-updating (optional)
- Enable Spotify's developer tools for inspection and debugging

## Installation

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/Bazw39/soniq/main/install.ps1 | iex
```

The installer downloads the latest `soniq-<version>-windows-<arch>.zip`
release asset, extracts `soniq.exe` to `%LOCALAPPDATA%\soniq` and adds that
directory to your user `PATH`.

To install a specific version:

```powershell
$v="2.42.0"; iwr -useb https://raw.githubusercontent.com/Bazw39/soniq/main/install.ps1 | iex
```

### macOS / Linux (shell)

```sh
curl -fsSL https://raw.githubusercontent.com/Bazw39/soniq/main/install.sh | sh
```

The installer downloads the latest `soniq-<version>-<os>-<arch>.tar.gz`
release asset, extracts the `soniq` binary to `~/.soniq` and adds that
directory to your `PATH` through your shell profile.

To install a specific version:

```sh
curl -fsSL https://raw.githubusercontent.com/Bazw39/soniq/main/install.sh | sh -s -- 2.42.0
```

To point the installers at a custom release location (forks, mirrors, offline
testing), set `SONIQ_REPO_URL` (PowerShell) or `SONIQ_RELEASES_URL` (shell)
before running them.

## Quick start

```sh
# Print help and the version
soniq --help
soniq --version

# Back up Spotify's original files (required before first apply)
soniq backup

# Apply your current configuration (theme, extensions, custom apps)
soniq apply

# Chain commands; Spotify restarts automatically unless -n is given
soniq backup apply

# Restore Spotify to its original state
soniq restore

# Update SONIQ itself
soniq update
```

Configuration is created automatically on first run. Useful lookups:

```sh
soniq config          # show all config fields
soniq path userdata   # show the SONIQ data directory
soniq config-dir      # open the SONIQ config directory
```

## Configuration

SONIQ stores its settings in `config-xpui.ini` inside its data directory:

| OS      | SONIQ data directory            |
|---------|---------------------------------|
| Windows | `%APPDATA%\soniq`               |
| Linux   | `$XDG_CONFIG_HOME/soniq` (`~/.config/soniq` by default) |
| macOS   | `~/.config/soniq`               |

State such as backups and extracted files lives under the state directory
(`%APPDATA%\soniq` on Windows, `$XDG_STATE_HOME/soniq` on Linux,
`~/.local/state/soniq` on macOS), and can be overridden with the
`SONIQ_CONFIG` and `SONIQ_STATE` environment variables.

Key settings (see `soniq -h config` for the full list):

| Setting                | Meaning                                                        |
|------------------------|----------------------------------------------------------------|
| `spotify_path`         | Path to the Spotify client directory                           |
| `prefs_path`           | Path to Spotify's `prefs` file                                 |
| `current_theme`        | Active theme folder name                                       |
| `color_scheme`         | Color section in the theme's `color.ini`                       |
| `inject_css`           | Apply the theme's `user.css` (`0`/`1`)                         |
| `inject_theme_js`      | Apply the theme's `theme.js` (`0`/`1`)                         |
| `replace_colors`       | Apply the theme's color scheme (`0`/`1`)                        |
| `spotify_launch_flags` | Extra flags used when SONIQ launches Spotify, separated by `|` |
| `check_soniq_update`   | Check for SONIQ updates on launch (`0`/`1`)                    |
| `extensions`           | Enabled extensions, separated by `|`                           |
| `custom_apps`          | Enabled custom apps, separated by `|`                          |

Edit settings with `soniq config <field> <value>`, e.g.
`soniq config inject_css 1`, or `soniq color <field> <value>` for theme
colors, e.g. `soniq color main ff0000`.

### Migrating from the upstream tool

If you previously used the Spicetify CLI, SONIQ detects its configuration on
first run and copies the supported settings, themes, extensions and custom
apps into the SONIQ directories. Migration is non-destructive (the original
data is left untouched), idempotent (safe to run more than once), and skipped
automatically once SONIQ already has a configuration. The legacy
`SPICETIFY_CONFIG`/`SPICETIFY_STATE` variables and the `check_spicetify_update`
config key are honored as fallbacks during migration.

## Themes and extensions

- Ship-ready defaults live in `Themes/` (e.g. `SONIQDefault`), `Extensions/`
  and `CustomApps/` next to the executable, or per-user under the SONIQ data
  directory.
- Enable them via config: `soniq config current_theme SONIQDefault`,
  `soniq config extensions myExt.js`, `soniq config custom_apps my-app`,
  then run `soniq apply`.
- Refresh only what changed: `soniq refresh`, `soniq refresh -e`
  (extensions), `soniq refresh -a` (custom apps).
- Develop live: `soniq watch -l` reloads Spotify when themes, extensions or
  custom apps change; combine `-e`, `-a`, `-s` to watch a subset.
- For extension authors: the in-client `Spicetify` JavaScript API namespace,
  `SpicetifyWrapper` helper, `--spice-*` CSS variables and the documented
  manifest fields are intentionally preserved for compatibility. See
  `CONTRIBUTING.md` for build details.

### SONIQ Store

SONIQ ships a built-in store so you can browse without leaving Spotify:

- Enable it once: `soniq config custom_apps soniq-store extensions soniqStore.js`
  followed by `soniq apply` (Spotify restarts).
- Click the **★ star button** in the top bar, or open the **SONIQ Store**
  entry in the sidebar.
- The **Extensions** tab lists every bundled extension; the **Themes** tab
  lists `SONIQDefault` with clickable color-scheme swatches plus popular
  community themes.
- Each card has a button that copies the exact terminal command
  (e.g. `soniq config extensions bookmark.js`). Paste it in a terminal, run
  it, then run `soniq apply` and restart Spotify when asked.

Community themes live in the
[spicetify/themes](https://github.com/spicetify/themes) collection:
download a theme folder into your SONIQ `Themes` directory, then enable it
with `soniq config current_theme <FolderName>` + `soniq apply`.

## Troubleshooting

- **"spotify_path is not a valid path"** — set it manually:
  `soniq config spotify_path "<path-to-spotify-directory>"`.
- **"Cannot detect Spotify location"** — install the official Spotify desktop
  client (not the Microsoft Store version on Windows) and launch it once.
- **Black/blank window after applying** — do not run `soniq` as administrator
  or root; files written with elevated privileges are unreadable by Spotify
  running as a normal user. Use `--bypass-admin` only if you accept the risk.
- **Spotify updated itself and customization vanished** — run `soniq update`;
  SONIQ re-applies backup and customization automatically when needed.
- **Blocked updates** — `soniq spotify-updates block` / `soniq spotify-updates unblock`
  controls Spotify's self-updater patch.
- **Permissions** — if downloads or writes fail with "Permission denied",
  check ownership of the SONIQ data directory or reinstall with the same
  package manager/user that performed the original install.
- **Unsupported client versions** — new Spotify releases can break themes or
  extensions; run `soniq restore`, update Spotify, then `soniq backup apply`.

## Development

Requirements: [Go](https://go.dev/dl/) (see `go.mod`), plus
[Node.js](https://nodejs.org/) and [pnpm](https://pnpm.io/) for the bundled
wrapper helper.

```sh
git clone https://github.com/Bazw39/soniq.git
cd cli
pnpm install
pnpm build:wrapper   # regenerates jsHelper/soniqWrapper.js

# Build
go build -o soniq.exe   # Windows
go build -o soniq       # Linux / macOS

./soniq --help
```

Useful checks: `gofmt -s -l .`, `pnpm lint`, `pnpm check:wrapper`. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the full contribution workflow.

## Project credit

**SONIQ — Made by NOX / VANTA / blasphemyw**

Built on the open-source Spicetify CLI codebase; see [LICENSE](LICENSE) for
license and attribution notices.

### Code Signing Policy

Free code signing provided by [SignPath.io](https://signpath.io), certificate by [SignPath Foundation](https://signpath.org/).
