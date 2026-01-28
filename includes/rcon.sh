# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/restapi.sh

function get_time() {
    date '+[%H:%M:%S]'
}

function save_and_shutdown_server() {
    api_broadcast "Server shutdown requested. Saving..."
    api_save
    api_broadcast "Saving done. Server shutting down..."
    api_shutdown 10 "Server is shutting down"
}

function broadcast_automatic_restart() {
    local countdown="${RESTART_COUNTDOWN:-15}"

    for ((counter=countdown; counter>=1; counter--)); do
        if [[ -n $RESTART_ANNOUNCE_MESSAGES_ENABLED ]] && [[ "${RESTART_ANNOUNCE_MESSAGES_ENABLED,,}" == "true" ]]; then
            api_broadcast "AUTOMATIC RESTART IN $counter MINUTES"
        fi
        sleep 60
    done

    if [[ -n $RESTART_ANNOUNCE_MESSAGES_ENABLED ]] && [[ "${RESTART_ANNOUNCE_MESSAGES_ENABLED,,}" == "true" ]]; then
        api_broadcast "Saving world before restart..."
    fi
    api_save
    api_broadcast "Saving done"

    if [[ -n $BACKUP_ANNOUNCE_MESSAGES_ENABLED ]] && [[ "${RESTART_ANNOUNCE_MESSAGES_ENABLED,,}" == "true" ]]; then
        api_broadcast "Creating backup"
    fi
    api_shutdown 10 "Server is restarting"
}

function broadcast_backup_start() {
    if [[ -n $BACKUP_ANNOUNCE_MESSAGES_ENABLED ]] && [[ "${BACKUP_ANNOUNCE_MESSAGES_ENABLED,,}" == "true" ]]; then
        api_broadcast "Saving in 5 seconds..."
        sleep 5
        api_broadcast "Saving world..."
        api_save
        api_broadcast "Saving done"
        sleep 15
        api_broadcast "Creating backup..."
    else
        api_save
    fi
}

function broadcast_backup_success() {
    if [[ -n $BACKUP_ANNOUNCE_MESSAGES_ENABLED ]] && [[ "${BACKUP_ANNOUNCE_MESSAGES_ENABLED,,}" == "true" ]]; then
        api_broadcast "Backup done"
    fi
}

function broadcast_backup_failed() {
    api_broadcast "Backup failed"
}

function broadcast_player_name_change() {
    api_broadcast "$1 renamed to $2"
}

function check_is_server_empty() {
    api_is_server_empty
}
