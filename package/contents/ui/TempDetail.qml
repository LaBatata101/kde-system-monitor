pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: tempDetailRoot

    required property var parentRef

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Item {
        height: Kirigami.Units.smallSpacing
    }

    Repeater {
        model: tempDetailRoot.parentRef.temperatures

        delegate: RowLayout {
            id: temperatureRow

            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            SvgIcon {
                name: "am-temperature-symbolic"
                width: 12
                height: 12
            }

            PlasmaComponents.Label {
                text: temperatureRow.modelData.label
                Layout.fillWidth: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            // Temp bar
            Item {
                id: temperatureBar

                width: 60
                height: 12

                Rectangle {
                    id: temperatureTrack

                    anchors.fill: temperatureBar
                    color: tempDetailRoot.parentRef.themeTrackColor
                    radius: 3

                    Rectangle {
                        anchors.left: temperatureTrack.left
                        anchors.top: temperatureTrack.top
                        anchors.bottom: temperatureTrack.bottom
                        anchors.margins: 1
                        width: (temperatureTrack.width - 2) * Math.min(1, temperatureRow.modelData.value / 110)
                        color: temperatureRow.modelData.value > 90 ? "#ff4444" : temperatureRow.modelData.value > 75 ? "#ffaa00" : "#00aaff"
                        radius: 2

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                            }
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                text: temperatureRow.modelData.value.toFixed(1) + " °C"
                font.pixelSize: 11
                font.bold: true
                color: {
                    if (temperatureRow.modelData.value > 90)
                        return "#ff4444";

                    if (temperatureRow.modelData.value > 75)
                        return "#ffaa00";

                    return Kirigami.Theme.textColor;
                }
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 55
            }
        }
    }

    PlasmaComponents.Label {
        visible: tempDetailRoot.parentRef.temperatures.length === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Install lm-sensors for temperature data"
        font.italic: true
        font.pixelSize: 10
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }
}
