import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    Layout.preferredWidth: sizerRow.implicitWidth
    Layout.minimumWidth:   sizerRow.implicitWidth
    implicitWidth:         sizerRow.implicitWidth

    readonly property int labelPx: Math.max(8, Kirigami.Units.sizeForLabels)
    readonly property int twoLineLabelPx: Math.max(8, labelPx - 0.5)
    readonly property int iconSz:  Kirigami.Units.iconSizes.small        // 16 px
    // Smaller icon for inline arrow (next to a single text line)
    readonly property int arrowSz: Math.max(8, Kirigami.Units.iconSizes.small - 4)  // ~12 px
    readonly property var coreColors: ["#00aaff", "#22cc66", "#ffaa00", "#aa66ff", "#ff6688", "#00ccbb"]

    // Hidden sizer row 
    // Must mirror every item in contentRow so implicitWidth is stable.
    RowLayout {
        id: sizerRow
        visible: false
        spacing: Kirigami.Units.smallSpacing

        // Temp icon
        Item { implicitWidth: compactRoot.iconSz;  implicitHeight: compactRoot.iconSz }
        // Temp text column
        Text { text: "99.9 °C\n99.9 °C"; font.pixelSize: compactRoot.twoLineLabelPx }
        // Network section: icon + two rows of (arrow icon + speed text)
        Item { implicitWidth: compactRoot.iconSz;  implicitHeight: compactRoot.iconSz }
        Column {
            spacing: 0
            RowLayout {
                spacing: 2
                Item { implicitWidth: compactRoot.arrowSz; implicitHeight: compactRoot.arrowSz }
                Text { text: "999.9 MB/s"; font.pixelSize: compactRoot.twoLineLabelPx }
            }
            RowLayout {
                spacing: 2
                Item { implicitWidth: compactRoot.arrowSz; implicitHeight: compactRoot.arrowSz }
                Text { text: "999.9 MB/s"; font.pixelSize: compactRoot.twoLineLabelPx }
            }
        }
        // Storage icon
        Item { implicitWidth: compactRoot.iconSz;  implicitHeight: compactRoot.iconSz }
        // Storage bar
        Item { implicitWidth: Math.round(compactRoot.iconSz * 0.7); implicitHeight: compactRoot.iconSz }
        // Mini network graph
        Item { implicitWidth: 36; implicitHeight: compactRoot.iconSz }
        // CPU icon
        Item { implicitWidth: compactRoot.iconSz;  implicitHeight: compactRoot.iconSz }
        // CPU bar
        Item { implicitWidth: Math.max(Math.round(compactRoot.iconSz * 0.7), root.cpuCores.length * 4); implicitHeight: compactRoot.iconSz }
        // CPU percent
        Text { text: "100%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
        // RAM icon
        Item { implicitWidth: compactRoot.iconSz;  implicitHeight: compactRoot.iconSz }
        // RAM bar
        Item { implicitWidth: Math.round(compactRoot.iconSz * 0.7); implicitHeight: compactRoot.iconSz }
        // RAM percent
        Text { text: "100%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
    }

    // Visible content 
    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Temperature icon 
        SvgIcon {
            visible: plasmoid.configuration.showTemps
            name: "am-temperature-symbolic"
            implicitWidth:  compactRoot.iconSz
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter
        }

        // Temperature values (2 lines) 
        Column {
            visible: plasmoid.configuration.showTemps
            spacing: 0
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: tempRef.implicitWidth
            Layout.minimumWidth:   tempRef.implicitWidth

            Text { id: tempRef; visible: false; text: "99.9 °C"; font.pixelSize: compactRoot.twoLineLabelPx }

            Repeater {
                model: Math.min(root.temperatures.length, 2)
                Text {
                    width: tempRef.implicitWidth
                    text: root.temperatures[index].value.toFixed(1) + " °C"
                    font.pixelSize: compactRoot.twoLineLabelPx
                    color: {
                        var t = root.temperatures[index].value
                        if (t > 90) return "#ff4444"
                        if (t > 75) return "#ffaa00"
                        return Kirigami.Theme.textColor
                    }
                    font.bold: true
                }
            }
            Repeater {
                model: Math.max(0, 2 - root.temperatures.length)
                Text {
                    width: tempRef.implicitWidth
                    text: "-- °C"
                    font.pixelSize: compactRoot.twoLineLabelPx
                    color: root.themePlaceholderTextColor
                    font.bold: true
                }
            }
        }

        // Network icon 
        SvgIcon {
            visible: plasmoid.configuration.showNetwork
            name: "am-network-symbolic"
            implicitWidth:  compactRoot.iconSz
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter
        }

        // Network speeds (icon + text per row) 
        Column {
            visible: plasmoid.configuration.showNetwork
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            // Upload row
            Row {
                spacing: 2
                SvgIcon {
                    name: "am-up-symbolic"
                    width:  compactRoot.arrowSz
                    height: compactRoot.arrowSz
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: netRef
                    text: root.netUploadCompactSpeed
                    font.pixelSize: compactRoot.twoLineLabelPx
                    color: Kirigami.Theme.textColor
                    font.bold: true
                }
            }
            // Download row
            Row {
                spacing: 2
                SvgIcon {
                    name: "am-down-symbolic"
                    width:  compactRoot.arrowSz
                    height: compactRoot.arrowSz
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.netDownloadCompactSpeed
                    font.pixelSize: compactRoot.twoLineLabelPx
                    color: Kirigami.Theme.textColor
                    font.bold: true
                }
            }
        }

        // Network graph 
        Canvas {
            id: netMiniGraph
            visible: plasmoid.configuration.showNetwork
            implicitWidth:  36
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter
            property color themeTextColor: Kirigami.Theme.textColor

            onThemeTextColorChanged: requestPaint()

            Connections {
                target: root
                function onNetHistoryChanged() { netMiniGraph.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var halfHeight = height / 2
                var borderColor = root.themeBorderColor

                ctx.strokeStyle = borderColor
                ctx.lineWidth = 1
                ctx.strokeRect(0.5, 0.5, width - 1, height - 1)
                ctx.beginPath()
                ctx.moveTo(0, halfHeight)
                ctx.lineTo(width, halfHeight)
                ctx.stroke()

                var h = root.netHistory
                if (h.length < 2) return
                ctx.strokeStyle = "#ff4444"; ctx.lineWidth = 1
                ctx.beginPath()
                for (var i = 0; i < h.length; i++) {
                    var x = i / (h.length - 1) * width
                    var y = halfHeight - h[i].tx * halfHeight
                    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
                }
                ctx.stroke()
                ctx.strokeStyle = "#00aaff"
                ctx.beginPath()
                for (var j = 0; j < h.length; j++) {
                    var x2 = j / (h.length - 1) * width
                    var y2 = height - h[j].rx * halfHeight
                    j === 0 ? ctx.moveTo(x2, y2) : ctx.lineTo(x2, y2)
                }
                ctx.stroke()

                ctx.strokeStyle = borderColor
                ctx.lineWidth = 1
                ctx.strokeRect(0.5, 0.5, width - 1, height - 1)
                ctx.beginPath()
                ctx.moveTo(0, halfHeight)
                ctx.lineTo(width, halfHeight)
                ctx.stroke()
            }
        }

        // Storage icon 
        SvgIcon {
            visible: plasmoid.configuration.showStorage
            name: "am-harddisk-symbolic"
            implicitWidth:  compactRoot.iconSz
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter
        }

        // Storage usage bar 
        Item {
            visible: plasmoid.configuration.showStorage
            implicitWidth:  Math.round(compactRoot.iconSz * 0.7)
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: root.themeBorderColor
                border.width: 1
                radius: 2

                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 1 }
                    height: root.storageDevices.length > 0 && root.storageDevices[0].percent > 0
                        ? Math.max(3, (parent.height - 2) * (root.storageDevices[0].percent / 100))
                        : 0
                    color: root.storageDevices.length > 0 && root.storageDevices[0].percent > 85
                        ? "#ff4444" : "#00aaff"
                    radius: 1
                    Behavior on height { NumberAnimation { duration: 300 } }
                }
            }
        }

        // CPU icon 
        SvgIcon {
            visible: plasmoid.configuration.showCpu
            name: "am-cpu-symbolic"
            implicitWidth:  compactRoot.iconSz
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter
        }

        //  CPU per-core bars 
        Item {
            visible: plasmoid.configuration.showCpu
            implicitWidth:  Math.max(Math.round(compactRoot.iconSz * 0.7), root.cpuCores.length * 4)
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter

            // Outer border
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: root.themeBorderColor
                border.width: 1
                radius: 2
            }

            // Fallback single bar before core data arrives
            Rectangle {
                visible: root.cpuCores.length === 0
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
                height: root.cpuTotal > 0 ? Math.max(1, (parent.height - 2) * (root.cpuTotal / 100)) : 0
                color: root.cpuTotal > 80 ? "#ff4444" : "#00aaff"
                radius: 1
                Behavior on height { NumberAnimation { duration: 300 } }
            }

            // One thin bar per core, filling from the bottom
            RowLayout {
                visible: root.cpuCores.length > 0
                anchors { fill: parent; margins: 1 }
                spacing: 0

                Repeater {
                    model: root.cpuCores
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: modelData.usage > 0 ? Math.max(1, parent.height * (modelData.usage / 100)) : 0
                            color: compactRoot.coreColors[index % compactRoot.coreColors.length]
                            Behavior on height { NumberAnimation { duration: 300 } }
                        }
                    }
                }
            }
        }

        // CPU percent 
        Text {
            visible: plasmoid.configuration.showCpu
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.max(cpuPctRef.implicitWidth, cpuPctDecRef.implicitWidth)
            Layout.minimumWidth:   Math.max(cpuPctRef.implicitWidth, cpuPctDecRef.implicitWidth)
            horizontalAlignment: Text.AlignRight
            text: root.cpuTotal < 1 ? root.cpuTotal.toFixed(1) + "%" : root.cpuTotal.toFixed(0) + "%"
            font.pixelSize: compactRoot.labelPx
            font.bold: true
            color: Kirigami.Theme.textColor

            Text { id: cpuPctRef; visible: false; text: "100%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
            Text { id: cpuPctDecRef; visible: false; text: "0.0%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
        }

        // RAM icon 
        SvgIcon {
            visible: plasmoid.configuration.showRam
            name: "am-memory-symbolic"
            implicitWidth:  compactRoot.iconSz
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter
        }

        //  RAM vertical bar 
        Item {
            visible: plasmoid.configuration.showRam
            implicitWidth:  Math.round(compactRoot.iconSz * 0.7)
            implicitHeight: compactRoot.iconSz
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: root.themeBorderColor
                border.width: 1
                radius: 2

                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 1 }
                    height: Math.max(0, (parent.height - 2) * (root.ramTotal > 0 ? root.ramUsed / root.ramTotal : 0))
                    color: (root.ramTotal > 0 && root.ramUsed / root.ramTotal > 0.85) ? "#ff4444" : "#00aaff"
                    radius: 1
                    Behavior on height { NumberAnimation { duration: 300 } }
                }
            }
        }

        // RAM percent 
        Text {
            visible: plasmoid.configuration.showRam
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: ramPctRef.implicitWidth
            Layout.minimumWidth:   ramPctRef.implicitWidth
            horizontalAlignment: Text.AlignRight
            text: root.ramTotal > 0 ? (root.ramUsed / root.ramTotal * 100).toFixed(0) + "%" : "---%"
            font.pixelSize: compactRoot.labelPx
            font.bold: true
            color: Kirigami.Theme.textColor

            Text { id: ramPctRef; visible: false; text: "100%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: plasmoid.expanded = !plasmoid.expanded
        cursorShape: Qt.PointingHandCursor
    }
}
