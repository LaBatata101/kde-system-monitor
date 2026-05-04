pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: coreInfo

    required property var parentRef

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
        height: Math.max(82, Math.ceil(coreInfo.parentRef.cpuCores.length / 8) * 82)
        cellWidth: coresGrid.width / Math.min(8, coreInfo.parentRef.cpuCores.length > 0 ? coreInfo.parentRef.cpuCores.length : 8)
        cellHeight: 82
        model: coreInfo.parentRef.cpuCores
        interactive: false

        delegate: Item {
            id: coreDelegate

            required property var modelData

            width: coresGrid.cellWidth
            height: coresGrid.cellHeight

            ColumnLayout {
                anchors.fill: coreDelegate
                anchors.margins: 2
                spacing: 1

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: coreDelegate.modelData.name.replace("cpu", "Core")
                    font.pixelSize: 8
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Item {
                    id: stackedCoreBar

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        id: stackedCoreBarTrack

                        anchors.fill: stackedCoreBar
                        color: coreInfo.parentRef.themeFaintTrackColor
                        radius: 2

                        Rectangle {
                            anchors.bottom: stackedCoreBarTrack.bottom
                            anchors.left: stackedCoreBarTrack.left
                            anchors.right: stackedCoreBarTrack.right
                            anchors.margins: 1
                            height: (stackedCoreBarTrack.height - 2) * (coreDelegate.modelData.user / 100)
                            color: "#00aaff"
                            radius: 1
                        }

                        Rectangle {
                            anchors.bottom: stackedCoreBarTrack.bottom
                            anchors.left: stackedCoreBarTrack.left
                            anchors.right: stackedCoreBarTrack.right
                            anchors.margins: 1
                            height: (stackedCoreBarTrack.height - 2) * (coreDelegate.modelData.system / 100)
                            color: "#ff4444"
                            radius: 1
                        }
                    }
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: coreDelegate.modelData.usage.toFixed(1) + "%"
                    font.pixelSize: 8
                    horizontalAlignment: Text.AlignHCenter
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: coreInfo.parentRef.cpuCoreClockText(coreDelegate.modelData.name)
                    visible: coreInfo.parentRef.cpuCoreClockText(coreDelegate.modelData.name).length > 0
                    font.pixelSize: 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }
    }
}
