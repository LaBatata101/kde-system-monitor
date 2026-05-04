import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: coreInfo

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "CPU Core Info"
        font.bold: true
        font.pixelSize: 11
    }

    GridView {
        id: coresGrid
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: Math.max(82, Math.ceil(root.cpuCores.length / 8) * 82)
        cellWidth: width / Math.min(8, root.cpuCores.length > 0 ? root.cpuCores.length : 8)
        cellHeight: 82
        model: root.cpuCores
        interactive: false

        delegate: Item {
            width: coresGrid.cellWidth
            height: coresGrid.cellHeight

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 1

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: modelData.name.replace("cpu", "Core")
                    font.pixelSize: 8
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.fill: parent
                        color: root.themeFaintTrackColor
                        radius: 2

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: (parent.height - 2) * (modelData.user / 100)
                            color: "#00aaff"
                            radius: 1
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: (parent.height - 2) * (modelData.system / 100)
                            color: "#ff4444"
                            radius: 1
                        }
                    }
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: modelData.usage.toFixed(1) + "%"
                    font.pixelSize: 8
                    horizontalAlignment: Text.AlignHCenter
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.cpuCoreClockText(modelData.name)
                    visible: text.length > 0
                    font.pixelSize: 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }
    }
}
