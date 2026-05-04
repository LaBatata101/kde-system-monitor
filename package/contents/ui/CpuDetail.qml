pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: cpuDetailRoot

    required property var parentRef

    readonly property int axisLabelGap: 2
    readonly property int axisLabelWidth: axisLabelSizer.implicitWidth

    function showCoreInfoPopup() {
        coreInfoCloseTimer.stop();
        let pos = cpuHistoryArea.mapToGlobal(Qt.point(cpuHistoryArea.width + Kirigami.Units.smallSpacing, 0));
        coreInfoWindow.x = pos.x;
        coreInfoWindow.y = pos.y;
        coreInfoWindow.visible = true;
    }

    function scheduleCoreInfoPopupClose() {
        coreInfoCloseTimer.restart();
    }

    function updateCoreInfoPopup() {
        if (cpuHistoryHover.hovered || coreInfoPopupHover.hovered)
            cpuDetailRoot.showCoreInfoPopup();
        else
            cpuDetailRoot.scheduleCoreInfoPopupClose();
    }

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Text {
        id: axisLabelSizer

        visible: false
        text: "100%"
        font.pixelSize: 10
    }

    // CPU Model
    PlasmaComponents.Label {
        Layout.fillWidth: true
        text: (cpuDetailRoot.parentRef.cpuModel || "CPU") + (cpuDetailRoot.parentRef.cpuClockMHz > 0 ? " @ " + cpuDetailRoot.parentRef.cpuClockText() : "")
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

            StatRow {
                label: "Total:"
                value: cpuDetailRoot.parentRef.cpuTotal.toFixed(0) + "%"
            }

            StatRow {
                label: "User:"
                value: cpuDetailRoot.parentRef.cpuUser.toFixed(0) + "%"
            }

            StatRow {
                label: "System:"
                value: cpuDetailRoot.parentRef.cpuSystem.toFixed(0) + "%"
            }
        }
    }

    // Overall usage
    Item {
        id: cpuUsageRow

        readonly property int rightInset: cpuDetailRoot.axisLabelWidth + cpuDetailRoot.axisLabelGap

        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        Layout.preferredHeight: 16
        Layout.minimumHeight: 16

        Rectangle {
            id: cpuUsageTrack

            x: 0
            anchors.verticalCenter: cpuUsageRow.verticalCenter
            width: Math.max(0, cpuUsageRow.width - cpuUsageRow.rightInset)
            height: 6
            radius: 3
            color: cpuDetailRoot.parentRef.themeTrackColor

            Rectangle {
                width: cpuUsageTrack.width * Math.min(1, Math.max(0, cpuDetailRoot.parentRef.cpuTotal / 100))
                height: cpuUsageTrack.height
                radius: 3
                color: cpuDetailRoot.parentRef.cpuTotal > 80 ? "#ff4444" : "#00aaff"

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }

        PlasmaComponents.Label {
            anchors.right: cpuUsageRow.right
            anchors.verticalCenter: cpuUsageRow.verticalCenter
            width: cpuDetailRoot.axisLabelWidth
            text: cpuDetailRoot.parentRef.cpuTotal.toFixed(0) + "%"
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

            onHoveredChanged: cpuDetailRoot.updateCoreInfoPopup()
        }

        Item {
            id: cpuGraphContainer

            Layout.fillWidth: true
            Layout.preferredHeight: 58
            Layout.minimumHeight: 58

            Rectangle {
                anchors.fill: cpuGraphContainer
                anchors.margins: -Math.round(Kirigami.Units.smallSpacing / 2)
                radius: 4
                color: cpuHistoryHover.hovered ? cpuDetailRoot.parentRef.themeHoverColor : "transparent"
            }

            Canvas {
                id: cpuGraph

                property color themeTextColor: Kirigami.Theme.textColor

                anchors.fill: cpuGraphContainer
                onThemeTextColorChanged: cpuGraph.requestPaint()
                onPaint: {
                    let ctx = cpuGraph.getContext("2d");
                    let rightInset = cpuDetailRoot.axisLabelWidth + cpuDetailRoot.axisLabelGap;
                    let plotWidth = Math.max(0, cpuGraph.width - rightInset);
                    ctx.clearRect(0, 0, cpuGraph.width, cpuGraph.height);
                    // Background
                    ctx.fillStyle = cpuDetailRoot.parentRef.themeGraphBackgroundColor;
                    ctx.fillRect(0, 0, plotWidth, cpuGraph.height);
                    // Grid lines
                    ctx.strokeStyle = cpuDetailRoot.parentRef.themeGraphGridColor;
                    ctx.lineWidth = 1;
                    for (let g = 0.25; g <= 1; g += 0.25) {
                        ctx.beginPath();
                        ctx.moveTo(0, cpuGraph.height * (1 - g));
                        ctx.lineTo(plotWidth, cpuGraph.height * (1 - g));
                        ctx.stroke();
                    }
                    let history = cpuDetailRoot.parentRef.cpuHistory;
                    if (history.length < 2)
                        return;

                    // Fill area
                    ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2);
                    ctx.beginPath();
                    ctx.moveTo(0, cpuGraph.height);
                    for (let i = 0; i < history.length; i++) {
                        let x = i / (history.length - 1) * plotWidth;
                        let y = cpuGraph.height - history[i] * cpuGraph.height;
                        ctx.lineTo(x, y);
                    }
                    ctx.lineTo(plotWidth, cpuGraph.height);
                    ctx.closePath();
                    ctx.fill();
                    // Line
                    ctx.strokeStyle = "#00aaff";
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    for (let j = 0; j < history.length; j++) {
                        let x2 = j / (history.length - 1) * plotWidth;
                        let y2 = cpuGraph.height - history[j] * cpuGraph.height;
                        if (j === 0)
                            ctx.moveTo(x2, y2);
                        else
                            ctx.lineTo(x2, y2);
                    }
                    ctx.stroke();
                }

                Connections {
                    function onCpuHistoryChanged() {
                        cpuGraph.requestPaint();
                    }

                    target: cpuDetailRoot.parentRef
                }
            }

            ColumnLayout {
                anchors.top: cpuGraphContainer.top
                anchors.bottom: cpuGraphContainer.bottom
                anchors.right: cpuGraphContainer.right
                width: cpuDetailRoot.axisLabelWidth

                Text {
                    Layout.fillWidth: true
                    text: "100%"
                    color: cpuDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "50%"
                    color: cpuDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "0%"
                    color: cpuDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                id: cpuXAxisContainer

                Layout.fillWidth: true
                Layout.preferredHeight: 10
                Layout.minimumHeight: 10

                Rectangle {
                    anchors.fill: cpuXAxisContainer
                    anchors.leftMargin: -Math.round(Kirigami.Units.smallSpacing / 2)
                    anchors.rightMargin: -Math.round(Kirigami.Units.smallSpacing / 2)
                    radius: 4
                    color: cpuHistoryHover.hovered ? cpuDetailRoot.parentRef.themeHoverColor : "transparent"
                }

                Text {
                    anchors.left: cpuXAxisContainer.left
                    text: "5 mins ago"
                    color: cpuDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                }

                Text {
                    anchors.right: cpuXAxisContainer.right
                    anchors.rightMargin: cpuDetailRoot.axisLabelWidth + cpuDetailRoot.axisLabelGap
                    text: "now"
                    color: cpuDetailRoot.parentRef.themeGraphLabelColor
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
        model: cpuDetailRoot.parentRef.topProcesses.length

        delegate: RowLayout {
            id: cpuProcessRow

            required property int index

            readonly property var processInfo: cpuDetailRoot.parentRef.topProcesses[cpuProcessRow.index] || ({
                    "name": "",
                    "cpu": 0
                })

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: cpuProcessRow.processInfo.name
                Layout.fillWidth: true
                font.bold: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            PlasmaComponents.Label {
                text: cpuProcessRow.processInfo.cpu.toFixed(1) + "%"
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
        visible: cpuDetailRoot.parentRef.gpus.length > 0
    }

    Repeater {
        model: cpuDetailRoot.parentRef.gpus

        delegate: PlasmaComponents.Label {
            id: gpuLabel

            required property string modelData

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            text: gpuLabel.modelData
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
        text: cpuDetailRoot.parentRef.systemUptime || "..."
        font.pixelSize: 10
    }

    Window {
        id: coreInfoWindow

        width: Math.max(Kirigami.Units.gridUnit * 16, cpuDetailRoot.width - Kirigami.Units.smallSpacing * 2)
        height: Math.min(coreInfoContent.implicitHeight + Kirigami.Units.smallSpacing * 2, Kirigami.Units.gridUnit * 18)
        visible: false
        flags: Qt.ToolTip | Qt.FramelessWindowHint
        color: "transparent"

        Rectangle {
            anchors.fill: coreInfoWindow.contentItem
            color: Kirigami.Theme.backgroundColor
            border.color: cpuDetailRoot.parentRef.themeBorderColor
            border.width: 1
            radius: 4
        }

        CpuCoreInfo {
            id: coreInfoContent

            parentRef: cpuDetailRoot.parentRef
            anchors.fill: coreInfoWindow.contentItem
            anchors.margins: Kirigami.Units.smallSpacing

            HoverHandler {
                id: coreInfoPopupHover

                onHoveredChanged: cpuDetailRoot.updateCoreInfoPopup()
            }
        }
    }

    Timer {
        id: coreInfoCloseTimer

        interval: 200
        repeat: false
        onTriggered: {
            if (!cpuHistoryHover.hovered && !coreInfoPopupHover.hovered)
                coreInfoWindow.visible = false;
        }
    }
}
