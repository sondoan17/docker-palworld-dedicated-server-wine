# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

# REST API Configuration
RESTAPI_BASE_URL="${RESTAPI_BASE_URL:-http://localhost:${RESTAPI_PORT:-8212}/v1/api}"

# Base function to make REST API requests
# Arguments: <method> <endpoint> [json_body]
# Returns: Response body on success, empty on failure
# Exit code: 0 on success (2xx), 1 on failure
# Note: Pass empty string "" for POST requests that need Content-Length but no body
api_request() {
    local method="$1"
    local endpoint="$2"
    local url="${RESTAPI_BASE_URL}${endpoint}"
    local auth="admin:${ADMIN_PASSWORD}"
    local response
    local http_code
    local temp_file

    temp_file=$(mktemp)

    if [[ $# -ge 3 ]]; then
        # Body provided (can be empty string for POST without payload)
        local body="$3"
        http_code=$(curl -s -X "$method" \
            -u "$auth" \
            -H "Content-Type: application/json" \
            -d "$body" \
            -w "%{http_code}" \
            -o "$temp_file" \
            "$url")
    else
        # No body (GET requests)
        http_code=$(curl -s -X "$method" \
            -u "$auth" \
            -H "Accept: application/json" \
            -w "%{http_code}" \
            -o "$temp_file" \
            "$url")
    fi

    response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 300 ]]; then
        echo "$response"
        return 0
    else
        ew "> REST API request failed: $method $endpoint (HTTP $http_code)"
        if [[ -n "$response" ]]; then
            ew "> Response: $response"
        fi
        return 1
    fi
}

# GET /players - Get list of connected players
# Returns: JSON array of players
api_get_players() {
    api_request "GET" "/players"
}

# GET /info - Get server information
# Returns: JSON with server info
api_get_info() {
    api_request "GET" "/info"
}

# GET /settings - Get server settings
# Returns: JSON with server settings
api_get_settings() {
    api_request "GET" "/settings"
}

# GET /metrics - Get server metrics
# Returns: JSON with server metrics
api_get_metrics() {
    api_request "GET" "/metrics"
}

# POST /announce - Send broadcast message to all players
# Arguments: <message>
api_announce() {
    local message="$1"
    local body
    body=$(jq -n --arg msg "$message" '{"message": $msg}')
    api_request "POST" "/announce" "$body"
}

# POST /save - Save the world
api_save() {
    api_request "POST" "/save" ""
}

# POST /shutdown - Graceful shutdown with countdown
# Arguments: <waittime_seconds> [message]
api_shutdown() {
    local waittime="${1:-10}"
    local message="${2:-}"
    local body

    if [[ -n "$message" ]]; then
        body=$(jq -n --argjson wait "$waittime" --arg msg "$message" '{"waittime": $wait, "message": $msg}')
    else
        body=$(jq -n --argjson wait "$waittime" '{"waittime": $wait}')
    fi
    api_request "POST" "/shutdown" "$body"
}

# POST /stop - Force stop the server immediately
api_stop() {
    api_request "POST" "/stop" ""
}

# POST /kick - Kick a player
# Arguments: <userid> [message]
api_kick() {
    local userid="$1"
    local message="${2:-}"
    local body

    if [[ -n "$message" ]]; then
        body=$(jq -n --arg uid "$userid" --arg msg "$message" '{"userid": $uid, "message": $msg}')
    else
        body=$(jq -n --arg uid "$userid" '{"userid": $uid}')
    fi
    api_request "POST" "/kick" "$body"
}

# POST /ban - Ban a player
# Arguments: <userid> [message]
api_ban() {
    local userid="$1"
    local message="${2:-}"
    local body

    if [[ -n "$message" ]]; then
        body=$(jq -n --arg uid "$userid" --arg msg "$message" '{"userid": $uid, "message": $msg}')
    else
        body=$(jq -n --arg uid "$userid" '{"userid": $uid}')
    fi
    api_request "POST" "/ban" "$body"
}

# POST /unban - Unban a player
# Arguments: <userid>
api_unban() {
    local userid="$1"
    local body
    body=$(jq -n --arg uid "$userid" '{"userid": $uid}')
    api_request "POST" "/unban" "$body"
}

# Helper: Check if server has no players connected
# Returns: 0 if empty, 1 if has players
api_is_server_empty() {
    local response
    local player_count

    response=$(api_get_players) || return 1

    # Parse JSON response to get player count
    player_count=$(echo "$response" | jq -r '.players | length' 2>/dev/null)

    if [[ "$player_count" == "0" ]] || [[ -z "$player_count" ]]; then
        return 0  # Server is empty
    else
        return 1  # Server has players
    fi
}

# Helper: Get player count
# Returns: Number of players or -1 on error
api_get_player_count() {
    local response
    local player_count

    response=$(api_get_players) || {
        echo "-1"
        return 1
    }

    player_count=$(echo "$response" | jq -r '.players | length' 2>/dev/null)

    if [[ -z "$player_count" ]]; then
        echo "-1"
        return 1
    fi

    echo "$player_count"
    return 0
}

# Helper: Get player list as array (name,playeruid,steamid format for compatibility)
# Returns: One player per line in CSV format
api_get_players_csv() {
    local response
    response=$(api_get_players) || return 1

    # Convert JSON to CSV format: name,playeruid,steamid
    echo "$response" | jq -r '.players[] | "\(.name),\(.playerId),\(.userId)"' 2>/dev/null
}

# Helper: Broadcast with timestamp prefix
api_broadcast() {
    local message="$1"
    local time
    time=$(date '+[%H:%M:%S]')
    api_announce "${time} ${message}"
}
