#!/bin/bash
ARCHIVE_DIR="$HOME/.local/share/rclone-bisync/archive"
mkdir -p "$ARCHIVE_DIR"

echo "=== Available Bisync Archived Logs ==="
ls -1 "$ARCHIVE_DIR" | sort

echo "Options: 1) View file  2) Search keyword  3) Exit"
read -p "Choose option [1-3]: " CHOICE

case "$CHOICE" in
  1) read -p "Enter filename: " FILE; less "$ARCHIVE_DIR/$FILE" ;;
  2) read -p "Enter keyword: " KEY; grep -H "$KEY" "$ARCHIVE_DIR"/*.log ;;
  *) echo "Exiting." ;;
esac
