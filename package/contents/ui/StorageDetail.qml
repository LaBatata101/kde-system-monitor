import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: storageDetailRoot

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    readonly property int axisLabelGap: 2
    readonly property int axisLabelWidth: axisLabelSizer.implicitWidth
    readonly property real axisScale: 10485760

    function formatAxisRate(bytes) {
        if (bytes < 1073741824) {
            var mib = bytes / 1048576
            return mib < 10 ? mib.toFixed(1) + " MB/s" : mib.toFixed(0) + " MB/s"
        }
        return (bytes / 1073741824).toFixed(1) + " GB/s"
    }

    Text {
        id: axisLabelSizer
        visible: false
        text: "999 MB/s"
        font.pixelSize: 10
    }

    Item { height: Kirigami.Units.smallSpacing }

    // Storage read/write history graph
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 2

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            Layout.minimumHeight: 80

            Canvas {
                id: storageGraph
                anchors.fill: parent
                property color themeTextColor: Kirigami.Theme.textColor

                onThemeTextColorChanged: requestPaint()

                Connections {
                    target: root
                    function onStorageHistoryChanged() { storageGraph.requestPaint() }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    var rightInset = axisLabelWidth + axisLabelGap
                    var plotWidth = Math.max(0, width - rightInset)
                    var halfHeight = height / 2
                    var dividerGap = 3
                    var readBottom = halfHeight - dividerGap
                    var readHeight = readBottom
                    var writeTop = halfHeight + dividerGap
                    var writeHeight = height - writeTop
                    var scale = storageDetailRoot.axisScale

                    ctx.clearRect(0, 0, width, height)

                    ctx.fillStyle = root.themeGraphBackgroundColor
                    ctx.fillRect(0, 0, plotWidth, height)

                    ctx.strokeStyle = root.themeGraphGridColor
                    ctx.lineWidth = 1
                    for (var g = 0.25; g <= 1.0; g += 0.25) {
                        ctx.beginPath()
                        ctx.moveTo(0, readBottom - readHeight * g)
                        ctx.lineTo(plotWidth, readBottom - readHeight * g)
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.moveTo(0, writeTop + writeHeight * (1 - g))
                        ctx.lineTo(plotWidth, writeTop + writeHeight * (1 - g))
                        ctx.stroke()
                    }

                    ctx.strokeStyle = root.themeBorderColor
                    ctx.lineWidth = 1
                    ctx.strokeRect(0.5, 0.5, plotWidth - 1, height - 1)
                    ctx.beginPath()
                    ctx.moveTo(0, halfHeight)
                    ctx.lineTo(plotWidth, halfHeight)
                    ctx.stroke()

                    var history = root.storageHistory
                    if (history.length < 2) return

                    ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2)
                    ctx.beginPath()
                    ctx.moveTo(0, readBottom)
                    for (var i = 0; i < history.length; i++) {
                        var x = i / (history.length - 1) * plotWidth
                        var y = readBottom - Math.min(1, history[i].read / scale) * readHeight
                        ctx.lineTo(x, y)
                    }
                    ctx.lineTo(plotWidth, readBottom)
                    ctx.closePath()
                    ctx.fill()

                    ctx.strokeStyle = "#00aaff"
                    ctx.lineWidth = 1.5
                    ctx.beginPath()
                    for (var j = 0; j < history.length; j++) {
                        var x2 = j / (history.length - 1) * plotWidth
                        var y2 = readBottom - Math.min(1, history[j].read / scale) * readHeight
                        if (j === 0) ctx.moveTo(x2, y2)
                        else ctx.lineTo(x2, y2)
                    }
                    ctx.stroke()

                    ctx.fillStyle = Qt.rgba(1, 0.27, 0.27, 0.2)
                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    for (var k = 0; k < history.length; k++) {
                        var x3 = k / (history.length - 1) * plotWidth
                        var y3 = height - Math.min(1, history[k].write / scale) * writeHeight
                        ctx.lineTo(x3, y3)
                    }
                    ctx.lineTo(plotWidth, height)
                    ctx.closePath()
                    ctx.fill()

                    ctx.strokeStyle = "#ff4444"
                    ctx.lineWidth = 1.5
                    ctx.beginPath()
                    for (var l = 0; l < history.length; l++) {
                        var x4 = l / (history.length - 1) * plotWidth
                        var y4 = height - Math.min(1, history[l].write / scale) * writeHeight
                        if (l === 0) ctx.moveTo(x4, y4)
                        else ctx.lineTo(x4, y4)
                    }
                    ctx.stroke()

                    ctx.strokeStyle = root.themeBorderColor
                    ctx.lineWidth = 1
                    ctx.strokeRect(0.5, 0.5, plotWidth - 1, height - 1)
                    ctx.beginPath()
                    ctx.moveTo(0, halfHeight)
                    ctx.lineTo(plotWidth, halfHeight)
                    ctx.stroke()
                }
            }

            Item {
                id: storageYAxisLabels

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: axisLabelWidth

                Text {
                    y: -6
                    width: parent.width
                    text: storageDetailRoot.formatAxisRate(storageDetailRoot.axisScale)
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
                Text {
                    y: parent.height / 4 - height / 2
                    width: parent.width
                    text: storageDetailRoot.formatAxisRate(storageDetailRoot.axisScale / 2)
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    text: storageDetailRoot.formatAxisRate(storageDetailRoot.axisScale)
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
                Text {
                    y: parent.height * 0.75 - height / 2
                    width: parent.width
                    text: storageDetailRoot.formatAxisRate(storageDetailRoot.axisScale / 2)
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
                Text {
                    y: parent.height - 6
                    width: parent.width
                    text: "0 MB/s"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: storageXAxisLabels.height + storageLegend.implicitHeight
            Layout.minimumHeight: storageXAxisLabels.height + storageLegend.implicitHeight

            Item {
                id: storageXAxisLabels
                anchors.left: parent.left
                anchors.right: parent.right
                height: Math.max(storagePastLabel.implicitHeight, storageNowLabel.implicitHeight)

                PlasmaComponents.Label {
                    id: storagePastLabel
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "5min ago"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                }

                PlasmaComponents.Label {
                    id: storageNowLabel
                    anchors.right: parent.right
                    anchors.rightMargin: axisLabelWidth + axisLabelGap
                    anchors.top: parent.top
                    text: "now"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                }
            }

            RowLayout {
                id: storageLegend
                anchors.left: parent.left
                anchors.top: storageXAxisLabels.bottom
                spacing: Kirigami.Units.smallSpacing

                Rectangle { width: 12; height: 3; color: "#00aaff"; radius: 1 }
                PlasmaComponents.Label { text: "Read " + root.storageReadSpeed; font.pixelSize: 10 }
                Rectangle { width: 12; height: 3; color: "#ff4444"; radius: 1 }
                PlasmaComponents.Label { text: "Write " + root.storageWriteSpeed; font.pixelSize: 10 }
            }
        }
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Devices"
        font.bold: true
        font.pixelSize: 12
    }

    Repeater {
        model: root.storageBlockDevices

        delegate: ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    text: modelData.name
                    font.bold: true
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    text: modelData.hasUsage ? modelData.used + " / " + modelData.usageSize : modelData.usageSize
                    font.pixelSize: 10
                }
            }

            PlasmaComponents.Label {
                text: modelData.path + " • " + modelData.detail
                font.pixelSize: 9
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
            }

            Item {
                visible: modelData.hasUsage
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
        visible: root.storageBlockDevices.length === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "No storage devices found"
        font.italic: true
        font.pixelSize: 11
    }

    Item { height: Kirigami.Units.smallSpacing }
}
