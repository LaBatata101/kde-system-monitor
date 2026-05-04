import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    // Fixed popup width; height grows with the selected section content.
    implicitWidth: Kirigami.Units.gridUnit * 20
    implicitHeight: mainColumn.implicitHeight
    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.maximumHeight: implicitHeight

    readonly property int activeSection: root.selectedSection >= 0 ? root.selectedSection : 0

    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: implicitHeight
        spacing: 0

        // CPU
        DetailHeader {
            visible: fullRoot.activeSection === 0
            title: "CPU"
            icon: ""
            showUsageRow: false
        }

        CpuDetail {
            visible: fullRoot.activeSection === 0
            Layout.fillWidth: true
        }

        // GPU
        DetailHeader {
            visible: fullRoot.activeSection === 5 && plasmoid.configuration.showGpu
            title: "GPU"
            icon: "am-gpu-symbolic"
            value: root.gpuUsageText()
            barValue: root.gpuUsage / 100
            barColor: root.gpuUsage > 85 ? "#ff4444" : "#00aaff"
            showUsageRow: false
        }

        GpuDetail {
            visible: fullRoot.activeSection === 5 && plasmoid.configuration.showGpu
            Layout.fillWidth: true
        }

        // RAM
        DetailHeader {
            visible: fullRoot.activeSection === 1 && plasmoid.configuration.showRam
            title: "RAM"
            icon: "am-memory-symbolic"
            value: root.ramTotal > 0 ? (root.ramUsed / 1024).toFixed(1) + " / " + (root.ramTotal / 1024).toFixed(1) + " GB" : "..."
            barValue: root.ramTotal > 0 ? root.ramUsed / root.ramTotal : 0
            barColor: root.ramTotal > 0 && (root.ramUsed / root.ramTotal) > 0.85 ? "#ff4444" : "#00aaff"
            showUsageRow: false
        }

        RamDetail {
            visible: fullRoot.activeSection === 1 && plasmoid.configuration.showRam
            Layout.fillWidth: true
        }

        // Network
        DetailHeader {
            visible: fullRoot.activeSection === 2
            title: "Network"
            icon: "am-network-symbolic"
            value: "↑ " + root.netUploadSpeed + "  ↓ " + root.netDownloadSpeed
            showBar: false
            showUsageRow: false
        }

        NetworkDetail {
            visible: fullRoot.activeSection === 2
            Layout.fillWidth: true
        }

        // Storage
        DetailHeader {
            visible: fullRoot.activeSection === 3
            title: "Storage"
            icon: "am-harddisk-symbolic"
            value: root.storageDevices.length > 0 ? root.storageDevices[0].used + " / " + root.storageDevices[0].size : "..."
            barValue: root.storageDevices.length > 0 ? root.storageDevices[0].percent / 100 : 0
            barColor: root.storageDevices.length > 0 && root.storageDevices[0].percent > 85 ? "#ff4444" : "#00aaff"
            showUsageRow: false
        }

        StorageDetail {
            visible: fullRoot.activeSection === 3
            Layout.fillWidth: true
        }

        // Temperatures
        DetailHeader {
            visible: fullRoot.activeSection === 4
            title: "Temperatures"
            icon: "am-temperature-symbolic"
            value: root.temperatures.length > 0 ? root.temperatures[0].value.toFixed(1) + " °C" : "N/A"
            barValue: root.temperatures.length > 0 ? root.temperatures[0].value / 100 : 0
            barColor: root.temperatures.length > 0 && root.temperatures[0].value > 80 ? "#ff4444" : "#ffaa00"
            showUsageRow: false
        }

        TempDetail {
            visible: fullRoot.activeSection === 4
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.ToolButton {
                id: systemMonitorButton

                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Accessible.name: "Open System Monitor"
                onClicked: root.openSystemResourceMonitor()

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                contentItem: Item {
                    SvgIcon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: width
                        name: "am-system-monitor-symbolic"
                    }
                }

                background: Rectangle {
                    radius: 3
                    color: systemMonitorButton.hovered ? root.themeHoverColor : "transparent"
                }

                PlasmaComponents.ToolTip.text: Accessible.name
            }

            PlasmaComponents.ToolButton {
                id: settingsButton

                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Accessible.name: "Configure Plasmoid"
                onClicked: root.openConfigurationWindow()

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                contentItem: Item {
                    SvgIcon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: width
                        name: "am-settings-symbolic"
                    }
                }

                background: Rectangle {
                    radius: 3
                    color: settingsButton.hovered ? root.themeHoverColor : "transparent"
                }

                PlasmaComponents.ToolTip.text: Accessible.name
            }
        }
    }
}
