pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: compactRoot

    required property var parentRef

    readonly property int labelPx: Math.max(8, Kirigami.Units.sizeForLabels)
    readonly property int twoLineLabelPx: Math.max(8, compactRoot.labelPx - 0.5)
    readonly property int iconSz: Kirigami.Units.iconSizes.small
    readonly property int sectionGap: Kirigami.Units.smallSpacing
    readonly property int hotspotHorizontalPadding: Kirigami.Units.smallSpacing
    readonly property int hotspotVerticalPadding: Kirigami.Units.smallSpacing
    readonly property int arrowSz: Math.max(8, Kirigami.Units.iconSizes.small - 4)
    readonly property var coreColors: ["#00aaff", "#22cc66", "#ffaa00", "#aa66ff", "#ff6688", "#00ccbb"]
    readonly property var defaultSectionOrder: ["temps", "network", "storage", "cpu", "gpu", "ram"]
    readonly property var visibleSectionKeys: compactRoot.enabledSectionKeys(Plasmoid.configuration.sectionOrder, Plasmoid.configuration.showTemps, Plasmoid.configuration.showNetwork, Plasmoid.configuration.showStorage, Plasmoid.configuration.showCpu, Plasmoid.configuration.showGpu, Plasmoid.configuration.showRam)

    function normalizedSectionOrder(order) {
        let result = [];
        let seen = {};
        let parts = String(order || "").split(",");
        for (let i = 0; i < parts.length; i++) {
            let key = parts[i].trim();
            if (compactRoot.defaultSectionOrder.indexOf(key) !== -1 && !seen[key]) {
                result.push(key);
                seen[key] = true;
            }
        }
        for (let j = 0; j < compactRoot.defaultSectionOrder.length; j++) {
            let defaultKey = compactRoot.defaultSectionOrder[j];
            if (!seen[defaultKey])
                result.push(defaultKey);
        }
        return result;
    }

    function sectionEnabled(key, showTemps, showNetwork, showStorage, showCpu, showGpu, showRam) {
        switch (key) {
        case "temps":
            return showTemps;
        case "network":
            return showNetwork;
        case "storage":
            return showStorage;
        case "cpu":
            return showCpu;
        case "gpu":
            return showGpu;
        case "ram":
            return showRam;
        }
        return false;
    }

    function enabledSectionKeys(order, showTemps, showNetwork, showStorage, showCpu, showGpu, showRam) {
        let keys = compactRoot.normalizedSectionOrder(order);
        let result = [];
        for (let i = 0; i < keys.length; i++) {
            if (compactRoot.sectionEnabled(keys[i], showTemps, showNetwork, showStorage, showCpu, showGpu, showRam))
                result.push(keys[i]);
        }
        return result;
    }

    function sectionComponent(key) {
        switch (key) {
        case "temps":
            return tempsSection;
        case "network":
            return networkSection;
        case "storage":
            return storageSection;
        case "cpu":
            return cpuSection;
        case "gpu":
            return gpuSection;
        case "ram":
            return ramSection;
        }
        return null;
    }

    function sectionTitle(key) {
        return compactRoot.parentRef.compactToolTipTitle(key);
    }

    function sectionSummary(key) {
        return compactRoot.parentRef.compactToolTipSummary(key);
    }

    function hideExpandedFeedback() {
        let item = compactRoot.parent;
        while (item) {
            if (item.expandedFeedback) {
                item.expandedFeedback.opacity = 0;
                item.expandedFeedback.visible = false;
                return;
            }
            item = item.parent;
        }
    }

    Component.onCompleted: Qt.callLater(compactRoot.hideExpandedFeedback)

    Layout.preferredWidth: contentRow.implicitWidth
    Layout.minimumWidth: contentRow.implicitWidth
    Layout.preferredHeight: contentRow.implicitHeight
    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    Connections {
        target: compactRoot.parentRef

        function onExpandedChanged() {
            Qt.callLater(compactRoot.hideExpandedFeedback);
        }
    }

    RowLayout {
        id: contentRow

        anchors.fill: compactRoot
        spacing: compactRoot.sectionGap

        Repeater {
            model: compactRoot.visibleSectionKeys

            Loader {
                id: sectionLoader

                required property var modelData

                sourceComponent: compactRoot.sectionComponent(sectionLoader.modelData)
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                Layout.preferredWidth: sectionLoader.item ? sectionLoader.item.implicitWidth : 0
                Layout.preferredHeight: sectionLoader.item ? sectionLoader.item.implicitHeight : 0
            }
        }
    }

    Component {
        id: tempsSection

        CompactSection {

            contentMinimumHeight: compactRoot.iconSz
            horizontalPadding: compactRoot.hotspotHorizontalPadding
            verticalPadding: compactRoot.hotspotVerticalPadding
            hoverColor: compactRoot.parentRef.themeHoverColor
            title: compactRoot.sectionTitle("temps")
            summary: compactRoot.sectionSummary("temps")
            tooltipActive: !compactRoot.parentRef.expanded
            onClicked: compactRoot.parentRef.openSection(4)

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
                    model: Math.min(compactRoot.parentRef.temperatures.length, 2)

                    Text {
                        id: temperatureText

                        required property int index

                        width: tempRef.implicitWidth
                        text: compactRoot.parentRef.temperatures[temperatureText.index].value.toFixed(1) + " °C"
                        font.pixelSize: compactRoot.twoLineLabelPx
                        color: {
                            let t = compactRoot.parentRef.temperatures[temperatureText.index].value;
                            if (t > 90)
                                return "#ff4444";

                            if (t > 75)
                                return "#ffaa00";

                            return Kirigami.Theme.textColor;
                        }
                        font.bold: true
                    }
                }

                Repeater {
                    model: Math.max(0, 2 - compactRoot.parentRef.temperatures.length)

                    Text {
                        width: tempRef.implicitWidth
                        text: "-- °C"
                        font.pixelSize: compactRoot.twoLineLabelPx
                        color: compactRoot.parentRef.themePlaceholderTextColor
                        font.bold: true
                    }
                }
            }
        }
    }

    Component {
        id: networkSection

        CompactSection {
            contentMinimumHeight: compactRoot.iconSz + 10
            horizontalPadding: compactRoot.hotspotHorizontalPadding
            verticalPadding: compactRoot.hotspotVerticalPadding
            hoverColor: compactRoot.parentRef.themeHoverColor
            title: compactRoot.sectionTitle("network")
            summary: compactRoot.sectionSummary("network")
            tooltipActive: !compactRoot.parentRef.expanded
            onClicked: compactRoot.parentRef.openSection(2)

            SvgIcon {
                name: "am-network-symbolic"
                implicitWidth: compactRoot.iconSz
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter
            }

            Canvas {
                id: netMiniGraph

                property color themeTextColor: Kirigami.Theme.textColor

                implicitWidth: 36
                implicitHeight: compactRoot.iconSz + 10
                Layout.alignment: Qt.AlignVCenter
                onThemeTextColorChanged: netMiniGraph.requestPaint()
                onPaint: {
                    let ctx = netMiniGraph.getContext("2d");
                    ctx.clearRect(0, 0, netMiniGraph.width, netMiniGraph.height);
                    let halfHeight = netMiniGraph.height / 2;
                    let dividerGap = 2;
                    let topPadding = 2;
                    let uploadBottom = halfHeight - dividerGap;
                    let uploadHeight = uploadBottom - topPadding;
                    let downloadTop = halfHeight + dividerGap;
                    let downloadHeight = netMiniGraph.height - downloadTop;
                    let borderColor = compactRoot.parentRef.themeBorderColor;
                    ctx.strokeStyle = borderColor;
                    ctx.lineWidth = 1;
                    ctx.strokeRect(0.5, 0.5, netMiniGraph.width - 1, netMiniGraph.height - 1);
                    ctx.beginPath();
                    ctx.moveTo(0, halfHeight);
                    ctx.lineTo(netMiniGraph.width, halfHeight);
                    ctx.stroke();
                    let h = compactRoot.parentRef.netHistory;
                    if (h.length < 2)
                        return;

                    ctx.fillStyle = Qt.rgba(1, 0.27, 0.27, 0.2);
                    ctx.beginPath();
                    ctx.moveTo(0, uploadBottom);
                    for (let i = 0; i < h.length; i++) {
                        let x = i / (h.length - 1) * netMiniGraph.width;
                        let y = uploadBottom - h[i].tx * uploadHeight;
                        ctx.lineTo(x, y);
                    }
                    ctx.lineTo(netMiniGraph.width, uploadBottom);
                    ctx.closePath();
                    ctx.fill();
                    ctx.strokeStyle = "#ff4444";
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    for (let j = 0; j < h.length; j++) {
                        let x2 = j / (h.length - 1) * netMiniGraph.width;
                        let y2 = uploadBottom - h[j].tx * uploadHeight;
                        j === 0 ? ctx.moveTo(x2, y2) : ctx.lineTo(x2, y2);
                    }
                    ctx.stroke();
                    ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2);
                    ctx.beginPath();
                    ctx.moveTo(0, netMiniGraph.height);
                    for (let k = 0; k < h.length; k++) {
                        let x3 = k / (h.length - 1) * netMiniGraph.width;
                        let y3 = netMiniGraph.height - h[k].rx * downloadHeight;
                        ctx.lineTo(x3, y3);
                    }
                    ctx.lineTo(netMiniGraph.width, netMiniGraph.height);
                    ctx.closePath();
                    ctx.fill();
                    ctx.strokeStyle = "#00aaff";
                    ctx.beginPath();
                    for (let l = 0; l < h.length; l++) {
                        let x4 = l / (h.length - 1) * netMiniGraph.width;
                        let y4 = netMiniGraph.height - h[l].rx * downloadHeight;
                        l === 0 ? ctx.moveTo(x4, y4) : ctx.lineTo(x4, y4);
                    }
                    ctx.stroke();
                    ctx.strokeStyle = borderColor;
                    ctx.lineWidth = 1;
                    ctx.strokeRect(0.5, 0.5, netMiniGraph.width - 1, netMiniGraph.height - 1);
                    ctx.beginPath();
                    ctx.moveTo(0, halfHeight);
                    ctx.lineTo(netMiniGraph.width, halfHeight);
                    ctx.stroke();
                }

                Connections {
                    function onNetHistoryChanged() {
                        netMiniGraph.requestPaint();
                    }

                    target: compactRoot.parentRef
                }
            }

            Column {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter

                Row {
                    id: uploadRateRow

                    spacing: 2

                    SvgIcon {
                        name: "am-up-symbolic"
                        width: compactRoot.arrowSz
                        height: compactRoot.arrowSz
                        anchors.verticalCenter: uploadRateRow.verticalCenter
                    }

                    Text {
                        text: compactRoot.parentRef.netUploadCompactSpeed
                        font.pixelSize: compactRoot.twoLineLabelPx
                        color: Kirigami.Theme.textColor
                        font.bold: true
                    }
                }

                Row {
                    id: downloadRateRow

                    spacing: 2

                    SvgIcon {
                        name: "am-down-symbolic"
                        width: compactRoot.arrowSz
                        height: compactRoot.arrowSz
                        anchors.verticalCenter: downloadRateRow.verticalCenter
                    }

                    Text {
                        text: compactRoot.parentRef.netDownloadCompactSpeed
                        font.pixelSize: compactRoot.twoLineLabelPx
                        color: Kirigami.Theme.textColor
                        font.bold: true
                    }
                }
            }
        }
    }

    Component {
        id: storageSection

        CompactSection {
            contentMinimumHeight: compactRoot.iconSz
            horizontalPadding: compactRoot.hotspotHorizontalPadding
            verticalPadding: compactRoot.hotspotVerticalPadding
            hoverColor: compactRoot.parentRef.themeHoverColor
            title: compactRoot.sectionTitle("storage")
            summary: compactRoot.sectionSummary("storage")
            tooltipActive: !compactRoot.parentRef.expanded
            onClicked: compactRoot.parentRef.openSection(3)

            SvgIcon {
                name: "am-harddisk-symbolic"
                implicitWidth: compactRoot.iconSz
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter
            }

            VerticalUsageMeter {
                implicitWidth: Math.round(compactRoot.iconSz * 0.7)
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter
                value: compactRoot.parentRef.storageDevices.length > 0 ? compactRoot.parentRef.storageDevices[0].percent / 100 : 0
                warningThreshold: 1
                criticalThreshold: 0.85
                borderColor: compactRoot.parentRef.themeBorderColor
                minimumFillHeight: 3
            }
        }
    }

    Component {
        id: cpuSection

        CompactSection {
            contentMinimumHeight: compactRoot.iconSz
            horizontalPadding: compactRoot.hotspotHorizontalPadding
            verticalPadding: compactRoot.hotspotVerticalPadding
            hoverColor: compactRoot.parentRef.themeHoverColor
            title: compactRoot.sectionTitle("cpu")
            summary: compactRoot.sectionSummary("cpu")
            tooltipActive: !compactRoot.parentRef.expanded
            onClicked: compactRoot.parentRef.openSection(0)

            SvgIcon {
                name: "am-cpu-symbolic"
                implicitWidth: compactRoot.iconSz
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                id: cpuMeter

                implicitWidth: Math.max(Math.round(compactRoot.iconSz * 0.7), compactRoot.parentRef.cpuCores.length * 4)
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: cpuMeterBorder

                    anchors.fill: cpuMeter
                    color: "transparent"
                    border.color: compactRoot.parentRef.themeBorderColor
                    border.width: 1
                    radius: 2
                }

                Rectangle {
                    visible: compactRoot.parentRef.cpuCores.length === 0
                    height: compactRoot.parentRef.cpuTotal > 0 ? Math.max(1, (cpuMeterBorder.height - 2) * (compactRoot.parentRef.cpuTotal / 100)) : 0
                    color: compactRoot.parentRef.cpuTotal > 80 ? "#ff4444" : "#00aaff"
                    radius: 1

                    anchors {
                        left: cpuMeterBorder.left
                        right: cpuMeterBorder.right
                        bottom: cpuMeterBorder.bottom
                        margins: 1
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                }

                RowLayout {
                    visible: compactRoot.parentRef.cpuCores.length > 0
                    spacing: 0

                    anchors {
                        fill: cpuMeter
                        margins: 1
                    }

                    Repeater {
                        model: compactRoot.parentRef.cpuCores

                        Item {
                            id: cpuCoreMeter

                            required property int index
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Rectangle {
                                anchors.bottom: cpuCoreMeter.bottom
                                width: cpuCoreMeter.width
                                height: cpuCoreMeter.modelData.usage > 0 ? Math.max(1, cpuCoreMeter.height * (cpuCoreMeter.modelData.usage / 100)) : 0
                                color: compactRoot.coreColors[cpuCoreMeter.index % compactRoot.coreColors.length]

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 300
                                    }
                                }
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
                text: compactRoot.parentRef.cpuTotal < 1 ? compactRoot.parentRef.cpuTotal.toFixed(1) + "%" : compactRoot.parentRef.cpuTotal.toFixed(0) + "%"
                font.pixelSize: compactRoot.labelPx
                font.bold: true
                color: Kirigami.Theme.textColor

                Text {
                    id: cpuPctRef

                    visible: false
                    text: "100%"
                    font.pixelSize: compactRoot.labelPx
                    font.bold: true
                }

                Text {
                    id: cpuPctDecRef

                    visible: false
                    text: "0.0%"
                    font.pixelSize: compactRoot.labelPx
                    font.bold: true
                }
            }
        }
    }

    Component {
        id: gpuSection

        CompactSection {
            contentMinimumHeight: compactRoot.iconSz
            horizontalPadding: compactRoot.hotspotHorizontalPadding
            verticalPadding: compactRoot.hotspotVerticalPadding
            hoverColor: compactRoot.parentRef.themeHoverColor
            title: compactRoot.sectionTitle("gpu")
            summary: compactRoot.sectionSummary("gpu")
            tooltipActive: !compactRoot.parentRef.expanded
            onClicked: compactRoot.parentRef.openSection(5)

            SvgIcon {
                name: "am-gpu-symbolic"
                implicitWidth: compactRoot.iconSz
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter
            }

            VerticalUsageMeter {
                implicitWidth: Math.round(compactRoot.iconSz * 0.7)
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter
                value: compactRoot.parentRef.gpuUsage / 100
                warningThreshold: 1
                criticalThreshold: 0.85
                borderColor: compactRoot.parentRef.themeBorderColor
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: gpuPctRef.implicitWidth
                Layout.minimumWidth: gpuPctRef.implicitWidth
                horizontalAlignment: Text.AlignLeft
                text: compactRoot.parentRef.formatPercent(compactRoot.parentRef.gpuUsage)
                font.pixelSize: compactRoot.labelPx
                font.bold: true
                color: Kirigami.Theme.textColor

                Text {
                    id: gpuPctRef

                    visible: false
                    text: "100%"
                    font.pixelSize: compactRoot.labelPx
                    font.bold: true
                }
            }
        }
    }

    Component {
        id: ramSection

        CompactSection {
            contentMinimumHeight: compactRoot.iconSz
            horizontalPadding: compactRoot.hotspotHorizontalPadding
            verticalPadding: compactRoot.hotspotVerticalPadding
            hoverColor: compactRoot.parentRef.themeHoverColor
            title: compactRoot.sectionTitle("ram")
            summary: compactRoot.sectionSummary("ram")
            tooltipActive: !compactRoot.parentRef.expanded
            onClicked: compactRoot.parentRef.openSection(1)

            SvgIcon {
                name: "am-memory-symbolic"
                implicitWidth: compactRoot.iconSz
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter
            }

            VerticalUsageMeter {
                implicitWidth: Math.round(compactRoot.iconSz * 0.7)
                implicitHeight: compactRoot.iconSz
                Layout.alignment: Qt.AlignVCenter
                value: compactRoot.parentRef.ramTotal > 0 ? compactRoot.parentRef.ramUsed / compactRoot.parentRef.ramTotal : 0
                warningThreshold: 1
                criticalThreshold: 0.85
                borderColor: compactRoot.parentRef.themeBorderColor
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: ramPctRef.implicitWidth
                Layout.minimumWidth: ramPctRef.implicitWidth
                horizontalAlignment: Text.AlignLeft
                text: compactRoot.parentRef.ramTotal > 0 ? (compactRoot.parentRef.ramUsed / compactRoot.parentRef.ramTotal * 100).toFixed(0) + "%" : "---%"
                font.pixelSize: compactRoot.labelPx
                font.bold: true
                color: Kirigami.Theme.textColor

                Text {
                    id: ramPctRef

                    visible: false
                    text: "100%"
                    font.pixelSize: compactRoot.labelPx
                    font.bold: true
                }
            }
        }
    }
}
