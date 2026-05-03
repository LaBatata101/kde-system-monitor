import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    // Fixed popup width; height grows with the selected section content.
    implicitWidth:  Kirigami.Units.gridUnit * 20
    implicitHeight: mainColumn.implicitHeight
    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight

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

        // RAM
        DetailHeader {
            visible: fullRoot.activeSection === 1 && plasmoid.configuration.showRam
            title: "RAM"
            icon: "am-memory-symbolic"
            value: root.ramTotal > 0
                ? (root.ramUsed / 1024).toFixed(1) + " / " + (root.ramTotal / 1024).toFixed(1) + " GB"
                : "..."
            barValue: root.ramTotal > 0 ? root.ramUsed / root.ramTotal : 0
            barColor: (root.ramUsed / root.ramTotal) > 0.85 ? "#ff4444" : "#00aaff"
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
            value: root.storageDevices.length > 0
                ? root.storageDevices[0].used + " / " + root.storageDevices[0].size
                : "..."
            barValue: root.storageDevices.length > 0 ? root.storageDevices[0].percent / 100 : 0
            barColor: root.storageDevices.length > 0 && root.storageDevices[0].percent > 85
                ? "#ff4444" : "#00aaff"
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
            value: root.temperatures.length > 0
                ? root.temperatures[0].value.toFixed(1) + " °C"
                : "N/A"
            barValue: root.temperatures.length > 0 ? root.temperatures[0].value / 100 : 0
            barColor: root.temperatures.length > 0 && root.temperatures[0].value > 80
                ? "#ff4444" : "#ffaa00"
        }

        TempDetail {
            visible: fullRoot.activeSection === 4
            Layout.fillWidth: true
        }
    }
}
