#!/bin/bash
LOGFILE="$HOME/.local/share/rclone-bisync.log"
STATUSFILE="$HOME/.local/share/rclone-bisync-status.json"

CONFLICTS=$(grep -oP 'Conflicts:\s+\K\d+' "$LOGFILE" | tail -n1)
COPIED=$(grep -oP 'Copied:\s+\K\d+' "$LOGFILE" | tail -n1)
DELETED=$(grep -oP 'Deleted:\s+\K\d+' "$LOGFILE" | tail -n1)

jq -n --arg conflicts "$CONFLICTS" --arg copied "$COPIED" --arg deleted "$DELETED" \
  '{conflicts: ($conflicts|tonumber), copied: ($copied|tonumber), deleted: ($deleted|tonumber)}' > "$STATUSFILE"

cat "$STATUSFILE"
