> [!NOTE]
> FEEL FREE TO IMPROVE THE SCRIPTS

> [!WARNING]
> ALL SCRIPTS ARE **NOT TESTED YET**

> [!CAUTION]
> THIS PROJECT NOT YET FINAL

# 📦 Bisync Control Center (AppImage)

A **portable desktop app** for managing [rclone bisync](https://rclone.org/bisync/) with automation, reporting, and a friendly GUI.  
This repository includes all scripts required to build an AppImage, run a GUI and CLI, rotate and archive logs, and generate weekly reports.

<details>
<summary>
🚀 Quick Start
</summary>

    # 1. Prepare AppDir
    ./setup-bisync.sh

    # 2. Build AppImage
    ./build-appimage.sh

    # 3. Run Bisync
    chmod +x Bisync-x86_64.AppImage
    ./Bisync-x86_64.AppImage
	
</details>

<details>
<summary>
📂 Directory Layout
</summary>

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
	
</details>

## 🛠️ Scripts

Below are the **full scripts** included in this project. Copy each into the appropriate file under `AppDir/` or `AppDir/usr/bin/` and make them executable.

### 🛠📂 AppDir/

<details>
<summary>
bisync.desktop
</summary>

	[Desktop Entry]
	Name=Bisync Control Center
	Exec=bisync-status.sh
	Icon=bisync
	Type=Application
	Categories=Utility;System;
	Comment=Rclone Bisync Control Center with automation and reporting
	
</details>

<details>
<summary>
setup-bisync.sh
</summary>

	#!/bin/bash
	# Bisync AppImage setup script

	# Create directory structure
	mkdir -p AppDir/usr/bin AppDir/usr/share/bisync/qml

	# Copy backend scripts (assuming they’re in ./scripts/)
	cp scripts/bisync-*.sh AppDir/usr/bin/

	# Create main.qml
	cat > AppDir/usr/share/bisync/qml/main.qml <<'EOF'
	import QtQuick 2.15
	import QtQuick.Controls 2.15
	import QtQuick.Dialogs 1.3

	ApplicationWindow {
		visible: true
		width: 500
		height: 400
		title: "Bisync Control Center"

		MessageDialog {
			id: conflictDialog
			title: "⚠ Conflicts Detected"
			text: ""   // set dynamically
			icon: StandardIcon.Warning
			visible: false
			onAccepted: conflictDialog.visible = false
		}

		MessageDialog {
			id: clearDialog
			title: "✅ All Clear"
			text: "No conflicts detected. Sync is healthy."
			icon: StandardIcon.Information
			visible: false
			onAccepted: clearDialog.visible = false
		}

		Column {
			anchors.centerIn: parent
			spacing: 20

			Label {
				text: "Rclone Bisync Status"
				font.pixelSize: 20
				horizontalAlignment: Text.AlignHCenter
			}

			Button { text: "Check Status"; onClicked: Qt.openUrlExternally("bash -c '~/bin/bisync-status.sh'") }
			Button { text: "View Report"; onClicked: Qt.openUrlExternally("bash -c '~/bin/bisync-report.sh'") }
			Button { text: "Archive Viewer"; onClicked: Qt.openUrlExternally("bash -c '~/bin/bisync-archive-viewer.sh'") }
			Button { text: "Exit"; onClicked: Qt.quit() }
		}

		Component.onCompleted: {
			var conflicts = Qt.openUrlExternally("bash -c '~/bin/bisync-checkconflicts.sh'")
			conflictDialog.text = "⚠ " + conflicts + " conflicts detected. Please check the logs."
			if (conflicts > 0) conflictDialog.visible = true
			else clearDialog.visible = true
		}
	}
	EOF

	# Create AppRun
	cat > AppDir/AppRun <<'EOF'
	#!/bin/bash
	APPDIR="$(dirname "$(readlink -f "$0")")"

	show_help() {
		echo "Bisync Control Center (AppImage)"
		echo
		echo "Usage:"
		echo "  ./Bisync-x86_64.AppImage [options]"
		echo
		echo "Options:"
		echo "  --gui       Force launch in GUI mode"
		echo "  --cli       Force launch in CLI mode"
		echo "  --help      Show this help message"
		echo
		echo "Default behavior:"
		echo "  - Terminal → CLI mode"
		echo "  - Desktop → GUI mode"
		exit 0
	}

	for arg in "$@"; do
		case "$arg" in
			--gui) exec qmlscene "$APPDIR/usr/share/bisync/qml/main.qml" ;;
			--cli) exec "$APPDIR/usr/bin/bisync-status.sh" "${@:2}" ;;
			--help) show_help ;;
		esac
	done

	if [ -t 1 ]; then
		exec "$APPDIR/usr/bin/bisync-status.sh" "$@"
	else
		exec qmlscene "$APPDIR/usr/share/bisync/qml/main.qml"
	fi
	EOF
	chmod +x AppDir/AppRun

	# Create bisync.desktop
	cat > AppDir/bisync.desktop <<'EOF'
	[Desktop Entry]
	Name=Bisync Control Center
	Exec=AppRun
	Icon=bisync
	Type=Application
	Categories=Utility;System;
	Comment=Rclone Bisync Control Center with automation and reporting
	EOF

	# Copy logo (assuming bisync.png is in ./assets/)
	cp assets/bisync.png AppDir/

	echo "✅ Bisync AppDir fully prepared. Ready for AppImage build."

	
