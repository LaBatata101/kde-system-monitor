pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: storageDetailRoot

    required property var parentRef

    readonly property int axisLabelGap: 2
    readonly property int axisLabelWidth: axisLabelSizer.implicitWidth
    readonly property real axisScale: 1.04858e+07

    function formatAxisRate(bytes) {
        if (bytes < 1.07374e+09) {
            let mib = bytes / 1.04858e+06;
            return mib < 10 ? mib.toFixed(1) + " MB/s" : mib.toFixed(0) + " MB/s";
        }
        return (bytes / 1.07374e+09).toFixed(1) + " GB/s";
    }

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Text {
        id: axisLabelSizer

        visible: false
        text: "999 MB/s"
        font.pixelSize: 10
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }

    // Storage read/write history graph
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 2

        Item {
            id: storageGraphContainer

            Layout.fillWidth: true
            Layout.preferredHeight: 80
            Layout.minimumHeight: 80

            Canvas {
                id: storageGraph

                property color themeTextColor: Kirigami.Theme.textColor

                anchors.fill: storageGraphContainer
                onThemeTextColorChanged: storageGraph.requestPaint()
                onPaint: {
                    let ctx = storageGraph.getContext("2d");
                    let rightInset = storageDetailRoot.axisLabelWidth + storageDetailRoot.axisLabelGap;
                    let plotWidth = Math.max(0, storageGraph.width - rightInset);
                    let halfHeight = storageGraph.height / 2;
                    let dividerGap = 3;
                    let readBottom = halfHeight - dividerGap;
                    let readHeight = readBottom;
                    let writeTop = halfHeight + dividerGap;
                    let writeHeight = storageGraph.height - writeTop;
                    let scale = storageDetailRoot.axisScale;
                    ctx.clearRect(0, 0, storageGraph.width, storageGraph.height);
                    ctx.fillStyle = storageDetailRoot.parentRef.themeGraphBackgroundColor;
                    ctx.fillRect(0, 0, plotWidth, storageGraph.height);
                    ctx.strokeStyle = storageDetailRoot.parentRef.themeGraphGridColor;
                    ctx.lineWidth = 1;
                    for (let g = 0.25; g <= 1; g += 0.25) {
                        ctx.beginPath();
                        ctx.moveTo(0, readBottom - readHeight * g);
                        ctx.lineTo(plotWidth, readBottom - readHeight * g);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(0, writeTop + writeHeight * (1 - g));
                        ctx.lineTo(plotWidth, writeTop + writeHeight * (1 - g));
                        ctx.stroke();
                    }
                    ctx.strokeStyle = storageDetailRoot.parentRef.themeBorderColor;
                    ctx.lineWidth = 1;
                    ctx.strokeRect(0.5, 0.5, plotWidth - 1, storageGraph.height - 1);
                    ctx.beginPath();
                    ctx.moveTo(0, halfHeight);
                    ctx.lineTo(plotWidth, halfHeight);
                    ctx.stroke();
                    let history = storageDetailRoot.parentRef.storageHistory;
                    if (history.length < 2)
                        return;

                    ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2);
                    ctx.beginPath();
                    ctx.moveTo(0, readBottom);
                    for (let i = 0; i < history.length; i++) {
                        let x = i / (history.length - 1) * plotWidth;
                        let y = readBottom - Math.min(1, history[i].read / scale) * readHeight;
                        ctx.lineTo(x, y);
                    }
                    ctx.lineTo(plotWidth, readBottom);
                    ctx.closePath();
                    ctx.fill();
                    ctx.strokeStyle = "#00aaff";
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    for (let j = 0; j < history.length; j++) {
                        let x2 = j / (history.length - 1) * plotWidth;
                        let y2 = readBottom - Math.min(1, history[j].read / scale) * readHeight;
                        if (j === 0)
                            ctx.moveTo(x2, y2);
                        else
                            ctx.lineTo(x2, y2);
                    }
                    ctx.stroke();
                    ctx.fillStyle = Qt.rgba(1, 0.27, 0.27, 0.2);
                    ctx.beginPath();
                    ctx.moveTo(0, storageGraph.height);
                    for (let k = 0; k < history.length; k++) {
                        let x3 = k / (history.length - 1) * plotWidth;
                        let y3 = storageGraph.height - Math.min(1, history[k].write / scale) * writeHeight;
                        ctx.lineTo(x3, y3);
                    }
                    ctx.lineTo(plotWidth, storageGraph.height);
                    ctx.closePath();
                    ctx.fill();
                    ctx.strokeStyle = "#ff4444";
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    for (let l = 0; l < history.length; l++) {
                        let x4 = l / (history.length - 1) * plotWidth;
                        let y4 = storageGraph.height - Math.min(1, history[l].write / scale) * writeHeight;
                        if (l === 0)
                            ctx.moveTo(x4, y4);
                        else
                            ctx.lineTo(x4, y4);
                    }
                    ctx.stroke();
                    ctx.strokeStyle = storageDetailRoot.parentRef.themeBorderColor;
                    ctx.lineWidth = 1;
                    ctx.strokeRect(0.5, 0.5, plotWidth - 1, storageGraph.height - 1);
                    ctx.beginPath();
                    ctx.moveTo(0, halfHeight);
                    ctx.lineTo(plotWidth, halfHeight);
                    ctx.stroke();
                }

                Connections {
                    function onStorageHistoryChanged() {
                        storageGraph.requestPaint();
                    }

                    target: storageDetailRoot.parentRef
                }
            }

            Item {
                id: storageYAxisLabels

                anchors.top: storageGraphContainer.top
                anchors.bottom: storageGraphContainer.bottom
                anchors.right: storageGraphContainer.right
                width: storageDetailRoot.axisLabelWidth

                Text {
                    y: -6
                    width: storageYAxisLabels.width
                    text: storageDetailRoot.formatAxisRate(storageDetailRoot.axisScale)
                    color: storageDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    id: storageMidReadLabel

                    y: storageYAxisLabels.height / 4 - storageMidReadLabel.height / 2
                    width: storageYAxisLabels.width
                    text: storageDetailRoot.formatAxisRate(storageDetailRoot.axisScale / 2)
                    color: storageDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    anchors.verticalCenter: storageYAxisLabels.verticalCenter
                    width: storageYAxisLabels.width
                    text: storageDetailRoot.formatAxisRate(storageDetailRoot.axisScale)
                    color: storageDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    id: storageMidWriteLabel

                    y: storageYAxisLabels.height * 0.75 - storageMidWriteLabel.height / 2
                    width: storageYAxisLabels.width
                    text: storageDetailRoot.formatAxisRate(storageDetailRoot.axisScale / 2)
                    color: storageDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    y: storageYAxisLabels.height - 6
                    width: storageYAxisLabels.width
                    text: "0 MB/s"
                    color: storageDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        Item {
            id: storageTimelineContainer

            Layout.fillWidth: true
            Layout.preferredHeight: storageXAxisLabels.height + storageLegend.implicitHeight
            Layout.minimumHeight: storageXAxisLabels.height + storageLegend.implicitHeight

            Item {
                id: storageXAxisLabels

                anchors.left: storageTimelineContainer.left
                anchors.right: storageTimelineContainer.right
                height: Math.max(storagePastLabel.implicitHeight, storageNowLabel.implicitHeight)

                PlasmaComponents.Label {
                    id: storagePastLabel

                    anchors.left: storageXAxisLabels.left
                    anchors.top: storageXAxisLabels.top
                    text: "5min ago"
                    color: storageDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                }

                PlasmaComponents.Label {
                    id: storageNowLabel

                    anchors.right: storageXAxisLabels.right
                    anchors.rightMargin: storageDetailRoot.axisLabelWidth + storageDetailRoot.axisLabelGap
                    anchors.top: storageXAxisLabels.top
                    text: "now"
                    color: storageDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                }
            }

            RowLayout {
                id: storageLegend

                anchors.left: storageTimelineContainer.left
                anchors.top: storageXAxisLabels.bottom
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    width: 12
                    height: 3
                    color: "#00aaff"
                    radius: 1
                }

                PlasmaComponents.Label {
                    text: "Read " + storageDetailRoot.parentRef.storageReadSpeed
                    font.pixelSize: 10
                }

                Rectangle {
                    width: 12
                    height: 3
                    color: "#ff4444"
                    radius: 1
                }

                PlasmaComponents.Label {
                    text: "Write " + storageDetailRoot.parentRef.storageWriteSpeed
                    font.pixelSize: 10
                }
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
        model: storageDetailRoot.parentRef.storageBlockDevices

        delegate: ColumnLayout {
            id: storageDeviceDelegate

            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: 3

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: storageDeviceDelegate.modelData.name
                    font.bold: true
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                PlasmaComponents.Label {
                    text: storageDeviceDelegate.modelData.hasUsage ? storageDeviceDelegate.modelData.used + " / " + storageDeviceDelegate.modelData.usageSize : storageDeviceDelegate.modelData.usageSize
                    font.pixelSize: 10
                }
            }

            PlasmaComponents.Label {
                text: storageDeviceDelegate.modelData.path + " • " + storageDeviceDelegate.modelData.detail
                font.pixelSize: 9
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
            }

            Item {
                id: storageDeviceUsageBar

                visible: storageDeviceDelegate.modelData.hasUsage
                Layout.fillWidth: true
                height: 14

                Rectangle {
                    id: storageDeviceUsageTrack

                    anchors.fill: storageDeviceUsageBar
                    color: storageDetailRoot.parentRef.themeTrackColor
                    radius: 3

                    Rectangle {
                        anchors.left: storageDeviceUsageTrack.left
                        anchors.top: storageDeviceUsageTrack.top
                        anchors.bottom: storageDeviceUsageTrack.bottom
                        anchors.margins: 1
                        width: (storageDeviceUsageTrack.width - 2) * (storageDeviceDelegate.modelData.percent / 100)
                        color: storageDeviceDelegate.modelData.percent > 85 ? "#ff4444" : storageDeviceDelegate.modelData.percent > 70 ? "#ffaa00" : "#00aaff"
                        radius: 2
                    }

                    Text {
                        anchors.centerIn: storageDeviceUsageTrack
                        text: storageDeviceDelegate.modelData.percent + "%"
                        color: storageDetailRoot.parentRef.themeBarLabelColor
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            Item {
                height: 2
            }
        }
    }

    PlasmaComponents.Label {
        visible: storageDetailRoot.parentRef.storageBlockDevices.length === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "No storage devices found"
        font.italic: true
        font.pixelSize: 11
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }
}
