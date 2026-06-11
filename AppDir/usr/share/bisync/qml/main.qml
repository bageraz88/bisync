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
