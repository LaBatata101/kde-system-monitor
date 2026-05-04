#!/usr/bin/env bash
set -euo pipefail

APPLET_ID="com.labatata.sysmonitor"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/package"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids"
TARGET_DIR="$INSTALL_DIR/$APPLET_ID"

usage() {
    cat <<EOF
Usage: ./install.sh [option]

Options:
  --install          Install or update the plasmoid (default)
  --restart-plasma  Install or update, then restart Plasma Shell
  --remove          Remove the installed plasmoid
  -h, --help        Show this help
EOF
}

install_or_update() {
    if [[ ! -f "$PACKAGE_DIR/metadata.json" ]]; then
        echo "Error: package metadata not found at $PACKAGE_DIR/metadata.json" >&2
        return 1
    fi

    mkdir -p "$INSTALL_DIR"

    if [[ -d "$TARGET_DIR" ]]; then
        echo "Updating $APPLET_ID..."
        rm -rf "$TARGET_DIR"
    else
        echo "Installing $APPLET_ID..."
    fi

    mkdir -p "$TARGET_DIR"
    cp -a "$PACKAGE_DIR"/. "$TARGET_DIR"/
    echo "Installed files to $TARGET_DIR."
}

remove_plasmoid() {
    if [[ -d "$TARGET_DIR" ]]; then
        echo "Removing $APPLET_ID..."
        rm -rf "$TARGET_DIR"
        echo "Removed $TARGET_DIR."
    else
        echo "$APPLET_ID is not installed at $TARGET_DIR."
    fi
}

restart_plasma() {
    if command -v kquitapp6 >/dev/null 2>&1; then
        kquitapp6 plasmashell || true
    else
        killall plasmashell || true
    fi

    if command -v kstart >/dev/null 2>&1; then
        kstart plasmashell >/dev/null 2>&1
    elif command -v kstart6 >/dev/null 2>&1; then
        kstart6 plasmashell >/dev/null 2>&1
    else
        nohup plasmashell >/dev/null 2>&1 &
    fi
}

main() {
    local action="${1:---install}"

    case "$action" in
        --install)
            install_or_update
            ;;
        --restart-plasma)
            install_or_update
            restart_plasma
            echo "Restarted Plasma Shell."
            ;;
        --remove)
            remove_plasmoid
            ;;
        -h|--help)
            usage
            ;;
        *)
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
