import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Item { height: Kirigami.Units.smallSpacing }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 4

        StatRow {
            label: "Total:"
            value: root.ramTotal > 0 ? (root.ramTotal/1024).toFixed(2) + " GB" : "..."
        }
        StatRow {
            label: "Used:"
            value: root.ramUsed > 0 ? (root.ramUsed/1024).toFixed(2) + " GB" : "..."
        }
        StatRow {
            label: "Free:"
            value: root.ramFree > 0 ? (root.ramFree/1024).toFixed(2) + " GB" : "..."
        }
        StatRow {
            label: "Cached:"
            value: root.ramCached > 0 ? (root.ramCached/1024).toFixed(2) + " GB" : "..."
        }
    }

    // RAM bar
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 16

        Rectangle {
            anchors.fill: parent
            color: root.themeTrackColor
            radius: 4

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1
                width: root.ramTotal > 0 ? (parent.width - 2) * (root.ramUsed / root.ramTotal) : 0
                color: root.ramUsed/root.ramTotal > 0.85 ? "#ff4444" : "#00aaff"
                radius: 3

                Behavior on width { NumberAnimation { duration: 300 } }
            }

            Text {
                anchors.centerIn: parent
                text: root.ramTotal > 0 ? (root.ramUsed/root.ramTotal*100).toFixed(0) + "%" : ""
                color: root.themeBarLabelColor
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    // Swap
    PlasmaComponents.Label {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        text: "Swap"
        font.bold: true
        font.pixelSize: 11
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 4

        StatRow {
            label: "Total:"
            value: root.swapTotal > 0 ? (root.swapTotal/1024).toFixed(2) + " GB" : "None"
        }
        StatRow {
            label: "Used:"
            value: root.swapUsed > 0 ? (root.swapUsed/1024).toFixed(2) + " GB" : "0 GB"
        }
    }

    Item {
        visible: root.swapTotal > 0
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 16

        Rectangle {
            anchors.fill: parent
            color: root.themeTrackColor
            radius: 4

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1
                width: root.swapTotal > 0 ? (parent.width - 2) * (root.swapUsed / root.swapTotal) : 0
                color: "#ffaa00"
                radius: 3
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    Item { height: Kirigami.Units.smallSpacing }
}