</details>

<details>
<summary>
AppRun
</summary>

	#!/bin/bash
	# AppRun for Bisync Control Center
	# Detects environment and launches GUI or CLI accordingly
	# Supports --gui, --cli, and --help flags

	APPDIR="$(dirname "$(readlink -f "$0")")"

	show_help() {
		echo "Bisync Control Center (AppImage)"
		echo
		echo "Usage:"
		echo "  ./Bisync-x86_64.AppImage [options]"
		echo
		echo "Options:"
		echo "  --gui       Force launch in GUI mode (Qt/QML dashboard)"
		echo "  --cli       Force launch in CLI mode (bisync-status.sh)"
		echo "  --help      Show this help message"
		echo
		echo "Default behavior:"
		echo "  - If launched from terminal → CLI mode"
		echo "  - If launched from desktop → GUI mode"
		exit 0
	}

	# Parse override flags
	for arg in "$@"; do
		case "$arg" in
			--gui)
				exec qmlscene "$APPDIR/usr/share/bisync/qml/main.qml"
				;;
			--cli)
				exec "$APPDIR/usr/bin/bisync-status.sh" "${@:2}"
				;;
			--help)
				show_help
				;;
		esac
	done

	# Auto-detect environment if no override
	if [ -t 1 ]; then
		# Terminal detected → run CLI status tool
		exec "$APPDIR/usr/bin/bisync-status.sh" "$@"
	else
		# No terminal → launch GUI dashboard
		exec qmlscene "$APPDIR/usr/share/bisync/qml/main.qml"
	fi
	
</details>

<details>
<summary>
build-appimage.sh
</summary>

	#!/bin/bash
	# Bisync AppImage build script (simple naming)

	# Build AppImage
	appimagetool AppDir Bisync-x86_64.AppImage

	echo "✅ Build complete: Bisync-x86_64.AppImage"

</details>

### 🛠📂 AppDir/usr/bin/

<details>
<summary>
bisync-status.sh
</summary>

	#!/bin/bash
	LOGFILE="$HOME/.local/share/rclone-bisync.log"
	STATUSFILE="$HOME/.local/share/rclone-bisync-status.json"

	CONFLICTS=$(grep -oP 'Conflicts:\s+\K\d+' "$LOGFILE" | tail -n1)
	COPIED=$(grep -oP 'Copied:\s+\K\d+' "$LOGFILE" | tail -n1)
	DELETED=$(grep -oP 'Deleted:\s+\K\d+' "$LOGFILE" | tail -n1)

	jq -n --arg conflicts "$CONFLICTS" --arg copied "$COPIED" --arg deleted "$DELETED" \
	  '{conflicts: ($conflicts|tonumber), copied: ($copied|tonumber), deleted: ($deleted|tonumber)}' > "$STATUSFILE"

	cat "$STATUSFILE"
	
