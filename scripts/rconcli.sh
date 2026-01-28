#!/bin/bash
# shellcheck disable=SC2148,SC1091
# DEPRECATED: This script is a wrapper for backward compatibility.
# Please use restapicli instead.

source /includes/colors.sh

ew ">>> Warning: rconcli is deprecated. Please use 'restapicli' instead."
ew ">>> RCON has been replaced with REST API."

# Map old RCON commands to new REST API commands
command="$1"
shift

case "$command" in
    showplayers)
        exec /scripts/restapicli.sh players "$@"
        ;;
    info)
        exec /scripts/restapicli.sh info "$@"
        ;;
    save)
        exec /scripts/restapicli.sh save "$@"
        ;;
    broadcast)
        exec /scripts/restapicli.sh broadcast "$@"
        ;;
    Shutdown|shutdown)
        # Old format: Shutdown <seconds>
        exec /scripts/restapicli.sh shutdown "$@"
        ;;
    *)
        # Try to pass through to REST API CLI
        exec /scripts/restapicli.sh "$command" "$@"
        ;;
esac
