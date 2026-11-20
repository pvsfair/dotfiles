#!/usr/bin/env bash

# Tablet settings (Galaxy Tab S8 Ultra)
RESOLUTION="1920x1200"
REFRESH_RATE="60"
SCALE="1" # Change to 2.0 if UI elements still look too small.
PORT="3131"
PORT_EXPLICIT=false
START_VNC=false

# Fixed name for the virtual monitor.
CUSTOM_NAME="HEADLESS-1"

# Keep redirected output and terminals without color support readable.
COLOR_RESET=""
COLOR_CYAN=""
COLOR_GREEN=""
COLOR_YELLOW=""
COLOR_RED=""
if [[ -t 1 && "${TERM:-dumb}" != dumb && -z "${NO_COLOR+x}" ]]; then
    COLOR_RESET=$'\033[0m'
    COLOR_CYAN=$'\033[1;36m'
    COLOR_GREEN=$'\033[32m'
    COLOR_YELLOW=$'\033[33m'
    COLOR_RED=$'\033[31m'
fi

status_line() {
    printf '%s%s%s\n' "$1" "$2" "$COLOR_RESET"
}

show_status() {
    local monitors monitor processes process_status devices serial state rest forwards

    printf '\n'
    status_line "$COLOR_CYAN" '=== Current status ==='
    if monitors=$(hyprctl monitors -j 2>/dev/null) &&
        monitor=$(jq -r --arg name "$CUSTOM_NAME" \
            '.[] | select(.name == $name) | "\(.width)x\(.height) @ \(.refreshRate) Hz, scale \(.scale)"' \
            <<< "$monitors" 2>/dev/null); then
        if [ -n "$monitor" ]; then
            status_line "$COLOR_GREEN" "Monitor $CUSTOM_NAME: active — $monitor"
        else
            status_line "$COLOR_YELLOW" "Monitor $CUSTOM_NAME: inactive"
        fi
    else
        status_line "$COLOR_RED" "Monitor $CUSTOM_NAME: unable to query status."
    fi

    printf '\n'
    status_line "$COLOR_CYAN" 'WayVNC for the current user (PID and command):'
    processes=$(pgrep -a -u "$UID" -x wayvnc 2>/dev/null)
    process_status=$?
    case "$process_status" in
        0) status_line "$COLOR_GREEN" "$processes" ;;
        1) status_line "$COLOR_YELLOW" 'No running processes.' ;;
        *) status_line "$COLOR_RED" 'Unable to query processes.' ;;
    esac

    printf '\n'
    status_line "$COLOR_CYAN" 'ADB devices and reverse mappings (tablet → PC):'
    if devices=$(adb devices 2>/dev/null); then
        if [ -z "${devices//[[:space:]]/}" ] || [[ "$devices" != *$'\n'* ]]; then
            status_line "$COLOR_YELLOW" 'No devices found.'
        fi
        while read -r serial state rest; do
            [ -n "$serial" ] || continue
            if [ "$state" != device ]; then
                status_line "$COLOR_YELLOW" "  $serial: $state"
                continue
            fi
            status_line "$COLOR_GREEN" "  $serial: $state"
            if forwards=$(adb -s "$serial" reverse --list 2>/dev/null); then
                if [ -n "$forwards" ]; then
                    status_line "$COLOR_GREEN" "    $forwards"
                else
                    status_line "$COLOR_YELLOW" '    No active reverse mappings.'
                fi
            else
                status_line "$COLOR_RED" '    Unable to query reverse mappings.'
            fi
        done < <(printf '%s\n' "$devices" | tail -n +2)
    else
        status_line "$COLOR_RED" 'Unable to query ADB.'
    fi
    printf '\n'
    status_line "$COLOR_YELLOW" 'An active mapping does not guarantee that Deskreen or its video stream is working.'
    printf '\n'
}

usage() {
    printf 'Usage: %s [--vnc] [-p PORT | --port PORT]\n' "${0##*/}"
    printf 'Toggle the virtual monitor and forward a port through ADB.\n'
    printf 'Without arguments: show current status and prompt for WayVNC and the port.\n'
    printf 'With arguments: run without prompts.\n'
    printf 'Without --vnc: Deskreen must already be running separately; default port 3131.\n'
    printf 'With --vnc: start WayVNC; default port 5900.\n'
    printf '-p/--port overrides the port in either mode.\n'
    printf 'To stop, use the same mode and port used to start.\n'
}

# Without arguments, collect options before changing the monitor or tunnel.
if [ "$#" -eq 0 ]; then
    show_status
    printf 'If the monitor is already active, select the same mode and port to stop it.\n'
    while true; do
        printf 'start wayvnc? [y/N] ' >&2
        if ! read -r VNC_ANSWER; then
            printf '\nInput closed; no changes made.\n' >&2
            exit 1
        fi
        case "${VNC_ANSWER,,}" in
            y|yes|s|sim)
                START_VNC=true
                PORT="5900"
                break
                ;;
            n|no|nao|não|'')
                break
                ;;
            *)
                printf 'Enter y (yes) or n (no).\n' >&2
                ;;
        esac
    done

    printf 'port for adb? [%s] ' "$PORT" >&2
    if ! read -r PORT_ANSWER; then
        printf '\nInput closed; no changes made.\n' >&2
        exit 1
    fi
    if [ -n "$PORT_ANSWER" ]; then
        PORT="$PORT_ANSWER"
        PORT_EXPLICIT=true
    fi