> Note: `jq` is used here to produce JSON. Install `jq` or replace with another formatter if needed.
	
</details>

<details>
<summary>
bisync-report.sh
</summary>

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
	
</details>

<details>
<summary>
bisync-logrotate.sh
</summary>

	#!/bin/bash
	LOGFILE="$HOME/.local/share/rclone-bisync.log"
	MAXLINES=500
	tail -n $MAXLINES "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
	
</details>

<details>
<summary>
bisync-logarchive.sh
</summary>

	#!/bin/bash
	LOGFILE="$HOME/.local/share/rclone-bisync.log"
	ARCHIVE_DIR="$HOME/.local/share/rclone-bisync/archive"
	MAXLINES=500

	mkdir -p "$ARCHIVE_DIR"
	DATESTAMP=$(date '+%Y-%m-%d')
	cp "$LOGFILE" "$ARCHIVE_DIR/bisync-$DATESTAMP.log"
	tail -n $MAXLINES "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
	
</details>

<details>
<summary>
bisync-archive-viewer.sh
</summary>

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
	
</details>

<details>
<summary>
bisync-checkconflicts.sh
</summary>

	#!/bin/bash
	STATUSFILE="$HOME/.local/share/rclone-bisync-status.json"
	if [ -f "$STATUSFILE" ]; then
		jq -r '.conflicts' "$STATUSFILE"
	else
		echo "0"
	fi
	
</details>

### 🛠📂 AppDir/usr/share/bisync/qml

<details>
<summary>
main.qml
</summary>

	import QtQuick 2.15
	import QtQuick.Controls 2.15
	import QtQuick.Dialogs 1.3

	ApplicationWindow {
		visible: true
		width: 500
		height: 400
		title: "Bisync Control Center"

		MessageDialog {
			id: conflictDialog
			title: "⚠ Conflicts Detected"
			text: ""   // set dynamically
			icon: StandardIcon.Warning
			visible: false
			onAccepted: conflictDialog.visible = false
		}

		MessageDialog {
			id: clearDialog
			title: "✅ All Clear"
			text: "No conflicts detected. Sync is healthy."
			icon: StandardIcon.Information
			visible: false
			onAccepted: clearDialog.visible = false
		}

		Column {
			anchors.centerIn: parent
			spacing: 20

			Label {
				text: "Rclone Bisync Status"
				font.pixelSize: 20
				horizontalAlignment: Text.AlignHCenter
			}

			Button { text: "Check Status"; onClicked: Qt.openUrlExternally("bash -c '~/bin/bisync-status.sh'") }
			Button { text: "View Report"; onClicked: Qt.openUrlExternally("bash -c '~/bin/bisync-report.sh'") }
			Button { text: "Archive Viewer"; onClicked: Qt.openUrlExternally("bash -c '~/bin/bisync-archive-viewer.sh'") }
			Button { text: "Exit"; onClicked: Qt.quit() }
		}

		Component.onCompleted: {
			var conflicts = Qt.openUrlExternally("bash -c '~/bin/bisync-checkconflicts.sh'")
			conflictDialog.text = "⚠ " + conflicts + " conflicts detected. Please check the logs."
			if (conflicts > 0) conflictDialog.visible = true
			else clearDialog.visible = true
		}
	}
	
</details>

## 🚀 Usage

##### Build and run
    ./setup-bisync.sh
    ./build-appimage.sh
    chmod +x Bisync-x86_64.AppImage
    ./Bisync-x86_64.AppImage

##### Force CLI
    ./Bisync-x86_64.AppImage --cli

##### Force GUI
    ./Bisync-x86_64.AppImage --gui

---

## 📜 License

This project is licensed under the **MIT License**. Add a `LICENSE` file with the standard MIT text and your copyright.

---

## 🤝 Contributing

See `CONTRIBUTING.md` for contribution guidelines. Fork, create a branch, test changes, and open a pull request.
