# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

function check_for_default_credentials() {
    e "> Checking for existence of default credentials"
    if [[ -n $ADMIN_PASSWORD ]] && [[ $ADMIN_PASSWORD == "adminPasswordHere" ]]; then
        ee ">>> Security threat detected: Please change the default admin password. Aborting server start ..."
        exit 1
    fi
    if [[ -n $SERVER_PASSWORD ]] && [[ $SERVER_PASSWORD == "serverPasswordHere" ]]; then
        ee ">>> Security threat detected: Please change the default server password. Aborting server start ..."
        exit 1
    fi
    es "> No default passwords found"
}

function check_for_deprecated_variables() {
    e "> Checking for deprecated variables..."
    local deprecated_found=false

    # RCON_PLAYER_DETECTION -> PLAYER_DETECTION
    if [[ -n ${RCON_PLAYER_DETECTION+x} ]]; then
        ew ">>> WARNING: 'RCON_PLAYER_DETECTION' is deprecated. Use 'PLAYER_DETECTION' instead."
        deprecated_found=true
        export PLAYER_DETECTION="${RCON_PLAYER_DETECTION}"
    fi

    # RCON_PLAYER_DEBUG -> PLAYER_DETECTION_DEBUG
    if [[ -n ${RCON_PLAYER_DEBUG+x} ]]; then
        ew ">>> WARNING: 'RCON_PLAYER_DEBUG' is deprecated. Use 'PLAYER_DETECTION_DEBUG' instead."
        deprecated_found=true
        export PLAYER_DETECTION_DEBUG="${RCON_PLAYER_DEBUG}"
    fi

    # RCON_PLAYER_DETECTION_STARTUP_DELAY -> PLAYER_DETECTION_STARTUP_DELAY
    if [[ -n ${RCON_PLAYER_DETECTION_STARTUP_DELAY+x} ]]; then
        ew ">>> WARNING: 'RCON_PLAYER_DETECTION_STARTUP_DELAY' is deprecated. Use 'PLAYER_DETECTION_STARTUP_DELAY' instead."
        deprecated_found=true
        export PLAYER_DETECTION_STARTUP_DELAY="${RCON_PLAYER_DETECTION_STARTUP_DELAY}"
    fi

    # RCON_PLAYER_DETECTION_CHECK_INTERVAL -> PLAYER_DETECTION_CHECK_INTERVAL
    if [[ -n ${RCON_PLAYER_DETECTION_CHECK_INTERVAL+x} ]]; then
        ew ">>> WARNING: 'RCON_PLAYER_DETECTION_CHECK_INTERVAL' is deprecated. Use 'PLAYER_DETECTION_CHECK_INTERVAL' instead."
        deprecated_found=true
        export PLAYER_DETECTION_CHECK_INTERVAL="${RCON_PLAYER_DETECTION_CHECK_INTERVAL}"
    fi

    # RCON_ENABLED used for player detection -> RESTAPI_ENABLED
    if [[ -n ${RCON_ENABLED+x} ]] && [[ "${RCON_ENABLED,,}" == "true" ]] && [[ -z ${RESTAPI_ENABLED+x} ]]; then
        ew ">>> WARNING: RCON is deprecated for server management. Please use RESTAPI_ENABLED=true instead."
        ew ">>> Auto-enabling REST API for backward compatibility."
        deprecated_found=true
        export RESTAPI_ENABLED="true"
    fi

    if [[ -n ${RCON_QUIET_RESTART+x} ]]; then
        ew ">>> WARNING: The environment variable 'RCON_QUIET_RESTART' is deprecated and will be removed in a future version."
        ew ">>> Please use 'RESTART_ANNOUNCE_MESSAGES_ENABLED' instead."
        deprecated_found=true
        if [[ "$RCON_QUIET_RESTART" == "true" ]]; then
            export RESTART_ANNOUNCE_MESSAGES_ENABLED="false"
        else
            export RESTART_ANNOUNCE_MESSAGES_ENABLED="true"
        fi
    fi
    if [[ -n ${RCON_QUIET_BACKUP+x} ]]; then
        ew ">>> WARNING: The environment variable 'RCON_QUIET_BACKUP' is deprecated and will be removed in a future version."
        ew ">>> Please use 'BACKUP_ANNOUNCE_MESSAGES_ENABLED' instead."
        deprecated_found=true
        if [[ "$RCON_QUIET_BACKUP" == "true" ]]; then
            export BACKUP_ANNOUNCE_MESSAGES_ENABLED="false"
        else
            export BACKUP_ANNOUNCE_MESSAGES_ENABLED="true"
        fi
    fi
    if [[ -n ${RCON_QUIET_SAVE+x} ]]; then
        ew ">>> WARNING: The environment variable 'RCON_QUIET_SAVE' is deprecated and will be removed in a future version."
        ew ">>> Please use 'BACKUP_ANNOUNCE_MESSAGES_ENABLED' instead."
        deprecated_found=true
        # RCON_QUIET_SAVE=true meant no save announcements. This now maps to no backup announcements.
        if [[ "$RCON_QUIET_SAVE" == "true" ]]; then
            export BACKUP_ANNOUNCE_MESSAGES_ENABLED="false"
        else
            export BACKUP_ANNOUNCE_MESSAGES_ENABLED="true"
        fi
    fi

    if [[ "$deprecated_found" == "false" ]]; then
        es "> No deprecated variables found"
    fi
}
