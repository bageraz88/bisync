#!/bin/bash
LOGFILE="$HOME/.local/share/rclone-bisync.log"
MAXLINES=500
tail -n $MAXLINES "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
