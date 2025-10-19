#!/usr/bin/env bash
set -euo pipefail

log() { echo "[`date '+%F %T'`] $*"; }

prepare_vnc_passwd() {
su - chrome -c "mkdir -p ~/.vnc"
local pass="${VNC_PASSWORD:-changeme}"
log "Prepare VNC password for user chrome"
su - chrome -c "echo ${pass} | vncpasswd -f > ~/.vnc/passwd"
su - chrome -c "chmod 600 ~/.vnc/passwd"
}

start_desktop() {
: "${GEOMETRY:=1360x768}"
: "${NOVNC_PORT:=6080}"
: "${START_URL:=}"

log "Start desktop mode (noVNC) port=${NOVNC_PORT} geometry=${GEOMETRY}"
mkdir -p /data/profile /data/output
chmod -R 777 /data

prepare_vnc_passwd

# xstartup under user chrome
su - chrome -c "cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh
xrdb $HOME/.Xresources
openbox-session &
if [ -n "$START_URL" ]; then
google-chrome --no-sandbox --disable-dev-shm-usage --disable-gpu "$START_URL" &
fi
EOF
chmod +x ~/.vnc/xstartup"

# VNC :1 -> 5901
su - chrome -c "vncserver -localhost no -geometry ${GEOMETRY} :1"

log "Start noVNC on http://0.0.0.0:${NOVNC_PORT}"
websockify --web=/usr/share/novnc/ ${NOVNC_PORT} localhost:5901 &

tail -f /home/chrome/.vnc/*:1.log
}

start_script() {
log "Start script mode"
mkdir -p /data/profile /data/output
chmod -R 777 /data
exec python3 /app/main.py
}

MODE="${MODE:-script}"
if [ "${MODE}" = "desktop" ]; then
start_desktop
else
start_script
fi
