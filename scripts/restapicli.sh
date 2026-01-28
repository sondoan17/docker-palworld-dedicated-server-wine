#!/bin/bash
# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/restapi.sh

print_usage() {
    script_name=$(basename "$0")
    echo "Usage: ${script_name} <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  info                          Get server information"
    echo "  players                       List connected players"
    echo "  settings                      Get server settings"
    echo "  metrics                       Get server metrics"
    echo "  announce <message>            Send announcement to all players"
    echo "  broadcast <message>           Alias for announce (with timestamp)"
    echo "  save                          Save the world"
    echo "  shutdown [seconds] [message]  Graceful shutdown (default: 10 seconds)"
    echo "  stop                          Force stop the server"
    echo "  kick <userid> [message]       Kick a player"
    echo "  ban <userid> [message]        Ban a player"
    echo "  unban <userid>                Unban a player"
    echo "  help                          Display this help message"
    echo ""
    echo "Note: This CLI uses the REST API. Make sure RESTAPI_ENABLED=true"
}

# Check if REST API is enabled
check_restapi_enabled() {
    if [[ -z ${RESTAPI_ENABLED+x} ]] || [[ "${RESTAPI_ENABLED,,}" != "true" ]]; then
        ee ">>> REST API is not enabled. Set RESTAPI_ENABLED=true to use this CLI."
        exit 1
    fi
}

# Main command handler
main() {
    if [[ $# -lt 1 ]]; then
        print_usage
        exit 1
    fi

    local command="$1"
    shift

    case "$command" in
        info)
            check_restapi_enabled
            response=$(api_get_info)
            if [[ $? -eq 0 ]]; then
                echo "$response" | jq .
            fi
            ;;
        players|showplayers)
            check_restapi_enabled
            response=$(api_get_players)
            if [[ $? -eq 0 ]]; then
                player_count=$(echo "$response" | jq -r '.players | length')
                echo "Connected players: $player_count"
                echo ""
                echo "$response" | jq -r '.players[] | "  \(.name) (ID: \(.playerId), User: \(.userId))"'
            fi
            ;;
        settings)
            check_restapi_enabled
            response=$(api_get_settings)
            if [[ $? -eq 0 ]]; then
                echo "$response" | jq .
            fi
            ;;
        metrics)
            check_restapi_enabled
            response=$(api_get_metrics)
            if [[ $? -eq 0 ]]; then
                echo "$response" | jq .
            fi
            ;;
        announce)
            check_restapi_enabled
            if [[ $# -lt 1 ]]; then
                ee ">>> Usage: announce <message>"
                exit 1
            fi
            message="$*"
            if api_announce "$message"; then
                es "> Announcement sent: $message"
            fi
            ;;
        broadcast)
            check_restapi_enabled
            if [[ $# -lt 1 ]]; then
                ee ">>> Usage: broadcast <message>"
                exit 1
            fi
            message="$*"
            if api_broadcast "$message"; then
                es "> Broadcast sent: $message"
            fi
            ;;
        save)
            check_restapi_enabled
            if api_save; then
                es "> World saved successfully"
            fi
            ;;
        shutdown)
            check_restapi_enabled
            waittime="${1:-10}"
            shift 2>/dev/null || true
            message="$*"
            if [[ -n "$message" ]]; then
                ei "> Initiating shutdown in $waittime seconds with message: $message"
                api_shutdown "$waittime" "$message"
            else
                ei "> Initiating shutdown in $waittime seconds"
                api_shutdown "$waittime"
            fi
            ;;
        stop)
            check_restapi_enabled
            ew "> Force stopping server..."
            if api_stop; then
                es "> Server force stop initiated"
            fi
            ;;
        kick)
            check_restapi_enabled
            if [[ $# -lt 1 ]]; then
                ee ">>> Usage: kick <userid> [message]"
                exit 1
            fi
            userid="$1"
            shift
            message="$*"
            if [[ -n "$message" ]]; then
                api_kick "$userid" "$message"
            else
                api_kick "$userid"
            fi
            es "> Player $userid kicked"
            ;;
        ban)
            check_restapi_enabled
            if [[ $# -lt 1 ]]; then
                ee ">>> Usage: ban <userid> [message]"
                exit 1
            fi
            userid="$1"
            shift
            message="$*"
            if [[ -n "$message" ]]; then
                api_ban "$userid" "$message"
            else
                api_ban "$userid"
            fi
            es "> Player $userid banned"
            ;;
        unban)
            check_restapi_enabled
            if [[ $# -lt 1 ]]; then
                ee ">>> Usage: unban <userid>"
                exit 1
            fi
            userid="$1"
            if api_unban "$userid"; then
                es "> Player $userid unbanned"
            fi
            ;;
        help|--help|-h)
            print_usage
            ;;
        *)
            ee ">>> Unknown command: $command"
            print_usage
            exit 1
            ;;
    esac
}

main "$@"
