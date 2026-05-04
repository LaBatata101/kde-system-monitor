import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    // Padding
    Item { height: Kirigami.Units.smallSpacing }

    // CPU Model
    PlasmaComponents.Label {
        Layout.fillWidth: true
        text: root.cpuModel || "CPU"
        font.italic: true
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

    // CPU History Graph
    Canvas {
        id: cpuGraph
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 80
        property color themeTextColor: Kirigami.Theme.textColor

        onThemeTextColorChanged: requestPaint()

        Connections {
            target: root
            function onCpuHistoryChanged() { cpuGraph.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // Background
            ctx.fillStyle = root.themeGraphBackgroundColor
            ctx.fillRect(0, 0, width, height)

            // Grid lines
            ctx.strokeStyle = root.themeGraphGridColor
            ctx.lineWidth = 1
            for (var g = 0.25; g <= 1.0; g += 0.25) {
                ctx.beginPath()
                ctx.moveTo(0, height * (1 - g))
                ctx.lineTo(width, height * (1 - g))
                ctx.stroke()
            }

            var history = root.cpuHistory
            if (history.length < 2) return

            // Fill area
            ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2)
            ctx.beginPath()
            ctx.moveTo(0, height)
            for (var i = 0; i < history.length; i++) {
                var x = i / (history.length - 1) * width
                var y = height - history[i] * height
                ctx.lineTo(x, y)
            }
            ctx.lineTo(width, height)
            ctx.closePath()
            ctx.fill()

            // Line
            ctx.strokeStyle = "#00aaff"
            ctx.lineWidth = 1.5
            ctx.beginPath()
            for (var j = 0; j < history.length; j++) {
                var x2 = j / (history.length - 1) * width
                var y2 = height - history[j] * height
                if (j === 0) ctx.moveTo(x2, y2)
                else ctx.lineTo(x2, y2)
            }
            ctx.stroke()
        }

        // Labels
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            text: "100%"
            color: root.themeGraphLabelColor
            font.pixelSize: 9
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 2
            text: "50%"
            color: root.themeGraphLabelColor
            font.pixelSize: 9
        }
        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 2
            text: "0%"
            color: root.themeGraphLabelColor
            font.pixelSize: 9
        }
        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 2
            text: "5 mins ago"
            color: root.themeGraphLabelColor
            font.pixelSize: 9
        }
        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 2
            anchors.rightMargin: 30
            text: "now"
            color: root.themeGraphLabelColor
            font.pixelSize: 9
        }
    }

    // CPU Cores grid
    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "CPU Cores Usage Info"
        font.bold: true
        font.pixelSize: 11
    }

    GridView {
        id: coresGrid
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: Math.ceil((root.cpuCores.length) / 8) * 70
        cellWidth: width / Math.min(8, root.cpuCores.length > 0 ? root.cpuCores.length : 8)
        cellHeight: 70
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
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                // Bar chart
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
        model: root.topProcesses
        delegate: RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: modelData.name
                Layout.fillWidth: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                text: modelData.cpu.toFixed(1) + "%"
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
            font.italic: true
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
        font.pixelSize: 12
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: root.systemUptime || "..."
        font.pixelSize: 11
    }

    Item { height: Kirigami.Units.smallSpacing }
}
