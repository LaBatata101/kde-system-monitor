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

        StatRow { label: "Upload:"; value: root.netUploadSpeed }
        StatRow { label: "Download:"; value: root.netDownloadSpeed }
    }

    // Network history graph
    Canvas {
        id: netGraph
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 80
        property color themeTextColor: Kirigami.Theme.textColor

        onThemeTextColorChanged: requestPaint()

        Connections {
            target: root
            function onNetHistoryChanged() { netGraph.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var halfHeight = height / 2

            ctx.fillStyle = root.themeGraphBackgroundColor
            ctx.fillRect(0, 0, width, height)

            ctx.strokeStyle = root.themeGraphGridColor
            ctx.lineWidth = 1
            for (var g = 0.25; g <= 1.0; g += 0.25) {
                ctx.beginPath()
                ctx.moveTo(0, halfHeight * (1 - g))
                ctx.lineTo(width, halfHeight * (1 - g))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(0, halfHeight + halfHeight * (1 - g))
                ctx.lineTo(width, halfHeight + halfHeight * (1 - g))
                ctx.stroke()
            }

            ctx.strokeStyle = root.themeBorderColor
            ctx.lineWidth = 1
            ctx.strokeRect(0.5, 0.5, width - 1, height - 1)
            ctx.beginPath()
            ctx.moveTo(0, halfHeight)
            ctx.lineTo(width, halfHeight)
            ctx.stroke()

            var history = root.netHistory
            if (history.length < 2) return

            // Upload (red)
            ctx.strokeStyle = "#ff4444"
            ctx.lineWidth = 1.5
            ctx.beginPath()
            for (var i = 0; i < history.length; i++) {
                var x = i / (history.length - 1) * width
                var y = halfHeight - history[i].tx * halfHeight
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()

            // Download (blue)
            ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2)
            ctx.beginPath()
            ctx.moveTo(0, height)
            for (var j = 0; j < history.length; j++) {
                var x2 = j / (history.length - 1) * width
                var y2 = height - history[j].rx * halfHeight
                ctx.lineTo(x2, y2)
            }
            ctx.lineTo(width, height)
            ctx.closePath()
            ctx.fill()

            ctx.strokeStyle = "#00aaff"
            ctx.lineWidth = 1.5
            ctx.beginPath()
            for (var k = 0; k < history.length; k++) {
                var x3 = k / (history.length - 1) * width
                var y3 = height - history[k].rx * halfHeight
                if (k === 0) ctx.moveTo(x3, y3)
                else ctx.lineTo(x3, y3)
            }
            ctx.stroke()

            ctx.strokeStyle = root.themeBorderColor
            ctx.lineWidth = 1
            ctx.strokeRect(0.5, 0.5, width - 1, height - 1)
            ctx.beginPath()
            ctx.moveTo(0, halfHeight)
            ctx.lineTo(width, halfHeight)
            ctx.stroke()
        }
    }

    // Legend
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Rectangle { width: 12; height: 3; color: "#00aaff"; radius: 1 }
        PlasmaComponents.Label { text: "Download"; font.pixelSize: 10 }
        Rectangle { width: 12; height: 3; color: "#ff4444"; radius: 1 }
        PlasmaComponents.Label { text: "Upload"; font.pixelSize: 10 }
    }

    Item { height: Kirigami.Units.smallSpacing }
}
