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
