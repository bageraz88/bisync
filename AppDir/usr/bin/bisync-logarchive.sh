#!/bin/bash
LOGFILE="$HOME/.local/share/rclone-bisync.log"
ARCHIVE_DIR="$HOME/.local/share/rclone-bisync/archive"
MAXLINES=500

mkdir -p "$ARCHIVE_DIR"
DATESTAMP=$(date '+%Y-%m-%d')
cp "$LOGFILE" "$ARCHIVE_DIR/bisync-$DATESTAMP.log"
tail -n $MAXLINES "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
