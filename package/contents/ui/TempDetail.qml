import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Item {
        height: Kirigami.Units.smallSpacing
    }

    Repeater {
        model: root.temperatures

        delegate: RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            SvgIcon {
                name: "am-temperature-symbolic"
                width: 12
                height: 12
            }

            PlasmaComponents.Label {
                text: modelData.label
                Layout.fillWidth: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            // Temp bar
            Item {
                width: 60
                height: 12

                Rectangle {
                    anchors.fill: parent
                    color: root.themeTrackColor
                    radius: 3

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 1
                        width: (parent.width - 2) * Math.min(1, modelData.value / 110)
                        color: modelData.value > 90 ? "#ff4444" : modelData.value > 75 ? "#ffaa00" : "#00aaff"
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
                text: modelData.value.toFixed(1) + " °C"
                font.pixelSize: 11
                font.bold: true
                color: {
                    if (modelData.value > 90)
                        return "#ff4444";
                    if (modelData.value > 75)
                        return "#ffaa00";
                    return Kirigami.Theme.textColor;
                }
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 55
            }
        }
    }

    PlasmaComponents.Label {
        visible: root.temperatures.length === 0
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
