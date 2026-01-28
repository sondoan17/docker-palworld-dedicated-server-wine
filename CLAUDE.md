# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker container for running a Palworld Dedicated Server using Wine (Windows version of the server on Linux). This is a fork of jammsen's docker-palworld-dedicated-server, modified to run the Windows server binary instead of the Linux version.

Key differences from upstream:
- Uses Wine to run the Windows server executable (`PalServer-Win64-Shipping-Cmd.exe`)
- Requires Xvfb for virtual display
- Uses Windows SteamCMD via Wine for game updates
- Supports UE4SS framework for mods
- Uses REST API instead of deprecated RCON for server management

## Build Commands

```bash
# Build locally
./docker-build.sh

# Or with docker-compose
docker-compose build
```

## Running the Server

```bash
# Start server
docker-compose up -d

# View logs
docker-compose logs -f

# Stop server
docker-compose down
```

## CLI Tools Available Inside Container

```bash
# REST API commands (preferred)
docker exec palworld-wine-server restapicli <command>

# Available commands:
#   info                          Get server information
#   players                       List connected players
#   settings                      Get server settings
#   metrics                       Get server metrics
#   announce <message>            Send announcement to all players
#   broadcast <message>           Announce with timestamp
#   save                          Save the world
#   shutdown [seconds] [message]  Graceful shutdown
#   stop                          Force stop the server
#   kick <userid> [message]       Kick a player
#   ban <userid> [message]        Ban a player
#   unban <userid>                Unban a player

# Backup management
docker exec --user steam palworld-wine-server backup create
docker exec --user steam palworld-wine-server backup list [count]
docker exec --user steam palworld-wine-server backup clean [keep_count]

# Manual update
docker exec palworld-wine-server update

# Restart server
docker exec palworld-wine-server restart
```

## Architecture

### Container Flow
1. `entrypoint.sh` - Initializes user permissions (PUID/PGID), starts Xvfb virtual display, runs CMD as steam user via gosu
2. `scripts/servermanager.sh` - Main process loop, handles SIGTERM, coordinates server lifecycle and player detection
3. `includes/server.sh` - Server start/stop/update functions, Wine/SteamCMD integration
4. `includes/config.sh` - Config file generation (PalWorldSettings.ini, Engine.ini) from environment variables

### REST API Integration
- `includes/restapi.sh` - REST API client library with functions for all endpoints
- `scripts/restapicli.sh` - CLI tool for REST API commands
- Uses Basic Auth with `admin:ADMIN_PASSWORD`
- Default endpoint: `http://localhost:8212/v1/api`

### Key Directories
- `/palworld` - Game root, mounted as volume (`./game:/palworld`)
- `/palworld/Pal/Saved/Config/WindowsServer/` - Server config files
- `/palworld/backups/` - Backup storage
- `/home/steam/steamcmd/` - Windows SteamCMD installation
- `/includes/` - Bash function libraries
- `/scripts/` - CLI tools and management scripts

### Configuration Modes (SERVER_SETTINGS_MODE)
- `auto` - All settings via environment variables (default)
- `manual` - All settings via direct file editing

### Cron Jobs
Managed by Supercronic. Setup in `includes/cron.sh`:
- Backups (`BACKUP_CRON_EXPRESSION`)
- Auto-restarts (`RESTART_CRON_EXPRESSION`)
- Auto-updates (`AUTO_UPDATE_CRON_EXPRESSION`)

### Wine Environment
- `WINEPREFIX=/home/steam/.wine`
- `WINEARCH=win64`
- Winetricks installs vcrun2022 on first start if `WINETRICK_ON_START=true`

## Environment Variables

Configuration split between container behavior and game settings. See `docs/ENV_VARS.md` for full documentation. Key variables in `default.env`.

### Key REST API Variables
- `RESTAPI_ENABLED=true` - Enable REST API (required for management features)
- `RESTAPI_PORT=8212` - REST API port
- `ADMIN_PASSWORD` - Admin password for REST API authentication
- `PLAYER_DETECTION=true` - Enable player join/leave detection via REST API
- `PLAYER_DETECTION_STARTUP_DELAY=60` - Delay before starting player detection
- `PLAYER_DETECTION_CHECK_INTERVAL=15` - Interval between player checks

### Legacy RCON (Deprecated)
RCON support has been replaced with REST API. The `rconcli` command is now a wrapper that forwards commands to `restapicli`. Variables `RCON_ENABLED` and `RCON_PORT` are kept for PalWorldSettings.ini but RCON_ENABLED defaults to false.

## GitHub Actions

- `docker-publish-master.yml` - Publishes to GHCR on master branch
- `docker-publish.yml` - Creates testing images on work branch
- `docker-pakage-publish.yml` - Package publishing workflow
