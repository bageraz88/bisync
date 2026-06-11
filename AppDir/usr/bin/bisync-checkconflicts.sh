#!/bin/bash
STATUSFILE="$HOME/.local/share/rclone-bisync-status.json"
if [ -f "$STATUSFILE" ]; then
    jq -r '.conflicts' "$STATUSFILE"
else
    echo "0"
fi
