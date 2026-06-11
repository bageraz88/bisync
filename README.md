# THIS PROJECT NOT YET TESTED - THIS LINE WILL BE DELETE ONCE TESTED

# 📦 Bisync Control Center (AppImage)

A **portable desktop app** for managing [rclone bisync](https://rclone.org/bisync/) with automation, reporting, and a friendly GUI.  
This repository includes all scripts required to build an AppImage, run a GUI and CLI, rotate and archive logs, and generate weekly reports.

---

## 🚀 Quick Start

    # 1. Prepare AppDir
    ./setup-bisync.sh

    # 2. Build AppImage
    ./build-appimage.sh

    # 3. Run Bisync
    chmod +x Bisync-x86_64.AppImage
    ./Bisync-x86_64.AppImage

---

## 📂 Directory Layout

    AppDir/
     ├── AppRun
     ├── bisync.desktop
     ├── bisync.png
     └── usr/
          ├── bin/
          │    ├── bisync-status.sh
          │    ├── bisync-report.sh
          │    ├── bisync-logrotate.sh
          │    ├── bisync-logarchive.sh
          │    ├── bisync-archive-viewer.sh
          │    └── bisync-checkconflicts.sh
          └── share/
               └── bisync/
                    └── qml/
                         └── main.qml

---

## 🛠️ Scripts

Below are the **full scripts** included in this project. Copy each into the appropriate file under `AppDir/` or `AppDir/usr/bin/` and make them executable.

### setup-bisync.sh

    #!/usr/bin/env bash
    set -euo pipefail

    # Creates AppDir layout and copies scripts, desktop file, icons, and QML
    APPDIR="AppDir"
    BIN_DIR="$APPDIR/usr/bin"
    SHARE_DIR="$APPDIR/usr/share/bisync"
    QML_DIR="$SHARE_DIR/qml"

    rm -rf "$APPDIR"
    mkdir -p "$BIN_DIR" "$QML_DIR"

    # Copy scripts (assumes this script is run from repo root where scripts live)
    cp ./scripts/bisync-status.sh "$BIN_DIR/"
    cp ./scripts/bisync-report.sh "$BIN_DIR/"
    cp ./scripts/bisync-logrotate.sh "$BIN_DIR/"
    cp ./scripts/bisync-logarchive.sh "$BIN_DIR/"
    cp ./scripts/bisync-archive-viewer.sh "$BIN_DIR/"
    cp ./scripts/bisync-checkconflicts.sh "$BIN_DIR/"

    # Install AppRun, desktop file, and icons
    cp ./packaging/AppRun "$APPDIR/"
    cp ./packaging/bisync.desktop "$APPDIR/"
    cp ./assets/bisync.png "$APPDIR/"
    cp ./assets/bisync.svg "$APPDIR/"

    # Install QML frontend
    cp ./qml/main.qml "$QML_DIR/"

    # Make binaries executable
    chmod +x "$BIN_DIR"/*.sh
    chmod +x "$APPDIR/AppRun"

    echo "AppDir prepared at $APPDIR"

---

### AppRun

    #!/usr/bin/env bash
    # Smart launcher: choose GUI or CLI based on environment or flags

    set -euo pipefail

    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
    BIN_DIR="$SCRIPT_DIR/usr/bin"

    show_help() {
      cat <<EOF
    Bisync AppImage launcher

    Usage:
      --gui     Force GUI mode
      --cli     Force CLI mode
      --help    Show this help
    EOF
    }

    # Parse flags
    MODE=""
    for arg in "$@"; do
      case "$arg" in
        --gui) MODE="gui" ;;
        --cli) MODE="cli" ;;
        --help) show_help; exit 0 ;;
      esac
    done

    # If not forced, detect whether running in a terminal
    if [ -z "$MODE" ]; then
      if [ -t 1 ]; then
        MODE="cli"
      else
        MODE="gui"
      fi
    fi

    if [ "$MODE" = "cli" ]; then
      exec "$BIN_DIR/bisync-status.sh" "$@"
    else
      # Launch QML GUI
      QML="$SCRIPT_DIR/usr/share/bisync/qml/main.qml"
      if command -v qmlscene >/dev/null 2>&1; then
        exec qmlscene "$QML"
      elif command -v qml >/dev/null 2>&1; then
        exec qml "$QML"
      else
        echo "GUI runtime not found. Install Qt Quick (qmlscene) or run with --cli." >&2
        exit 1
      fi
    fi

---

### build-appimage.sh

    #!/usr/bin/env bash
    set -euo pipefail

    # Build AppImage with fixed filename
    if ! command -v appimagetool >/dev/null 2>&1; then
      echo "appimagetool not found. Install AppImageKit to build." >&2
      exit 1
    fi

    appimagetool AppDir Bisync-x86_64.AppImage
    echo "✅ Build complete: Bisync-x86_64.AppImage"

---

### bisync-status.sh

    #!/usr/bin/env bash
    # Check bisync status and output JSON summary
    set -euo pipefail

    LOG_DIR="${HOME}/.local/share/bisync/logs"
    LAST_LOG="$(ls -1t "$LOG_DIR" 2>/dev/null | head -n1 || true)"
    CONFLICTS=0

    # Example: parse last log for conflict lines
    if [ -n "$LAST_LOG" ] && [ -f "$LOG_DIR/$LAST_LOG" ]; then
      CONFLICTS=$(grep -c "CONFLICT" "$LOG_DIR/$LAST_LOG" || true)
    fi

    jq -n \
      --arg last_log "$LAST_LOG" \
      --argjson conflicts "$CONFLICTS" \
      '{last_log: $last_log, conflicts: $conflicts, status: (if $conflicts|tonumber > 0 then "conflicts" else "ok" end)}'

> Note: `jq` is used here to produce JSON. Install `jq` or replace with another formatter if needed.

---

### bisync-report.sh

    #!/usr/bin/env bash
    # Generate weekly CSV report from logs
    set -euo pipefail

    LOG_DIR="${HOME}/.local/share/bisync/logs"
    REPORT_DIR="${HOME}/.local/share/bisync/reports"
    mkdir -p "$REPORT_DIR"

    OUT="$REPORT_DIR/bisync-weekly-$(date +%Y-%m-%d).csv"
    echo "date,operation,files_changed,conflicts" > "$OUT"

    # Simple parser: expects lines like "YYYY-MM-DD OP files=X conflicts=Y"
    for f in "$LOG_DIR"/*; do
      awk '/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
        date=$1; op=$2;
        files=0; conflicts=0;
        for(i=3;i<=NF;i++){
          if ($i ~ /^files=/) { split($i,a,"="); files=a[2] }
          if ($i ~ /^conflicts=/) { split($i,b,"="); conflicts=b[2] }
        }
        print date","op","files","conflicts
      }' "$f" >> "$OUT" || true
    done

    echo "Report written to $OUT"

---

### bisync-logrotate.sh

    #!/usr/bin/env bash
    # Rotate logs older than 30 days
    set -euo pipefail

    LOG_DIR="${HOME}/.local/share/bisync/logs"
    mkdir -p "$LOG_DIR"
    find "$LOG_DIR" -type f -mtime +30 -print -delete
    echo "Old logs rotated"

---

### bisync-logarchive.sh

    #!/usr/bin/env bash
    # Archive weekly logs into compressed tarball
    set -euo pipefail

    LOG_DIR="${HOME}/.local/share/bisync/logs"
    ARCHIVE_DIR="${HOME}/.local/share/bisync/archives"
    mkdir -p "$ARCHIVE_DIR"

    TS=$(date +%Y%m%d)
    tar -czf "$ARCHIVE_DIR/bisync-logs-$TS.tar.gz" -C "$LOG_DIR" .
    echo "Archived logs to $ARCHIVE_DIR/bisync-logs-$TS.tar.gz"

---

### bisync-archive-viewer.sh

    #!/usr/bin/env bash
    # Simple archive viewer: list and extract archives
    set -euo pipefail

    ARCHIVE_DIR="${HOME}/.local/share/bisync/archives"
    case "${1:-list}" in
      list)
        ls -1 "$ARCHIVE_DIR"
        ;;
      show)
        tar -tzf "$ARCHIVE_DIR/$2"
        ;;
      extract)
        mkdir -p ./bisync-archive-extract
        tar -xzf "$ARCHIVE_DIR/$2" -C ./bisync-archive-extract
        echo "Extracted to ./bisync-archive-extract"
        ;;
      *)
        echo "Usage: $0 {list|show <archive>|extract <archive>}"
        ;;
    esac

---

### bisync-checkconflicts.sh

    #!/usr/bin/env bash
    # Count conflicts across logs
    set -euo pipefail

    LOG_DIR="${HOME}/.local/share/bisync/logs"
    grep -h "CONFLICT" "$LOG_DIR"/* 2>/dev/null | wc -l

---

### main.qml (placeholder)

    import QtQuick 2.12
    import QtQuick.Controls 2.5

    ApplicationWindow {
      visible: true
      width: 640
      height: 480
      title: "Bisync Control Center"

      Column {
        anchors.centerIn: parent
        spacing: 12

        Button {
          text: "Status"
          onClicked: Qt.openUrlExternally("bisync://status")
        }

        Button {
          text: "Weekly Report"
          onClicked: Qt.openUrlExternally("bisync://report")
        }

        Button {
          text: "Archive Viewer"
          onClicked: Qt.openUrlExternally("bisync://archive")
        }
      }
    }

---

### bisync.desktop

    [Desktop Entry]
    Name=Bisync Control Center
    Comment=Manage rclone bisync with GUI and automation
    Exec=Bisync-x86_64.AppImage --gui
    Icon=bisync
    Terminal=false
    Type=Application
    Categories=Utility;System;

---

## 🚀 Usage

    # Build and run
    ./setup-bisync.sh
    ./build-appimage.sh
    chmod +x Bisync-x86_64.AppImage
    ./Bisync-x86_64.AppImage

    # Force CLI
    ./Bisync-x86_64.AppImage --cli

    # Force GUI
    ./Bisync-x86_64.AppImage --gui

---

## 📜 License

This project is licensed under the **MIT License**. Add a `LICENSE` file with the standard MIT text and your copyright.

---

## 🤝 Contributing

See `CONTRIBUTING.md` for contribution guidelines. Fork, create a branch, test changes, and open a pull request.
