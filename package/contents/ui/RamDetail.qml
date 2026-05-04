pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: ramDetailRoot

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

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 4

        StatRow {
            label: "Total:"
            value: ramDetailRoot.parentRef.ramTotal > 0 ? (ramDetailRoot.parentRef.ramTotal / 1024).toFixed(2) + " GB" : "..."
        }

        StatRow {
            label: "Used:"
            value: ramDetailRoot.parentRef.ramUsed > 0 ? (ramDetailRoot.parentRef.ramUsed / 1024).toFixed(2) + " GB" : "..."
        }

        StatRow {
            label: "Free:"
            value: ramDetailRoot.parentRef.ramFree > 0 ? (ramDetailRoot.parentRef.ramFree / 1024).toFixed(2) + " GB" : "..."
        }

        StatRow {
            label: "Cached:"
            value: ramDetailRoot.parentRef.ramCached > 0 ? (ramDetailRoot.parentRef.ramCached / 1024).toFixed(2) + " GB" : "..."
        }
    }

    // RAM history graph
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 2

        Item {
            id: ramGraphContainer

            Layout.fillWidth: true
            Layout.preferredHeight: 58
            Layout.minimumHeight: 58

            Canvas {
                id: ramGraph

                property color themeTextColor: Kirigami.Theme.textColor

                anchors.fill: ramGraphContainer
                onThemeTextColorChanged: ramGraph.requestPaint()
                onPaint: {
                    let ctx = ramGraph.getContext("2d");
                    let rightInset = ramDetailRoot.axisLabelWidth + ramDetailRoot.axisLabelGap;
                    let plotWidth = Math.max(0, ramGraph.width - rightInset);
                    ctx.clearRect(0, 0, ramGraph.width, ramGraph.height);
                    ctx.fillStyle = ramDetailRoot.parentRef.themeGraphBackgroundColor;
                    ctx.fillRect(0, 0, plotWidth, ramGraph.height);
                    ctx.strokeStyle = ramDetailRoot.parentRef.themeGraphGridColor;
                    ctx.lineWidth = 1;
                    for (let g = 0.25; g <= 1; g += 0.25) {
                        ctx.beginPath();
                        ctx.moveTo(0, ramGraph.height * (1 - g));
                        ctx.lineTo(plotWidth, ramGraph.height * (1 - g));
                        ctx.stroke();
                    }
                    let history = ramDetailRoot.parentRef.ramHistory;
                    if (history.length < 2)
                        return;

                    ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2);
                    ctx.beginPath();
                    ctx.moveTo(0, ramGraph.height);
                    for (let i = 0; i < history.length; i++) {
                        let x = i / (history.length - 1) * plotWidth;
                        let y = ramGraph.height - history[i] * ramGraph.height;
                        ctx.lineTo(x, y);
                    }
                    ctx.lineTo(plotWidth, ramGraph.height);
                    ctx.closePath();
                    ctx.fill();
                    ctx.strokeStyle = "#00aaff";
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    for (let j = 0; j < history.length; j++) {
                        let x2 = j / (history.length - 1) * plotWidth;
                        let y2 = ramGraph.height - history[j] * ramGraph.height;
                        if (j === 0)
                            ctx.moveTo(x2, y2);
                        else
                            ctx.lineTo(x2, y2);
                    }
                    ctx.stroke();
                }

                Connections {
                    function onRamHistoryChanged() {
                        ramGraph.requestPaint();
                    }

                    target: ramDetailRoot.parentRef
                }
            }

            ColumnLayout {
                anchors.top: ramGraphContainer.top
                anchors.bottom: ramGraphContainer.bottom
                anchors.right: ramGraphContainer.right
                width: ramDetailRoot.axisLabelWidth

                Text {
                    Layout.fillWidth: true
                    text: "100%"
                    color: ramDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "50%"
                    color: ramDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "0%"
                    color: ramDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                id: ramXAxisContainer

                Layout.fillWidth: true
                Layout.preferredHeight: 10
                Layout.minimumHeight: 10

                Text {
                    anchors.left: ramXAxisContainer.left
                    text: "2 mins ago"
                    color: ramDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                }

                Text {
                    anchors.right: ramXAxisContainer.right
                    anchors.rightMargin: ramDetailRoot.axisLabelWidth + ramDetailRoot.axisLabelGap
                    text: "now"
                    color: ramDetailRoot.parentRef.themeGraphLabelColor
                    font.pixelSize: 9
                }
            }
        }
    }

    // RAM bar
    Item {
        id: ramUsageBar

        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 16

        Rectangle {
            id: ramUsageTrack

            anchors.fill: ramUsageBar
            color: ramDetailRoot.parentRef.themeTrackColor
            radius: 4

            Rectangle {
                anchors.left: ramUsageTrack.left
                anchors.top: ramUsageTrack.top
                anchors.bottom: ramUsageTrack.bottom
                anchors.margins: 1
                width: ramDetailRoot.parentRef.ramTotal > 0 ? (ramUsageTrack.width - 2) * (ramDetailRoot.parentRef.ramUsed / ramDetailRoot.parentRef.ramTotal) : 0
                color: ramDetailRoot.parentRef.ramTotal > 0 && ramDetailRoot.parentRef.ramUsed / ramDetailRoot.parentRef.ramTotal > 0.85 ? "#ff4444" : "#00aaff"
                radius: 3

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }

            Text {
                anchors.centerIn: ramUsageTrack
                text: ramDetailRoot.parentRef.ramTotal > 0 ? (ramDetailRoot.parentRef.ramUsed / ramDetailRoot.parentRef.ramTotal * 100).toFixed(0) + "%" : "0%"
                color: ramDetailRoot.parentRef.themeBarLabelColor
                font.pixelSize: 9
                font.bold: true
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
        model: ramDetailRoot.parentRef.ramTopProcesses.length

        delegate: RowLayout {
            id: ramProcessRow

            required property int index

            readonly property var processInfo: ramDetailRoot.parentRef.ramTopProcesses[ramProcessRow.index] || ({
                    "name": "",
                    "memory": 0,
                    "memoryValue": "0 KB"
                })

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: ramProcessRow.processInfo.name
                Layout.fillWidth: true
                font.bold: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            PlasmaComponents.Label {
                text: ramProcessRow.processInfo.memoryValue
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            PlasmaComponents.Label {
                text: ramProcessRow.processInfo.memory.toFixed(1) + "%"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    // Swap
    PlasmaComponents.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Swap"
        font.bold: true
        font.pixelSize: 11
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 4

        StatRow {
            label: "Total:"
            value: ramDetailRoot.parentRef.swapTotal > 0 ? (ramDetailRoot.parentRef.swapTotal / 1024).toFixed(2) + " GB" : "None"
        }

        StatRow {
            label: "Used:"
            value: ramDetailRoot.parentRef.swapUsed > 0 ? (ramDetailRoot.parentRef.swapUsed / 1024).toFixed(2) + " GB" : "0 GB"
        }
    }

    Item {
        id: swapUsageBar

        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 16

        Rectangle {
            id: swapUsageTrack

            anchors.fill: swapUsageBar
            color: ramDetailRoot.parentRef.themeTrackColor
            radius: 4

            Rectangle {
                anchors.left: swapUsageTrack.left
                anchors.top: swapUsageTrack.top
                anchors.bottom: swapUsageTrack.bottom
                anchors.margins: 1
                width: ramDetailRoot.parentRef.swapTotal > 0 ? (swapUsageTrack.width - 2) * (ramDetailRoot.parentRef.swapUsed / ramDetailRoot.parentRef.swapTotal) : 0
                color: "#ffaa00"
                radius: 3

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }

            Text {
                anchors.centerIn: swapUsageTrack
                text: ramDetailRoot.parentRef.swapTotal > 0 ? (ramDetailRoot.parentRef.swapUsed / ramDetailRoot.parentRef.swapTotal * 100).toFixed(0) + "%" : "0%"
                color: ramDetailRoot.parentRef.themeBarLabelColor
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }
}
