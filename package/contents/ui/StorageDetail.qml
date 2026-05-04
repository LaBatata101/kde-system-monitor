import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Item { height: Kirigami.Units.smallSpacing }

    Repeater {
        model: root.storageDevices

        delegate: ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    text: modelData.mount
                    font.bold: true
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }
                PlasmaComponents.Label {
                    text: modelData.used + " / " + modelData.size
                    font.pixelSize: 10
                }
            }

            PlasmaComponents.Label {
                text: modelData.device
                font.pixelSize: 9
                font.italic: true
                color: Kirigami.Theme.disabledTextColor
            }

            Item {
                Layout.fillWidth: true
                height: 14

                Rectangle {
                    anchors.fill: parent
                    color: root.themeTrackColor
                    radius: 3

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 1
                        width: (parent.width - 2) * (modelData.percent / 100)
                        color: modelData.percent > 85 ? "#ff4444" : modelData.percent > 70 ? "#ffaa00" : "#00aaff"
                        radius: 2
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.percent + "%"
                        color: root.themeBarLabelColor
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            Item { height: 2 }
        }
    }

    PlasmaComponents.Label {
        visible: root.storageDevices.length === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "No storage devices found"
        font.italic: true
        font.pixelSize: 11
    }

    Item { height: Kirigami.Units.smallSpacing }
}
