import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    Layout.preferredWidth: contentRow.implicitWidth
    Layout.minimumWidth: contentRow.implicitWidth
    Layout.preferredHeight: contentRow.implicitHeight
    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    readonly property int labelPx: Math.max(8, Kirigami.Units.sizeForLabels)
    readonly property int twoLineLabelPx: Math.max(8, labelPx - 0.5)
    readonly property int iconSz: Kirigami.Units.iconSizes.small
    readonly property int sectionGap: Kirigami.Units.smallSpacing
    readonly property int hotspotHorizontalPadding: Kirigami.Units.smallSpacing
    readonly property int hotspotVerticalPadding: Kirigami.Units.smallSpacing
    readonly property int arrowSz: Math.max(8, Kirigami.Units.iconSizes.small - 4)
    readonly property var coreColors: ["#00aaff", "#22cc66", "#ffaa00", "#aa66ff", "#ff6688", "#00ccbb"]
    readonly property var defaultSectionOrder: ["temps", "network", "storage", "cpu", "gpu", "ram"]
    readonly property var visibleSectionKeys: enabledSectionKeys(
        plasmoid.configuration.sectionOrder,
        plasmoid.configuration.showTemps,
        plasmoid.configuration.showNetwork,
        plasmoid.configuration.showStorage,
        plasmoid.configuration.showCpu,
        plasmoid.configuration.showGpu,
        plasmoid.configuration.showRam
    )

    function hideExpandedFeedback() {
        var item = compactRoot.parent
        while (item) {
            if (item.expandedFeedback) {
                item.expandedFeedback.opacity = 0
                item.expandedFeedback.visible = false
                return
            }
            item = item.parent
        }
    }

    function normalizedSectionOrder(order) {
        var result = []
        var seen = {}
        var parts = String(order || "").split(",")
        for (var i = 0; i < parts.length; i++) {
            var key = parts[i].trim()
            if (defaultSectionOrder.indexOf(key) !== -1 && !seen[key]) {
                result.push(key)
                seen[key] = true
            }
        }
        for (var j = 0; j < defaultSectionOrder.length; j++) {
            var defaultKey = defaultSectionOrder[j]
            if (!seen[defaultKey]) result.push(defaultKey)
        }
        return result
    }

    function sectionEnabled(key, showTemps, showNetwork, showStorage, showCpu, showGpu, showRam) {
        switch (key) {
        case "temps": return showTemps
        case "network": return showNetwork
        case "storage": return showStorage
        case "cpu": return showCpu
        case "gpu": return showGpu
        case "ram": return showRam
        }
        return false
    }

    function enabledSectionKeys(order, showTemps, showNetwork, showStorage, showCpu, showGpu, showRam) {
        var keys = normalizedSectionOrder(order)
        var result = []
        for (var i = 0; i < keys.length; i++) {
            if (sectionEnabled(keys[i], showTemps, showNetwork, showStorage, showCpu, showGpu, showRam)) {
                result.push(keys[i])
            }
        }
        return result
    }

    function sectionComponent(key) {
        switch (key) {
        case "temps": return tempsSection
        case "network": return networkSection
        case "storage": return storageSection
        case "cpu": return cpuSection
        case "gpu": return gpuSection
        case "ram": return ramSection
        }
        return null
    }

    function sectionTitle(key) {
        return root.compactToolTipTitle(key)
    }

    function sectionSummary(key) {
        return root.compactToolTipSummary(key)
    }

    Component.onCompleted: Qt.callLater(hideExpandedFeedback)

    RowLayout {
        id: contentRow
        anchors.fill: parent
        spacing: compactRoot.sectionGap

        Repeater {
            model: compactRoot.visibleSectionKeys

            Loader {
                sourceComponent: compactRoot.sectionComponent(modelData)
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                Layout.preferredWidth: item ? item.implicitWidth : 0
                Layout.preferredHeight: item ? item.implicitHeight : 0
            }
        }
    }

    Component {
        id: tempsSection

        Rectangle {
            implicitWidth: tempContent.implicitWidth + compactRoot.hotspotHorizontalPadding * 2
            implicitHeight: Math.max(compactRoot.iconSz, tempContent.implicitHeight) + compactRoot.hotspotVerticalPadding * 2
            radius: 3
            color: tempToolTipArea.containsMouse ? root.themeHoverColor : "transparent"

            RowLayout {
                id: tempContent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: compactRoot.hotspotHorizontalPadding
                anchors.rightMargin: compactRoot.hotspotHorizontalPadding
                spacing: Kirigami.Units.smallSpacing

                SvgIcon {
                    name: "am-temperature-symbolic"
                    implicitWidth: compactRoot.iconSz
                    implicitHeight: compactRoot.iconSz
                    Layout.alignment: Qt.AlignVCenter
                }

                Column {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: tempRef.implicitWidth
                    Layout.minimumWidth: tempRef.implicitWidth

                    Text {
                        id: tempRef
                        visible: false
                        text: "99.9 °C"
                        font.pixelSize: compactRoot.twoLineLabelPx
                    }

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
            }

            PlasmaCore.ToolTipArea {
                id: tempToolTipArea
                anchors.fill: parent
                mainText: compactRoot.sectionTitle("temps")
                subText: compactRoot.sectionSummary("temps")
                location: Plasmoid.location
                active: !root.expanded

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.openSection(4)
                }
            }
        }
    }

    Component {
        id: networkSection

        Rectangle {
            implicitWidth: networkContent.implicitWidth + compactRoot.hotspotHorizontalPadding * 2
            implicitHeight: Math.max(compactRoot.iconSz + 10, networkContent.implicitHeight) + compactRoot.hotspotVerticalPadding * 2
            radius: 3
            color: networkToolTipArea.containsMouse ? root.themeHoverColor : "transparent"

            RowLayout {
                id: networkContent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: compactRoot.hotspotHorizontalPadding
                anchors.rightMargin: compactRoot.hotspotHorizontalPadding
                spacing: Kirigami.Units.smallSpacing

                SvgIcon {
                    name: "am-network-symbolic"
                    implicitWidth: compactRoot.iconSz
                    implicitHeight: compactRoot.iconSz
                    Layout.alignment: Qt.AlignVCenter
                }

                Canvas {
                    id: netMiniGraph
                    implicitWidth: 36
                    implicitHeight: compactRoot.iconSz + 10
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
                        var dividerGap = 2
                        var topPadding = 2
                        var uploadBottom = halfHeight - dividerGap
                        var uploadHeight = uploadBottom - topPadding
                        var downloadTop = halfHeight + dividerGap
                        var downloadHeight = height - downloadTop
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

                        ctx.fillStyle = Qt.rgba(1, 0.27, 0.27, 0.2)
                        ctx.beginPath()
                        ctx.moveTo(0, uploadBottom)
                        for (var i = 0; i < h.length; i++) {
                            var x = i / (h.length - 1) * width
                            var y = uploadBottom - h[i].tx * uploadHeight
                            ctx.lineTo(x, y)
                        }
                        ctx.lineTo(width, uploadBottom)
                        ctx.closePath()
                        ctx.fill()

                        ctx.strokeStyle = "#ff4444"
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        for (var j = 0; j < h.length; j++) {
                            var x2 = j / (h.length - 1) * width
                            var y2 = uploadBottom - h[j].tx * uploadHeight
                            j === 0 ? ctx.moveTo(x2, y2) : ctx.lineTo(x2, y2)
                        }
                        ctx.stroke()

                        ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2)
                        ctx.beginPath()
                        ctx.moveTo(0, height)
                        for (var k = 0; k < h.length; k++) {
                            var x3 = k / (h.length - 1) * width
                            var y3 = height - h[k].rx * downloadHeight
                            ctx.lineTo(x3, y3)
                        }
                        ctx.lineTo(width, height)
                        ctx.closePath()
                        ctx.fill()

                        ctx.strokeStyle = "#00aaff"
                        ctx.beginPath()
                        for (var l = 0; l < h.length; l++) {
                            var x4 = l / (h.length - 1) * width
                            var y4 = height - h[l].rx * downloadHeight
                            l === 0 ? ctx.moveTo(x4, y4) : ctx.lineTo(x4, y4)
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

                Column {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter

                    Row {
                        spacing: 2
                        SvgIcon {
                            name: "am-up-symbolic"
                            width: compactRoot.arrowSz
                            height: compactRoot.arrowSz
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.netUploadCompactSpeed
                            font.pixelSize: compactRoot.twoLineLabelPx
                            color: Kirigami.Theme.textColor
                            font.bold: true
                        }
                    }

                    Row {
                        spacing: 2
                        SvgIcon {
                            name: "am-down-symbolic"
                            width: compactRoot.arrowSz
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
            }

            PlasmaCore.ToolTipArea {
                id: networkToolTipArea
                anchors.fill: parent
                mainText: compactRoot.sectionTitle("network")
                subText: compactRoot.sectionSummary("network")
                location: Plasmoid.location
                active: !root.expanded

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.openSection(2)
                }
            }
        }
    }

    Component {
        id: storageSection

        Rectangle {
            implicitWidth: storageContent.implicitWidth + compactRoot.hotspotHorizontalPadding * 2
            implicitHeight: Math.max(compactRoot.iconSz, storageContent.implicitHeight) + compactRoot.hotspotVerticalPadding * 2
            radius: 3
            color: storageToolTipArea.containsMouse ? root.themeHoverColor : "transparent"

            RowLayout {
                id: storageContent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: compactRoot.hotspotHorizontalPadding
                anchors.rightMargin: compactRoot.hotspotHorizontalPadding
                spacing: Kirigami.Units.smallSpacing

                SvgIcon {
                    name: "am-harddisk-symbolic"
                    implicitWidth: compactRoot.iconSz
                    implicitHeight: compactRoot.iconSz
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    implicitWidth: Math.round(compactRoot.iconSz * 0.7)
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
            }

            PlasmaCore.ToolTipArea {
                id: storageToolTipArea
                anchors.fill: parent
                mainText: compactRoot.sectionTitle("storage")
                subText: compactRoot.sectionSummary("storage")
                location: Plasmoid.location
                active: !root.expanded

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.openSection(3)
                }
            }
        }
    }

    Component {
        id: cpuSection

        Rectangle {
            implicitWidth: cpuContent.implicitWidth + compactRoot.hotspotHorizontalPadding * 2
            implicitHeight: Math.max(compactRoot.iconSz, cpuContent.implicitHeight) + compactRoot.hotspotVerticalPadding * 2
            radius: 3
            color: cpuToolTipArea.containsMouse ? root.themeHoverColor : "transparent"

            RowLayout {
                id: cpuContent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: compactRoot.hotspotHorizontalPadding
                anchors.rightMargin: compactRoot.hotspotHorizontalPadding
                spacing: Kirigami.Units.smallSpacing

                SvgIcon {
                    name: "am-cpu-symbolic"
                    implicitWidth: compactRoot.iconSz
                    implicitHeight: compactRoot.iconSz
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    implicitWidth: Math.max(Math.round(compactRoot.iconSz * 0.7), root.cpuCores.length * 4)
                    implicitHeight: compactRoot.iconSz
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: root.themeBorderColor
                        border.width: 1
                        radius: 2
                    }

                    Rectangle {
                        visible: root.cpuCores.length === 0
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
                        height: root.cpuTotal > 0 ? Math.max(1, (parent.height - 2) * (root.cpuTotal / 100)) : 0
                        color: root.cpuTotal > 80 ? "#ff4444" : "#00aaff"
                        radius: 1
                        Behavior on height { NumberAnimation { duration: 300 } }
                    }

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

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Math.max(cpuPctRef.implicitWidth, cpuPctDecRef.implicitWidth)
                    Layout.minimumWidth: Math.max(cpuPctRef.implicitWidth, cpuPctDecRef.implicitWidth)
                    horizontalAlignment: Text.AlignLeft
                    text: root.cpuTotal < 1 ? root.cpuTotal.toFixed(1) + "%" : root.cpuTotal.toFixed(0) + "%"
                    font.pixelSize: compactRoot.labelPx
                    font.bold: true
                    color: Kirigami.Theme.textColor

                    Text { id: cpuPctRef; visible: false; text: "100%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
                    Text { id: cpuPctDecRef; visible: false; text: "0.0%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
                }
            }

            PlasmaCore.ToolTipArea {
                id: cpuToolTipArea
                anchors.fill: parent
                mainText: compactRoot.sectionTitle("cpu")
                subText: compactRoot.sectionSummary("cpu")
                location: Plasmoid.location
                active: !root.expanded

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.openSection(0)
                }
            }
        }
    }

    Component {
        id: gpuSection

        Rectangle {
            implicitWidth: gpuContent.implicitWidth + compactRoot.hotspotHorizontalPadding * 2
            implicitHeight: Math.max(compactRoot.iconSz, gpuContent.implicitHeight) + compactRoot.hotspotVerticalPadding * 2
            radius: 3
            color: gpuToolTipArea.containsMouse ? root.themeHoverColor : "transparent"

            RowLayout {
                id: gpuContent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: compactRoot.hotspotHorizontalPadding
                anchors.rightMargin: compactRoot.hotspotHorizontalPadding
                spacing: Kirigami.Units.smallSpacing

                SvgIcon {
                    name: "am-gpu-symbolic"
                    implicitWidth: compactRoot.iconSz
                    implicitHeight: compactRoot.iconSz
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    implicitWidth: Math.round(compactRoot.iconSz * 0.7)
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
                            height: Math.max(0, (parent.height - 2) * (root.gpuUsage / 100))
                            color: root.gpuUsage > 85 ? "#ff4444" : "#00aaff"
                            radius: 1
                            Behavior on height { NumberAnimation { duration: 300 } }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: gpuPctRef.implicitWidth
                    Layout.minimumWidth: gpuPctRef.implicitWidth
                    horizontalAlignment: Text.AlignLeft
                    text: root.formatPercent(root.gpuUsage)
                    font.pixelSize: compactRoot.labelPx
                    font.bold: true
                    color: Kirigami.Theme.textColor

                    Text { id: gpuPctRef; visible: false; text: "100%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
                }
            }

            PlasmaCore.ToolTipArea {
                id: gpuToolTipArea
                anchors.fill: parent
                mainText: compactRoot.sectionTitle("gpu")
                subText: compactRoot.sectionSummary("gpu")
                location: Plasmoid.location
                active: !root.expanded

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openSection(5)
                }
            }
        }
    }

    Component {
        id: ramSection

        Rectangle {
            implicitWidth: ramContent.implicitWidth + compactRoot.hotspotHorizontalPadding * 2
            implicitHeight: Math.max(compactRoot.iconSz, ramContent.implicitHeight) + compactRoot.hotspotVerticalPadding * 2
            radius: 3
            color: ramToolTipArea.containsMouse ? root.themeHoverColor : "transparent"

            RowLayout {
                id: ramContent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: compactRoot.hotspotHorizontalPadding
                anchors.rightMargin: compactRoot.hotspotHorizontalPadding
                spacing: Kirigami.Units.smallSpacing

                SvgIcon {
                    name: "am-memory-symbolic"
                    implicitWidth: compactRoot.iconSz
                    implicitHeight: compactRoot.iconSz
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    implicitWidth: Math.round(compactRoot.iconSz * 0.7)
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

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: ramPctRef.implicitWidth
                    Layout.minimumWidth: ramPctRef.implicitWidth
                    horizontalAlignment: Text.AlignLeft
                    text: root.ramTotal > 0 ? (root.ramUsed / root.ramTotal * 100).toFixed(0) + "%" : "---%"
                    font.pixelSize: compactRoot.labelPx
                    font.bold: true
                    color: Kirigami.Theme.textColor

                    Text { id: ramPctRef; visible: false; text: "100%"; font.pixelSize: compactRoot.labelPx; font.bold: true }
                }
            }

            PlasmaCore.ToolTipArea {
                id: ramToolTipArea
                anchors.fill: parent
                mainText: compactRoot.sectionTitle("ram")
                subText: compactRoot.sectionSummary("ram")
                location: Plasmoid.location
                active: !root.expanded

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.openSection(1)
                }
            }
        }
    }
}
