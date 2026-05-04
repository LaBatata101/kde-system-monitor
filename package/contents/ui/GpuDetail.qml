import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: gpuDetailRoot

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    readonly property int axisLabelGap: 2
    readonly property int axisLabelWidth: axisLabelSizer.implicitWidth

    Text {
        id: axisLabelSizer
        visible: false
        text: "100%"
        font.pixelSize: 10
    }

    Item { height: Kirigami.Units.smallSpacing }

    Repeater {
        model: root.gpuDevices.length > 0 ? root.gpuDevices : [{ name: root.gpuNameText(), usage: root.gpuUsage, clockMHz: root.gpuClockMHz, temperature: root.gpuTemperature, memoryUsedMiB: root.gpuMemoryUsedMiB, memoryTotalMiB: root.gpuMemoryTotalMiB, history: root.gpuHistory }]

        delegate: ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: 2

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: modelData.name
                font.pixelSize: 11
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            StatRow { label: "Clock:"; value: root.gpuDeviceClockText(modelData) }
            StatRow { label: "Memory:"; value: root.gpuDeviceMemoryText(modelData) }
            StatRow { label: "Temperature:"; value: root.gpuDeviceTemperatureText(modelData) }
            StatRow { label: "Usage:"; value: root.gpuDeviceUsageText(modelData) }

            Item {
                Layout.fillWidth: true
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
                        width: parent.width * Math.min(1, Math.max(0, (modelData.usage || 0) / 100))
                        height: parent.height
                        radius: 3
                        color: (modelData.usage || 0) > 85 ? "#ff4444" : "#00aaff"
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                PlasmaComponents.Label {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: axisLabelWidth
                    text: (modelData.usage || 0).toFixed(0) + "%"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                Layout.minimumHeight: 80

                Canvas {
                    id: gpuGraph
                    anchors.fill: parent
                    property color themeTextColor: Kirigami.Theme.textColor

                    onThemeTextColorChanged: requestPaint()

                    Connections {
                        target: root
                        function onGpuDevicesChanged() { gpuGraph.requestPaint() }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        var rightInset = axisLabelWidth + axisLabelGap
                        var plotWidth = Math.max(0, width - rightInset)
                        ctx.clearRect(0, 0, width, height)

                        ctx.fillStyle = root.themeGraphBackgroundColor
                        ctx.fillRect(0, 0, plotWidth, height)

                        ctx.strokeStyle = root.themeGraphGridColor
                        ctx.lineWidth = 1
                        for (var g = 0.25; g <= 1.0; g += 0.25) {
                            ctx.beginPath()
                            ctx.moveTo(0, height * (1 - g))
                            ctx.lineTo(plotWidth, height * (1 - g))
                            ctx.stroke()
                        }

                        ctx.strokeStyle = root.themeBorderColor
                        ctx.lineWidth = 1
                        ctx.strokeRect(0.5, 0.5, plotWidth - 1, height - 1)

                        var history = modelData.history || []
                        if (history.length < 2) return

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

                Text {
                    Layout.fillWidth: true
                    text: "GPU usage history"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                }

                Rectangle { width: 12; height: 3; color: "#00aaff"; radius: 1 }
                PlasmaComponents.Label { text: "Usage"; font.pixelSize: 10 }
            }
        }
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Top GPU processes"
        font.bold: true
        font.pixelSize: 12
    }

    Repeater {
        model: root.gpuProcesses
        delegate: RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: modelData.name
                Layout.fillWidth: true
                font.bold: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            PlasmaComponents.Label {
                text: root.formatMemoryMib(modelData.memoryMiB)
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Item { height: Kirigami.Units.smallSpacing }
}
