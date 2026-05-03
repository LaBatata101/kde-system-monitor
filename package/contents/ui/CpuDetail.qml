import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: cpuDetailRoot

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    readonly property int axisLabelGap: 2
    readonly property int axisLabelWidth: axisLabelSizer.implicitWidth

    function showCoreInfoPopup() {
        coreInfoCloseTimer.stop()
        var pos = cpuHistoryArea.mapToGlobal(Qt.point(cpuHistoryArea.width + Kirigami.Units.smallSpacing, 0))
        coreInfoWindow.x = pos.x
        coreInfoWindow.y = pos.y
        coreInfoWindow.visible = true
    }

    function scheduleCoreInfoPopupClose() {
        coreInfoCloseTimer.restart()
    }

    function updateCoreInfoPopup() {
        if (cpuHistoryHover.hovered || coreInfoPopupHover.hovered) {
            showCoreInfoPopup()
        } else {
            scheduleCoreInfoPopupClose()
        }
    }

    Text {
        id: axisLabelSizer
        visible: false
        text: "100%"
        font.pixelSize: 10
    }

    // CPU Model
    PlasmaComponents.Label {
        Layout.fillWidth: true
        text: root.cpuModel || "CPU"
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 11
    }

    // Overall stats
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            StatRow { label: "Total:"; value: root.cpuTotal.toFixed(0) + "%" }
            StatRow { label: "User:"; value: root.cpuUser.toFixed(0) + "%" }
            StatRow { label: "System:"; value: root.cpuSystem.toFixed(0) + "%" }
        }
    }

    // Overall usage
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        Layout.preferredHeight: 16
        Layout.minimumHeight: 16

        readonly property int rightInset: axisLabelWidth + axisLabelGap

        Rectangle {
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - parent.rightInset)
            height: 6
            radius: 3
            color: root.themeTrackColor

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, root.cpuTotal / 100))
                height: parent.height
                radius: 3
                color: root.cpuTotal > 80 ? "#ff4444" : "#00aaff"
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }

        PlasmaComponents.Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: axisLabelWidth
            text: root.cpuTotal.toFixed(0) + "%"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
        }
    }

    // CPU History Graph
    ColumnLayout {
        id: cpuHistoryArea

        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 2

        HoverHandler {
            id: cpuHistoryHover
            onHoveredChanged: updateCoreInfoPopup()
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            Layout.minimumHeight: 58

            Rectangle {
                anchors.fill: parent
                anchors.margins: -Math.round(Kirigami.Units.smallSpacing / 2)
                radius: 4
                color: cpuHistoryHover.hovered ? root.themeHoverColor : "transparent"
            }

            Canvas {
                id: cpuGraph
                anchors.fill: parent
                property color themeTextColor: Kirigami.Theme.textColor

                onThemeTextColorChanged: requestPaint()

                Connections {
                    target: root
                    function onCpuHistoryChanged() { cpuGraph.requestPaint() }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    var rightInset = axisLabelWidth + axisLabelGap
                    var plotWidth = Math.max(0, width - rightInset)
                    ctx.clearRect(0, 0, width, height)

                    // Background
                    ctx.fillStyle = root.themeGraphBackgroundColor
                    ctx.fillRect(0, 0, plotWidth, height)

                    // Grid lines
                    ctx.strokeStyle = root.themeGraphGridColor
                    ctx.lineWidth = 1
                    for (var g = 0.25; g <= 1.0; g += 0.25) {
                        ctx.beginPath()
                        ctx.moveTo(0, height * (1 - g))
                        ctx.lineTo(plotWidth, height * (1 - g))
                        ctx.stroke()
                    }

                    var history = root.cpuHistory
                    if (history.length < 2) return

                    // Fill area
                    ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2)
                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    for (var i = 0; i < history.length; i++) {
                        var x = i / (history.length - 1) * plotWidth
                        var y = height - history[i] * height
                        ctx.lineTo(x, y)
                    }
                    ctx.lineTo(plotWidth, height)
                    ctx.closePath()
                    ctx.fill()

                    // Line
                    ctx.strokeStyle = "#00aaff"
                    ctx.lineWidth = 1.5
                    ctx.beginPath()
                    for (var j = 0; j < history.length; j++) {
                        var x2 = j / (history.length - 1) * plotWidth
                        var y2 = height - history[j] * height
                        if (j === 0) ctx.moveTo(x2, y2)
                        else ctx.lineTo(x2, y2)
                    }
                    ctx.stroke()
                }
            }

            ColumnLayout {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: axisLabelWidth

                Text {
                    Layout.fillWidth: true
                    text: "100%"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
                Item { Layout.fillHeight: true }
                Text {
                    Layout.fillWidth: true
                    text: "50%"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
                Item { Layout.fillHeight: true }
                Text {
                    Layout.fillWidth: true
                    text: "0%"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                Layout.minimumHeight: 10

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -Math.round(Kirigami.Units.smallSpacing / 2)
                    anchors.rightMargin: -Math.round(Kirigami.Units.smallSpacing / 2)
                    radius: 4
                    color: cpuHistoryHover.hovered ? root.themeHoverColor : "transparent"
                }

                Text {
                    anchors.left: parent.left
                    text: "5 mins ago"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: axisLabelWidth + axisLabelGap
                    text: "now"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                }
            }
        }
    }

    // Top Processes
    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Top processes"
        font.bold: true
        font.pixelSize: 12
    }

    Repeater {
        model: root.topProcesses.length
        delegate: RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            readonly property var processInfo: root.topProcesses[index] || ({ name: "", cpu: 0 })

            PlasmaComponents.Label {
                text: processInfo.name
                Layout.fillWidth: true
                font.bold: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                text: processInfo.cpu.toFixed(1) + "%"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    // GPUs
    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "GPUs"
        font.bold: true
        font.pixelSize: 12
        visible: root.gpus.length > 0
    }

    Repeater {
        model: root.gpus
        delegate: PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            text: modelData
            font.pixelSize: 10
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // System Uptime
    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "System uptime"
        font.bold: true
        font.pixelSize: 11
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: root.systemUptime || "..."
        font.pixelSize: 10
    }

    Window {
        id: coreInfoWindow

        width: Math.max(Kirigami.Units.gridUnit * 16,
                        cpuDetailRoot.width - Kirigami.Units.smallSpacing * 2)
        height: Math.min(coreInfoContent.implicitHeight + Kirigami.Units.smallSpacing * 2,
                         Kirigami.Units.gridUnit * 18)
        visible: false
        flags: Qt.ToolTip | Qt.FramelessWindowHint
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            border.color: root.themeBorderColor
            border.width: 1
            radius: 4
        }

        CpuCoreInfo {
            id: coreInfoContent
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing

            HoverHandler {
                id: coreInfoPopupHover
                onHoveredChanged: updateCoreInfoPopup()
            }
        }
    }

    Timer {
        id: coreInfoCloseTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (!cpuHistoryHover.hovered && !coreInfoPopupHover.hovered) {
                coreInfoWindow.visible = false
            }
        }
    }
}
