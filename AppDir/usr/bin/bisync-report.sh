#!/bin/bash
ARCHIVE_DIR="$HOME/.local/share/rclone-bisync/archive"
CSVFILE="$HOME/.local/share/rclone-bisync/weekly-report.csv"

mkdir -p "$ARCHIVE_DIR"
echo "Date,Synced,Deleted,Conflicts" > "$CSVFILE"

for FILE in "$ARCHIVE_DIR"/bisync-*.log; do
    DATE=$(basename "$FILE" | cut -d'-' -f2-4 | cut -d'.' -f1)
    SYNCED=$(grep -oP 'Copied:\s+\K\d+' "$FILE" | tail -n1)
    DELETED=$(grep -oP 'Deleted:\s+\K\d+' "$FILE" | tail -n1)
    CONFLICTS=$(grep -oP 'Conflicts:\s+\K\d+' "$FILE" | tail -n1)
    echo "$DATE,${SYNCED:-0},${DELETED:-0},${CONFLICTS:-0}" >> "$CSVFILE"
done

column -t -s, "$CSVFILE"
echo "✅ CSV report saved to $CSVFILE"
