import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: networkDetailRoot

    required property var parentRef

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    Item {
        height: Kirigami.Units.smallSpacing
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: 4

        StatRow {
            label: "Upload:"
            value: networkDetailRoot.parentRef.netUploadSpeed
        }

        StatRow {
            label: "Download:"
            value: networkDetailRoot.parentRef.netDownloadSpeed
        }
    }

    // Network history graph
    Canvas {
        id: netGraph

        property color themeTextColor: Kirigami.Theme.textColor

        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        height: 80
        onThemeTextColorChanged: netGraph.requestPaint()
        onPaint: {
            let ctx = netGraph.getContext("2d");
            ctx.clearRect(0, 0, netGraph.width, netGraph.height);
            let halfHeight = netGraph.height / 2;
            let dividerGap = 3;
            let topPadding = 3;
            let uploadBottom = halfHeight - dividerGap;
            let uploadHeight = uploadBottom - topPadding;
            let downloadTop = halfHeight + dividerGap;
            let downloadHeight = netGraph.height - downloadTop;
            ctx.fillStyle = networkDetailRoot.parentRef.themeGraphBackgroundColor;
            ctx.fillRect(0, 0, netGraph.width, netGraph.height);
            ctx.strokeStyle = networkDetailRoot.parentRef.themeGraphGridColor;
            ctx.lineWidth = 1;
            for (let g = 0.25; g <= 1; g += 0.25) {
                ctx.beginPath();
                ctx.moveTo(0, uploadBottom - uploadHeight * g);
                ctx.lineTo(netGraph.width, uploadBottom - uploadHeight * g);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(0, downloadTop + downloadHeight * (1 - g));
                ctx.lineTo(netGraph.width, downloadTop + downloadHeight * (1 - g));
                ctx.stroke();
            }
            ctx.strokeStyle = networkDetailRoot.parentRef.themeBorderColor;
            ctx.lineWidth = 1;
            ctx.strokeRect(0.5, 0.5, netGraph.width - 1, netGraph.height - 1);
            ctx.beginPath();
            ctx.moveTo(0, halfHeight);
            ctx.lineTo(netGraph.width, halfHeight);
            ctx.stroke();
            let history = networkDetailRoot.parentRef.netHistory;
            if (history.length < 2)
                return;

            // Upload (red)
            ctx.fillStyle = Qt.rgba(1, 0.27, 0.27, 0.2);
            ctx.beginPath();
            ctx.moveTo(0, uploadBottom);
            for (let i = 0; i < history.length; i++) {
                let x = i / (history.length - 1) * netGraph.width;
                let y = uploadBottom - history[i].tx * uploadHeight;
                ctx.lineTo(x, y);
            }
            ctx.lineTo(netGraph.width, uploadBottom);
            ctx.closePath();
            ctx.fill();
            ctx.strokeStyle = "#ff4444";
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            for (let j = 0; j < history.length; j++) {
                let x2 = j / (history.length - 1) * netGraph.width;
                let y2 = uploadBottom - history[j].tx * uploadHeight;
                if (j === 0)
                    ctx.moveTo(x2, y2);
                else
                    ctx.lineTo(x2, y2);
            }
            ctx.stroke();
            // Download (blue)
            ctx.fillStyle = Qt.rgba(0, 0.6, 1, 0.2);
            ctx.beginPath();
            ctx.moveTo(0, netGraph.height);
            for (let k = 0; k < history.length; k++) {
                let x3 = k / (history.length - 1) * netGraph.width;
                let y3 = netGraph.height - history[k].rx * downloadHeight;
                ctx.lineTo(x3, y3);
            }
            ctx.lineTo(netGraph.width, netGraph.height);
            ctx.closePath();
            ctx.fill();
            ctx.strokeStyle = "#00aaff";
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            for (let l = 0; l < history.length; l++) {
                let x4 = l / (history.length - 1) * netGraph.width;
                let y4 = netGraph.height - history[l].rx * downloadHeight;
                if (l === 0)
                    ctx.moveTo(x4, y4);
                else
                    ctx.lineTo(x4, y4);
            }
            ctx.stroke();
            ctx.strokeStyle = networkDetailRoot.parentRef.themeBorderColor;
            ctx.lineWidth = 1;
            ctx.strokeRect(0.5, 0.5, netGraph.width - 1, netGraph.height - 1);
            ctx.beginPath();
            ctx.moveTo(0, halfHeight);
            ctx.lineTo(netGraph.width, halfHeight);
            ctx.stroke();
        }

        Connections {
            function onNetHistoryChanged() {
                netGraph.requestPaint();
            }

            target: networkDetailRoot.parentRef
        }
    }

    // Legend
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            width: 12
            height: 3
            color: "#00aaff"
            radius: 1
        }

        PlasmaComponents.Label {
            text: "Download"
            font.pixelSize: 10
        }

        Rectangle {
            width: 12
            height: 3
            color: "#ff4444"
            radius: 1
        }

        PlasmaComponents.Label {
            text: "Upload"
            font.pixelSize: 10
        }
    }

    Item {
        height: Kirigami.Units.smallSpacing
    }
}
