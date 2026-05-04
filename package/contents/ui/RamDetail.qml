import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: ramDetailRoot

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    readonly property int axisLabelGap: 2
    readonly property int axisLabelWidth: axisLabelSizer.implicitWidth

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
            value: root.ramTotal > 0 ? (root.ramTotal / 1024).toFixed(2) + " GB" : "..."
        }
        StatRow {
            label: "Used:"
            value: root.ramUsed > 0 ? (root.ramUsed / 1024).toFixed(2) + " GB" : "..."
        }
        StatRow {
            label: "Free:"
            value: root.ramFree > 0 ? (root.ramFree / 1024).toFixed(2) + " GB" : "..."
        }
        StatRow {
            label: "Cached:"
            value: root.ramCached > 0 ? (root.ramCached / 1024).toFixed(2) + " GB" : "..."
        }
    }

    // RAM history graph
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 2

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            Layout.minimumHeight: 58

            Canvas {
                id: ramGraph
                anchors.fill: parent
                property color themeTextColor: Kirigami.Theme.textColor

                onThemeTextColorChanged: requestPaint()

                Connections {
                    target: root
                    function onRamHistoryChanged() {
                        ramGraph.requestPaint();
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    var rightInset = axisLabelWidth + axisLabelGap;
                    var plotWidth = Math.max(0, width - rightInset);
                    ctx.clearRect(0, 0, width, height);

                    ctx.fillStyle = root.themeGraphBackgroundColor;
                    ctx.fillRect(0, 0, plotWidth, height);

                    ctx.strokeStyle = root.themeGraphGridColor;
                    ctx.lineWidth = 1;
                    for (var g = 0.25; g <= 1.0; g += 0.25) {
                        ctx.beginPath();
                        ctx.moveTo(0, height * (1 - g));
                        ctx.lineTo(plotWidth, height * (1 - g));
                        ctx.stroke();
                    }

                    var history = root.ramHistory;
                    if (history.length < 2)
                        return;
                    ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2);
                    ctx.beginPath();
                    ctx.moveTo(0, height);
                    for (var i = 0; i < history.length; i++) {
                        var x = i / (history.length - 1) * plotWidth;
                        var y = height - history[i] * height;
                        ctx.lineTo(x, y);
                    }
                    ctx.lineTo(plotWidth, height);
                    ctx.closePath();
                    ctx.fill();

                    ctx.strokeStyle = "#00aaff";
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    for (var j = 0; j < history.length; j++) {
                        var x2 = j / (history.length - 1) * plotWidth;
                        var y2 = height - history[j] * height;
                        if (j === 0)
                            ctx.moveTo(x2, y2);
                        else
                            ctx.lineTo(x2, y2);
                    }
                    ctx.stroke();
                }
            }

            ColumnLayout {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: axisLabelWidth

                Text {
                    Layout.fillWidth: true
                    text: "100%"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
                Item {
                    Layout.fillHeight: true
                }
                Text {
                    Layout.fillWidth: true
                    text: "50%"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
                Item {
                    Layout.fillHeight: true
                }
                Text {
                    Layout.fillWidth: true
                    text: "0%"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                Layout.minimumHeight: 10

                Text {
                    anchors.left: parent.left
                    text: "2 mins ago"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: axisLabelWidth + axisLabelGap
                    text: "now"
                    color: root.themeGraphLabelColor
                    font.pixelSize: 9
                }
            }
        }
    }

    // RAM bar
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 16

        Rectangle {
            anchors.fill: parent
            color: root.themeTrackColor
            radius: 4

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1
                width: root.ramTotal > 0 ? (parent.width - 2) * (root.ramUsed / root.ramTotal) : 0
                color: root.ramTotal > 0 && root.ramUsed / root.ramTotal > 0.85 ? "#ff4444" : "#00aaff"
                radius: 3

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.ramTotal > 0 ? (root.ramUsed / root.ramTotal * 100).toFixed(0) + "%" : "0%"
                color: root.themeBarLabelColor
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
        model: root.ramTopProcesses.length
        delegate: RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing

            readonly property var processInfo: root.ramTopProcesses[index] || ({
                    name: "",
                    memory: 0,
                    memoryValue: "0 KB"
                })

            PlasmaComponents.Label {
                text: processInfo.name
                Layout.fillWidth: true
                font.bold: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                text: processInfo.memoryValue
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                text: processInfo.memory.toFixed(1) + "%"
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
            value: root.swapTotal > 0 ? (root.swapTotal / 1024).toFixed(2) + " GB" : "None"
        }
        StatRow {
            label: "Used:"
            value: root.swapUsed > 0 ? (root.swapUsed / 1024).toFixed(2) + " GB" : "0 GB"
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 16

        Rectangle {
            anchors.fill: parent
            color: root.themeTrackColor
            radius: 4

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1
                width: root.swapTotal > 0 ? (parent.width - 2) * (root.swapUsed / root.swapTotal) : 0
                color: "#ffaa00"
                radius: 3
                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.swapTotal > 0 ? (root.swapUsed / root.swapTotal * 100).toFixed(0) + "%" : "0%"
                color: root.themeBarLabelColor
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }
}
