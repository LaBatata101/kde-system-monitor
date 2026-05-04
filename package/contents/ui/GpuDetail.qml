pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: gpuDetailRoot

    required property var parentRef

    readonly property int axisLabelGap: 2
    readonly property int axisLabelWidth: axisLabelSizer.implicitWidth

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Text {
        id: axisLabelSizer

        visible: false
        text: "100%"
        font.pixelSize: 10
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }

    Repeater {
        model: gpuDetailRoot.parentRef.gpuDevices.length > 0 ? gpuDetailRoot.parentRef.gpuDevices : [
            {
                "name": gpuDetailRoot.parentRef.gpuNameText(),
                "usage": gpuDetailRoot.parentRef.gpuUsage,
                "clockMHz": gpuDetailRoot.parentRef.gpuClockMHz,
                "temperature": gpuDetailRoot.parentRef.gpuTemperature,
                "memoryUsedMiB": gpuDetailRoot.parentRef.gpuMemoryUsedMiB,
                "memoryTotalMiB": gpuDetailRoot.parentRef.gpuMemoryTotalMiB,
                "history": gpuDetailRoot.parentRef.gpuHistory
            }
        ]

        delegate: ColumnLayout {
            id: gpuDeviceDelegate

            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: 2

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: gpuDeviceDelegate.modelData.name
                font.pixelSize: 11
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            StatRow {
                label: "Clock:"
                value: gpuDetailRoot.parentRef.gpuDeviceClockText(gpuDeviceDelegate.modelData)
            }

            StatRow {
                label: "Memory:"
                value: gpuDetailRoot.parentRef.gpuDeviceMemoryText(gpuDeviceDelegate.modelData)
            }

            StatRow {
                label: "Temperature:"
                value: gpuDetailRoot.parentRef.gpuDeviceTemperatureText(gpuDeviceDelegate.modelData)
            }

            StatRow {
                label: "Usage:"
                value: gpuDetailRoot.parentRef.gpuDeviceUsageText(gpuDeviceDelegate.modelData)
            }

            Item {
                id: gpuUsageRow

                readonly property int rightInset: gpuDetailRoot.axisLabelWidth + gpuDetailRoot.axisLabelGap

                Layout.fillWidth: true
                Layout.preferredHeight: 16
                Layout.minimumHeight: 16

                Rectangle {
                    id: gpuUsageTrack

                    x: 0
                    anchors.verticalCenter: gpuUsageRow.verticalCenter
                    width: Math.max(0, gpuUsageRow.width - gpuUsageRow.rightInset)
                    height: 6
                    radius: 3
                    color: gpuDetailRoot.parentRef.themeTrackColor

                    Rectangle {
                        width: gpuUsageTrack.width * Math.min(1, Math.max(0, (gpuDeviceDelegate.modelData.usage || 0) / 100))
                        height: gpuUsageTrack.height
                        radius: 3
                        color: (gpuDeviceDelegate.modelData.usage || 0) > 85 ? "#ff4444" : "#00aaff"

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    anchors.right: gpuUsageRow.right
                    anchors.verticalCenter: gpuUsageRow.verticalCenter
                    width: gpuDetailRoot.axisLabelWidth
                    text: (gpuDeviceDelegate.modelData.usage || 0).toFixed(0) + "%"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                }
            }

            Item {
                id: gpuGraphContainer

                Layout.fillWidth: true
                Layout.preferredHeight: 80
                Layout.minimumHeight: 80

                Canvas {
                    id: gpuGraph

                    property color themeTextColor: Kirigami.Theme.textColor

                    anchors.fill: gpuGraphContainer
                    onThemeTextColorChanged: gpuGraph.requestPaint()
                    onPaint: {
                        let ctx = gpuGraph.getContext("2d");
                        let rightInset = gpuDetailRoot.axisLabelWidth + gpuDetailRoot.axisLabelGap;
                        let plotWidth = Math.max(0, gpuGraph.width - rightInset);
                        ctx.clearRect(0, 0, gpuGraph.width, gpuGraph.height);
                        ctx.fillStyle = gpuDetailRoot.parentRef.themeGraphBackgroundColor;
                        ctx.fillRect(0, 0, plotWidth, gpuGraph.height);
                        ctx.strokeStyle = gpuDetailRoot.parentRef.themeGraphGridColor;
                        ctx.lineWidth = 1;
                        for (let g = 0.25; g <= 1; g += 0.25) {
                            ctx.beginPath();
                            ctx.moveTo(0, gpuGraph.height * (1 - g));
                            ctx.lineTo(plotWidth, gpuGraph.height * (1 - g));
                            ctx.stroke();
                        }
                        ctx.strokeStyle = gpuDetailRoot.parentRef.themeBorderColor;
                        ctx.lineWidth = 1;
                        ctx.strokeRect(0.5, 0.5, plotWidth - 1, gpuGraph.height - 1);
                        let history = gpuDeviceDelegate.modelData.history || [];
                        if (history.length < 2)
                            return;

                        ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2);
                        ctx.beginPath();
                        ctx.moveTo(0, gpuGraph.height);
                        for (let i = 0; i < history.length; i++) {
                            let x = i / (history.length - 1) * plotWidth;
                            let y = gpuGraph.height - history[i] * gpuGraph.height;
                            ctx.lineTo(x, y);
                        }
                        ctx.lineTo(plotWidth, gpuGraph.height);
                        ctx.closePath();
                        ctx.fill();
                        ctx.strokeStyle = "#00aaff";
                        ctx.lineWidth = 1.5;
                        ctx.beginPath();
                        for (let j = 0; j < history.length; j++) {
                            let x2 = j / (history.length - 1) * plotWidth;
                            let y2 = gpuGraph.height - history[j] * gpuGraph.height;
                            if (j === 0)
                                ctx.moveTo(x2, y2);
                            else
                                ctx.lineTo(x2, y2);
                        }
                        ctx.stroke();
                    }

                    Connections {
                        function onGpuDevicesChanged() {
                            gpuGraph.requestPaint();
                        }

                        target: gpuDetailRoot.parentRef
                    }
                }

                ColumnLayout {
                    anchors.top: gpuGraphContainer.top
                    anchors.bottom: gpuGraphContainer.bottom
                    anchors.right: gpuGraphContainer.right
                    width: gpuDetailRoot.axisLabelWidth

                    Text {
                        Layout.fillWidth: true
                        text: "100%"
                        color: gpuDetailRoot.parentRef.themeGraphLabelColor
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignLeft
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "50%"
                        color: gpuDetailRoot.parentRef.themeGraphLabelColor
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignLeft
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "0%"
                        color: gpuDetailRoot.parentRef.themeGraphLabelColor
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    id: gpuXAxisContainer

                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    Layout.minimumHeight: 10

                    Text {
                        anchors.left: gpuXAxisContainer.left
                        text: "5 mins ago"
                        color: gpuDetailRoot.parentRef.themeGraphLabelColor
                        font.pixelSize: 9
                    }

                    Text {
                        anchors.right: gpuXAxisContainer.right
                        anchors.rightMargin: gpuDetailRoot.axisLabelWidth + gpuDetailRoot.axisLabelGap
                        text: "now"
                        color: gpuDetailRoot.parentRef.themeGraphLabelColor
                        font.pixelSize: 9
                    }
                }
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
        model: gpuDetailRoot.parentRef.gpuProcesses

        delegate: RowLayout {
            id: gpuProcessRow

            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: gpuProcessRow.modelData.name
                Layout.fillWidth: true
                font.bold: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            PlasmaComponents.Label {
                text: gpuDetailRoot.parentRef.formatMemoryMib(gpuProcessRow.modelData.memoryMiB)
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }
}
