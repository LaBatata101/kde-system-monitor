import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    // Fixed popup width; height grows with content up to a max
    implicitWidth:  Kirigami.Units.gridUnit * 22
    implicitHeight: Math.min(mainColumn.implicitHeight + Kirigami.Units.largeSpacing * 2,
                             Kirigami.Units.gridUnit * 38)

    property int expandedSection: -1

    function toggleSection(idx) {
        expandedSection = (expandedSection === idx) ? -1 : idx
    }

    QQC2.ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth:  availableWidth
        contentHeight: mainColumn.implicitHeight
        clip: true

        ColumnLayout {
            id: mainColumn
            width:  scrollView.availableWidth
            // Explicit height is required for QQC2.ScrollView to treat this as
            // scrollable content rather than clamping it to the viewport height.
            height: implicitHeight
            spacing: 0

            // CPU 
            SectionHeader {
                title: "CPU"
                icon: "am-cpu-symbolic"
                value: root.cpuTotal.toFixed(0) + "%"
                barValue: root.cpuTotal / 100
                barColor: root.cpuTotal > 80 ? "#ff4444" : "#00aaff"
                expanded: fullRoot.expandedSection === 0
                onToggled: fullRoot.toggleSection(0)
            }

            CpuDetail {
                visible: fullRoot.expandedSection === 0
                Layout.fillWidth: true
            }

            Kirigami.Separator { Layout.fillWidth: true }

            // RAM 
            SectionHeader {
                visible: plasmoid.configuration.showRam
                title: "RAM"
                icon: "am-memory-symbolic"
                value: root.ramTotal > 0
                    ? (root.ramUsed / 1024).toFixed(1) + " / " + (root.ramTotal / 1024).toFixed(1) + " GB"
                    : "..."
                barValue: root.ramTotal > 0 ? root.ramUsed / root.ramTotal : 0
                barColor: (root.ramUsed / root.ramTotal) > 0.85 ? "#ff4444" : "#00aaff"
                expanded: fullRoot.expandedSection === 1
                onToggled: fullRoot.toggleSection(1)
            }

            RamDetail {
                visible: plasmoid.configuration.showRam && fullRoot.expandedSection === 1
                Layout.fillWidth: true
            }

            Kirigami.Separator {
                visible: plasmoid.configuration.showRam
                Layout.fillWidth: true
            }

            // Network 
            SectionHeader {
                title: "Network"
                icon: "am-network-symbolic"
                value: "↑ " + root.netUploadSpeed + "  ↓ " + root.netDownloadSpeed
                barValue: 0
                showBar: false
                expanded: fullRoot.expandedSection === 2
                onToggled: fullRoot.toggleSection(2)
            }

            NetworkDetail {
                visible: fullRoot.expandedSection === 2
                Layout.fillWidth: true
            }

            Kirigami.Separator { Layout.fillWidth: true }

            // Storage 
            SectionHeader {
                title: "Storage"
                icon: "am-harddisk-symbolic"
                value: root.storageDevices.length > 0
                    ? root.storageDevices[0].used + " / " + root.storageDevices[0].size
                    : "..."
                barValue: root.storageDevices.length > 0 ? root.storageDevices[0].percent / 100 : 0
                barColor: root.storageDevices.length > 0 && root.storageDevices[0].percent > 85
                    ? "#ff4444" : "#00aaff"
                expanded: fullRoot.expandedSection === 3
                onToggled: fullRoot.toggleSection(3)
            }

            StorageDetail {
                visible: fullRoot.expandedSection === 3
                Layout.fillWidth: true
            }

            Kirigami.Separator { Layout.fillWidth: true }

            // Temperatures 
            SectionHeader {
                title: "Temperatures"
                icon: "am-temperature-symbolic"
                value: root.temperatures.length > 0
                    ? root.temperatures[0].value.toFixed(1) + " °C"
                    : "N/A"
                barValue: root.temperatures.length > 0 ? root.temperatures[0].value / 100 : 0
                barColor: root.temperatures.length > 0 && root.temperatures[0].value > 80
                    ? "#ff4444" : "#ffaa00"
                expanded: fullRoot.expandedSection === 4
                onToggled: fullRoot.toggleSection(4)
            }

            TempDetail {
                visible: fullRoot.expandedSection === 4
                Layout.fillWidth: true
            }
        }
    }
}
