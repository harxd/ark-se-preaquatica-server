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
export SERVER_SETTINGS="${SERVER_SETTINGS:-}"

# Define SteamCMD and ARK paths
STEAMCMD_DIR="/home/steam/steamcmd"
ARK_DIR="/ark"

# --- Download ARK server if not present ---
if [ ! -f "$ARK_DIR/ShooterGame/Binaries/Linux/ShooterGameServer" ]; then
    echo ">>> ARK server not found in $ARK_DIR. Downloading ARK server files..."
    $STEAMCMD_DIR/steamcmd.sh +force_install_dir $ARK_DIR +login anonymous +app_update 376030 -beta preaquatica validate +quit
fi

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
SERVER_ARGS="${SERVER_MAP}?SessionName=${SESSION_NAME}?MaxPlayers=${MAX_PLAYERS}?Port=7777??QueryPort=27015"

# Add server password if it is set
if [ -n "$SERVER_PASSWORD" ]; then
    SERVER_ARGS="${SERVER_ARGS}?ServerPassword=${SERVER_PASSWORD}"
fi

# Add admin password
SERVER_ARGS="${SERVER_ARGS}?ServerAdminPassword=${ADMIN_PASSWORD}"

# Remove mod IDs from launch arguments (handled in GameUserSettings.ini)

# Add BattlEye flag if disabled
if [ "$DISABLE_BATTLEYE" = "true" ]; then
    SERVER_ARGS="${SERVER_ARGS} -NoBattlEye"
fi

# --- Ensure GameUserSettings.ini exists and inject server settings ---

GAME_USER_SETTINGS_PATH="$ARK_DIR/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini"

if [ ! -f "$GAME_USER_SETTINGS_PATH" ]; then
    echo ">>> GameUserSettings.ini not found. Starting server once to generate config files..."
    exec $ARK_DIR/ShooterGame/Binaries/Linux/ShooterGameServer $SERVER_MAP?SessionName=${SESSION_NAME}?MaxPlayers=${MAX_PLAYERS}?Port=7777??QueryPort=27015 -NoTransferFromFiltering -activeevent=none -UseVivox -noundermeshkilling -server -log &
    SERVER_PID=$!
    for i in {1..120}; do
        if [ -f "$GAME_USER_SETTINGS_PATH" ]; then
            break
        fi
        sleep 1
    done
    kill $SERVER_PID
    wait $SERVER_PID 2>/dev/null
    echo ">>> GameUserSettings.ini generated."
fi

# Add server settings from SERVER_SETTINGS variable to [ServerSettings] section
if [ -n "$SERVER_SETTINGS" ] || [ -n "$GAME_MOD_IDS" ]; then
    echo ">>> Applying server settings to GameUserSettings.ini..."
    # Ensure [ServerSettings] exists
    if ! grep -q "^\[ServerSettings\]" "$GAME_USER_SETTINGS_PATH"; then
        echo "[ServerSettings]" >> "$GAME_USER_SETTINGS_PATH"
    fi

    TMP_FILE=$(mktemp)
    awk '
        BEGIN { in_section=0 }
        /^\[ServerSettings\]/ { print; in_section=1; next }
        /^\[/ { if(in_section){in_section=0}; print; next }
        { if(!in_section) print }
    ' "$GAME_USER_SETTINGS_PATH" > "$TMP_FILE"

    echo "[ServerSettings]" >> "$TMP_FILE"
    IFS=',' read -ra SETTINGS <<< "$SERVER_SETTINGS"
    for SETTING in "${SETTINGS[@]}"; do
        echo "$SETTING" >> "$TMP_FILE"
    done

    # Add ActiveMods line if GAME_MOD_IDS is set
    if [ -n "$GAME_MOD_IDS" ]; then
        echo "ActiveMods=${GAME_MOD_IDS}" >> "$TMP_FILE"
    fi

    # Add the rest of the file after [ServerSettings]
    awk '
        BEGIN { in_section=0 }
        /^\[ServerSettings\]/ { in_section=1; next }
        /^\[/ { if(in_section){in_section=0}; print; next }
        { if(!in_section) print }
    ' "$GAME_USER_SETTINGS_PATH" >> "$TMP_FILE"

    mv "$TMP_FILE" "$GAME_USER_SETTINGS_PATH"
fi

# --- Start the Server for good ---
echo ">>> Starting ARK: Survival Evolved Server..."
exec $ARK_DIR/ShooterGame/Binaries/Linux/ShooterGameServer $SERVER_ARGS -NoTransferFromFiltering -activeevent=none -UseVivox -noundermeshkilling -server -log