fi

while [ "$#" -gt 0 ]; do
    case "$1" in
        -p|--port)
            if [ "$#" -lt 2 ]; then
                printf 'Error: %s requires a port.\n' "$1" >&2
                exit 1
            fi
            PORT="$2"
            PORT_EXPLICIT=true
            shift 2
            ;;
        --vnc)
            START_VNC=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Error: unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ "$START_VNC" = true ] && [ "$PORT_EXPLICIT" = false ]; then
    PORT="5900"
fi

if [[ ! "$PORT" =~ ^[0-9]{1,5}$ ]]; then
    printf 'Error: port must be a number between 1 and 65535.\n' >&2
    exit 1
fi
PORT=$((10#$PORT))
if (( PORT < 1 || PORT > 65535 )); then
    printf 'Error: port must be a number between 1 and 65535.\n' >&2
    exit 1
fi

# Check whether the monitor with the fixed name already exists.
EXISTING_MONITOR=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$CUSTOM_NAME\") | .name" | head -n 1)

# ---- STOP MODE ----
if [ -n "$EXISTING_MONITOR" ]; then
    echo "🚨 Virtual monitor '$CUSTOM_NAME' detected. Stopping the session..."

    if [ "$START_VNC" = true ]; then
        # Stop only WayVNC matching this user, monitor and port.
        pkill -u "$UID" -f "^wayvnc --output=$CUSTOM_NAME 127[.]0[.]0[.]1 $PORT$" \
            && echo "✅ WayVNC stopped."
    fi

    # Remove the monitor using its fixed name.
    hyprctl output remove "$CUSTOM_NAME" && echo "✅ Monitor '$CUSTOM_NAME' removed."

    # Remove the ADB reverse mapping if a device is connected.
    if adb devices | grep -q -w "device"; then
        adb reverse --remove "tcp:$PORT" && echo "✅ ADB reverse mapping removed."
    fi

    echo "🎉 Shutdown complete!"
    exit 0
fi

# ---- START MODE ----
if [ "$START_VNC" = true ] && ! command -v wayvnc >/dev/null 2>&1; then
    echo "❌ Error: WayVNC is not installed." >&2
    exit 1
fi

echo "🚀 Setting up the virtual monitor..."

# 1. Create the headless output with a fixed custom name.
echo "📺 Creating virtual output '$CUSTOM_NAME' in Hyprland..."
hyprctl output create headless "$CUSTOM_NAME"

# Give Hyprland a moment to register the output.
sleep 0.5

# 2. Set the resolution and scale using the fixed name.
echo "⚙️ Configuring $CUSTOM_NAME at ${RESOLUTION}@${REFRESH_RATE} with scale ${SCALE}..."
hyprctl keyword monitor "$CUSTOM_NAME,${RESOLUTION}@${REFRESH_RATE},auto,${SCALE}"

# 3. Check the ADB device.
echo "📱 Checking the tablet's USB connection (ADB)..."
if ! adb devices | grep -q -w "device"; then
    echo "❌ Error: no Android tablet detected through ADB."
    echo "💡 Make sure USB debugging is enabled and the cable is connected."
    # Remove the newly created monitor before exiting.
    hyprctl output remove "$CUSTOM_NAME"
    exit 1
fi

# 4. Set up ADB reverse forwarding.
echo "🔗 Setting up the USB port tunnel..."
# Remove any stale mapping before creating a new one.
adb reverse --remove "tcp:$PORT" 2>/dev/null
if adb reverse "tcp:$PORT" "tcp:$PORT"; then
    echo "✅ Port $PORT forwarded through USB."
else
    echo "❌ Error setting up adb reverse."
    hyprctl output remove "$CUSTOM_NAME"
    exit 1
fi

# 5. Start the VNC server only when requested.
if [ "$START_VNC" = true ]; then
    echo "🌐 Starting WayVNC for monitor $CUSTOM_NAME..."
    wayvnc --output="$CUSTOM_NAME" 127.0.0.1 "$PORT" &
    VNC_PID=$!
    sleep 0.5
    if ! kill -0 "$VNC_PID" 2>/dev/null; then
        echo "❌ Error: WayVNC exited during startup." >&2
        adb reverse --remove "tcp:$PORT"
        hyprctl output remove "$CUSTOM_NAME"
        exit 1
    fi
    echo "✨ Open AVNC or bVNC on the tablet and connect to localhost:$PORT."
    echo "💡 To stop, run again with --vnc -p $PORT."
else
    # Deskreen runs separately; ADB forwards its TCP port.
    echo "✨ Monitor and tunnel ready! With Deskreen running on the PC, open http://localhost:$PORT in the tablet's browser."
    echo "💡 If the Deskreen link includes a path or code, keep it and replace only the address with localhost:$PORT."
    echo "⚠️ The tunnel forwards the TCP page/signaling traffic; WebRTC video may require additional network connectivity."
    echo "💡 To stop, run this script again with the same port (-p $PORT)."
fi
