#!/usr/bin/env sh
# Copyright 2022 khanhas.
# Copyright 2023-present Spicetify contributors.
# Copyright 2026 SONIQ contributors.
# Edited from project Denoland install script (https://github.com/denoland/deno_install)

set -e

for arg in "$@"; do
    shift
    case "$arg" in
        "--root") override_root=1 ;;
        *)
        if echo "$arg" | grep -qv "^-"; then
            tag="$arg"
        else
            echo "Invalid option $arg" >&2
            exit 1
        fi
    esac
done

is_root() {
    [ "$(id -u)" -ne 0 ]
}

if ! is_root && [ "${override_root:-0}" -eq 0 ]; then
    echo "The script was ran under sudo or as root. The script will now exit"
    echo "If you hadn't intended to do this, please execute the script without root access to avoid problems with soniq"
    echo "To override this behavior, pass the '--root' parameter to this script"
    exit
fi

soniq_install="$HOME/.soniq"
legacy_install="$HOME/.spicetify"
# Non-destructive migration of a legacy binary install location.
if [ ! -d "$soniq_install" ] && [ -d "$legacy_install" ]; then
    mkdir -p "$soniq_install"
    cp -R "$legacy_install/." "$soniq_install/" 2>/dev/null || true
fi
exe="$soniq_install/soniq"
installed_exe=
if [ -x "$exe" ]; then
    installed_exe="$exe"
elif command -v soniq >/dev/null 2>&1; then
    installed_exe=$(command -v soniq)
fi

if [ -n "$installed_exe" ]; then
    echo "SONIQ is already installed. Do you want to fix your installation? (Y/n)"
    read -r choice < /dev/tty
    if [ "$choice" != "N" ] && [ "$choice" != "n" ]; then
        "$installed_exe" update
        exit 0
    fi
fi

# wipe existing log
> install.log :

log() {
    echo "$1"
    echo "[$(date +'%H:%M:%S %Y-%m-%d')]" "$1" >> install.log
}

case $(uname -sm) in
    "Darwin x86_64") target="darwin-amd64" ;;
    "Darwin arm64") target="darwin-arm64" ;;
    "Linux x86_64") target="linux-amd64" ;;
    "Linux aarch64") target="linux-arm64" ;;
    *) log "Unsupported platform $(uname -sm). x86_64 and arm64 binaries for Linux and Darwin are available."; exit ;;
esac

# check for dependencies
command -v curl >/dev/null || { log "curl isn't installed!" >&2; exit 1; }
command -v tar >/dev/null || { log "tar isn't installed!" >&2; exit 1; }
command -v grep >/dev/null || { log "grep isn't installed!" >&2; exit 1; }

# download uri
# Override with SONIQ_RELEASES_URL to install from a custom location.
<<<<<<< HEAD
releases_uri=${SONIQ_RELEASES_URL:-https://github.com/soniq/cli/releases}
=======
releases_uri=${SONIQ_RELEASES_URL:-https://github.com/Bazw39/soniq/releases}
>>>>>>> adc39be (SONIQ release v2.42.0)
if [ -z "$tag" ]; then
    tag=$(curl -LsH 'Accept: application/json' $releases_uri/latest)
    tag=${tag%\,\"update_url*}
    tag=${tag##*tag_name\":\"}
    tag=${tag%\"}
fi

tag=${tag#v}

log "FETCHING Version $tag"

download_uri=$releases_uri/download/v$tag/soniq-$tag-$target.tar.gz

# locations
tar="$soniq_install/soniq.tar.gz"

# installing
[ ! -d "$soniq_install" ] && log "CREATING $soniq_install" && mkdir -p "$soniq_install"

log "DOWNLOADING $download_uri"
curl --fail --location --progress-bar --output "$tar" "$download_uri"

log "EXTRACTING $tar"
tar xzf "$tar" -C "$soniq_install"

log "SETTING EXECUTABLE PERMISSIONS TO $exe"
chmod +x "$exe"

log "REMOVING $tar"
rm "$tar"

notfound() {
    cat << EOINFO
Manually add the directory to your \$PATH through your shell profile
export SONIQ_INSTALL="$soniq_install"
export PATH="\$PATH:$soniq_install"
EOINFO
}

endswith_newline() {
    [ "$(od -An -c "$1" | tail -1 | grep -o '.$')" = "\n" ]
}

check() {
    path="export PATH=\$PATH:$soniq_install"
    shellrc=$HOME/$1

    if [ "$1" = ".zshrc" ] && [ -n "${ZDOTDIR}" ]; then
        shellrc=$ZDOTDIR/$1
    fi

    # Create shellrc if it doesn't exist
    if ! [ -f "$shellrc" ]; then
        log "CREATING $shellrc"
        touch "$shellrc"
    fi

    # Still checking again, in case touch command failed
    if [ -f "$shellrc" ]; then
        if ! grep -q "$soniq_install" "$shellrc"; then
            log "APPENDING $soniq_install to PATH in $shellrc"
            if ! endswith_newline "$shellrc"; then
                echo >> "$shellrc"
            fi
            echo "${2:-$path}" >> "$shellrc"
            export PATH="$soniq_install:$PATH"
        else
            log "soniq path already set in $shellrc, continuing..."
        fi
    else
        notfound
    fi
}

case $SHELL in
    *zsh) check ".zshrc" ;;
    *bash)
        [ -f "$HOME/.bashrc" ] && check ".bashrc"
        [ -f "$HOME/.bash_profile" ] && check ".bash_profile"
    ;;
    *fish) check ".config/fish/config.fish" "fish_add_path $soniq_install" ;;
    *) notfound ;;
esac

case ":$PATH:" in
    *":$soniq_install:"*) ;;
    *) export PATH="$soniq_install:$PATH" ;;
esac

echo
log "soniq v$tag was installed successfully to $soniq_install"
if [ -n "${shellrc:-}" ] && [ -f "$shellrc" ]; then
    log "Open a new terminal or reload your shell profile to use soniq:"
    log "  source \"$shellrc\""
    log "Then run 'soniq --help' to get started"
else
    log "After adding soniq to your PATH, run 'soniq --help' to get started"
fi

echo "Do you want to install SONIQ Marketplace? (Y/n)"
read -r choice < /dev/tty
if [ "$choice" = "N" ] || [ "$choice" = "n" ]; then
    echo "SONIQ Marketplace installation aborted"
    exit 0
fi
echo "Starting the SONIQ Marketplace installation script.."
# Third-party community Marketplace resource. Override with SONIQ_MARKETPLACE_URL.
marketplace_url=${SONIQ_MARKETPLACE_URL:-https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh}
curl -fsSL "$marketplace_url" | sh || log "WARNING: Marketplace installation failed; SONIQ itself is installed."
