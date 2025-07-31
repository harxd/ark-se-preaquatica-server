#!/bin/bash
set -e

# --- Environment Variables with Defaults ---
# If a variable is not set, its default value will be used.
export SESSION_NAME="${SESSION_NAME:-ARK Pre-Aquatic Server}"
export SERVER_MAP="${SERVER_MAP:-TheIsland}"
export SERVER_PASSWORD="${SERVER_PASSWORD:-}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-$(openssl rand -base64 12)}"
export MAX_PLAYERS="${MAX_PLAYERS:-20}"
export DISABLE_BATTLEYE="${DISABLE_BATTLEYE:-true}"
export GAME_MOD_IDS="${GAME_MOD_IDS:-}"

# Define SteamCMD and ARK paths
STEAMCMD_DIR="/home/steam/steamcmd"
ARK_DIR="/ark"

# --- Server and Mod Installation/Update ---
echo ">>> Checking for ARK server updates..."
# The '-beta preaquatica' flag targets the specific branch
$STEAMCMD_DIR/steamcmd.sh +force_install_dir $ARK_DIR +login anonymous +app_update 376030 -beta preaquatica validate +quit

# Check and install/update mods if GAME_MOD_IDS is set
if [ -n "$GAME_MOD_IDS" ]; then
    echo ">>> Checking for Mod updates: ${GAME_MOD_IDS}..."
    # Replace commas with spaces for the loop
    MOD_ID_LIST=$(echo $GAME_MOD_IDS | sed 's/,/ /g')
    for MOD_ID in $MOD_ID_LIST; do
        echo ">>> Installing/Updating Mod ID: $MOD_ID"
        $STEAMCMD_DIR/steamcmd.sh +force_install_dir $ARK_DIR +login anonymous +workshop_download_item 346110 $MOD_ID validate +quit
    done
fi

# --- Construct Server Launch Arguments ---
# Base command with map and essential flags
SERVER_ARGS="${SERVER_MAP}?SessionName=${SESSION_NAME}?MaxPlayers=${MAX_PLAYERS}?Port=7777??QueryPort=27015"

# Add server password if it is set
if [ -n "$SERVER_PASSWORD" ]; then
    SERVER_ARGS="${SERVER_ARGS}?ServerPassword=${SERVER_PASSWORD}"
fi

# Add admin password
SERVER_ARGS="${SERVER_ARGS}?ServerAdminPassword=${ADMIN_PASSWORD}"

# Add mods if they are set
if [ -n "$GAME_MOD_IDS" ]; then
    SERVER_ARGS="${SERVER_ARGS}?GameModIds=${GAME_MOD_IDS}"
fi

# Add BattlEye flag if disabled
if [ "$DISABLE_BATTLEYE" = "true" ]; then
    SERVER_ARGS="${SERVER_ARGS} -NoBattlEye"
fi

# --- Start the Server ---
echo "---"
echo "ARK Server Configuration:"
echo "  Session Name: ${SESSION_NAME}"
echo "  Map: ${SERVER_MAP}"
echo "  Max Players: ${MAX_PLAYERS}"
echo "  Admin Password: ${ADMIN_PASSWORD}" # This is printed to the log on first start
echo "  Mods: ${GAME_MOD_IDS:-None}"
echo "---"
echo ">>> Starting ARK: Survival Evolved Server..."

# The 'exec' command replaces the script process with the server process
exec $ARK_DIR/ShooterGame/Binaries/Linux/ShooterGameServer $SERVER_ARGS -server -log