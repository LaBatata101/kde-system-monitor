import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

Item {
    id: fullRoot

    required property var parentRef

    readonly property int activeSection: fullRoot.parentRef.selectedSection >= 0 ? fullRoot.parentRef.selectedSection : 0

    // Fixed popup width; height grows with the selected section content.
    implicitWidth: Kirigami.Units.gridUnit * 20
    implicitHeight: mainColumn.implicitHeight
    Layout.minimumWidth: fullRoot.implicitWidth
    Layout.preferredWidth: fullRoot.implicitWidth
    Layout.maximumWidth: fullRoot.implicitWidth
    Layout.minimumHeight: fullRoot.implicitHeight
    Layout.preferredHeight: fullRoot.implicitHeight
    Layout.maximumHeight: fullRoot.implicitHeight

    ColumnLayout {
        id: mainColumn

        anchors.left: fullRoot.left
        anchors.right: fullRoot.right
        anchors.top: fullRoot.top
        height: mainColumn.implicitHeight
        spacing: 0

        // CPU
        DetailHeader {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 0
            title: "CPU"
            icon: ""
            showUsageRow: false
        }

        CpuDetail {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 0
            Layout.fillWidth: true
        }

        // GPU
        DetailHeader {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 5 && Plasmoid.configuration.showGpu
            title: "GPU"
            icon: "am-gpu-symbolic"
            value: fullRoot.parentRef.gpuUsageText()
            barValue: fullRoot.parentRef.gpuUsage / 100
            barColor: fullRoot.parentRef.gpuUsage > 85 ? "#ff4444" : "#00aaff"
            showUsageRow: false
        }

        GpuDetail {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 5 && Plasmoid.configuration.showGpu
            Layout.fillWidth: true
        }

        // RAM
        DetailHeader {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 1 && Plasmoid.configuration.showRam
            title: "RAM"
            icon: "am-memory-symbolic"
            value: fullRoot.parentRef.ramTotal > 0 ? (fullRoot.parentRef.ramUsed / 1024).toFixed(1) + " / " + (fullRoot.parentRef.ramTotal / 1024).toFixed(1) + " GB" : "..."
            barValue: fullRoot.parentRef.ramTotal > 0 ? fullRoot.parentRef.ramUsed / fullRoot.parentRef.ramTotal : 0
            barColor: fullRoot.parentRef.ramTotal > 0 && (fullRoot.parentRef.ramUsed / fullRoot.parentRef.ramTotal) > 0.85 ? "#ff4444" : "#00aaff"
            showUsageRow: false
        }

        RamDetail {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 1 && Plasmoid.configuration.showRam
            Layout.fillWidth: true
        }

        // Network
        DetailHeader {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 2
            title: "Network"
            icon: "am-network-symbolic"
            value: "↑ " + fullRoot.parentRef.netUploadSpeed + "  ↓ " + fullRoot.parentRef.netDownloadSpeed
            showBar: false
            showUsageRow: false
        }

        NetworkDetail {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 2
            Layout.fillWidth: true
        }

        // Storage
        DetailHeader {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 3
            title: "Storage"
            icon: "am-harddisk-symbolic"
            value: fullRoot.parentRef.storageDevices.length > 0 ? fullRoot.parentRef.storageDevices[0].used + " / " + fullRoot.parentRef.storageDevices[0].size : "..."
            barValue: fullRoot.parentRef.storageDevices.length > 0 ? fullRoot.parentRef.storageDevices[0].percent / 100 : 0
            barColor: fullRoot.parentRef.storageDevices.length > 0 && fullRoot.parentRef.storageDevices[0].percent > 85 ? "#ff4444" : "#00aaff"
            showUsageRow: false
        }

        StorageDetail {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 3
            Layout.fillWidth: true
        }

        // Temperatures
        DetailHeader {
            parentRef: fullRoot.parentRef
            visible: fullRoot.activeSection === 4
            title: "Temperatures"
            icon: "am-temperature-symbolic"
            value: fullRoot.parentRef.temperatures.length > 0 ? fullRoot.parentRef.temperatures[0].value.toFixed(1) + " °C" : "N/A"
            barValue: fullRoot.parentRef.temperatures.length > 0 ? fullRoot.parentRef.temperatures[0].value / 100 : 0
            barColor: fullRoot.parentRef.temperatures.length > 0 && fullRoot.parentRef.temperatures[0].value > 80 ? "#ff4444" : "#ffaa00"
            showUsageRow: false
        }

        TempDetail {
            parentRef: fullRoot.parentRef
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
                onClicked: fullRoot.parentRef.openSystemResourceMonitor()
                PlasmaComponents.ToolTip.text: systemMonitorButton.Accessible.name

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                contentItem: Item {
                    id: systemMonitorButtonContent

                    SvgIcon {
                        anchors.centerIn: systemMonitorButtonContent
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: Kirigami.Units.iconSizes.smallMedium
                        name: "am-system-monitor-symbolic"
                    }
                }

                background: Rectangle {
                    radius: 3
                    color: systemMonitorButton.hovered ? fullRoot.parentRef.themeHoverColor : "transparent"
                }
            }

            PlasmaComponents.ToolButton {
                id: settingsButton

                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Accessible.name: "Configure Plasmoid"
                onClicked: fullRoot.parentRef.openConfigurationWindow()
                PlasmaComponents.ToolTip.text: settingsButton.Accessible.name

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                contentItem: Item {
                    id: settingsButtonContent

                    SvgIcon {
                        anchors.centerIn: settingsButtonContent
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: Kirigami.Units.iconSizes.smallMedium
                        name: "am-settings-symbolic"
                    }
                }

                background: Rectangle {
                    radius: 3
                    color: settingsButton.hovered ? fullRoot.parentRef.themeHoverColor : "transparent"
                }
            }
        }
    }
}
