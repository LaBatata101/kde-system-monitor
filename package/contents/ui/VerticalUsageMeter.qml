import QtQuick

Item {
    id: meter

    property real value: 0
    property real warningThreshold: 0.7
    property real criticalThreshold: 0.85
    property color normalColor: "#00aaff"
    property color warningColor: "#ffaa00"
    property color criticalColor: "#ff4444"
    property color trackColor: "transparent"
    property color borderColor: "transparent"
    property bool showBorder: true
    property int minimumFillHeight: 0
    readonly property real clampedValue: Math.max(0, Math.min(1, meter.value))
    readonly property color fillColor: meter.clampedValue > meter.criticalThreshold ? meter.criticalColor : meter.clampedValue > meter.warningThreshold ? meter.warningColor : meter.normalColor

    Rectangle {
        id: meterTrack

        anchors.fill: meter
        color: meter.trackColor
        border.color: meter.showBorder ? meter.borderColor : "transparent"
        border.width: meter.showBorder ? 1 : 0
        radius: 2

        Rectangle {
            anchors.bottom: meterTrack.bottom
            anchors.left: meterTrack.left
            anchors.right: meterTrack.right
            anchors.margins: meter.showBorder ? 1 : 0
            height: {
                let availableHeight = meterTrack.height - (meter.showBorder ? 2 : 0);
                if (meter.clampedValue <= 0)
                    return 0;

                return Math.max(meter.minimumFillHeight, availableHeight * meter.clampedValue);
            }
            color: meter.fillColor
            radius: 1

            Behavior on height {
                NumberAnimation {
                    duration: 300
                }
            }
        }
    }
}
