import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: configGeneral

    property alias cfg_showCpu: showCpu.checked
    property alias cfg_showRam: showRam.checked
    property alias cfg_showNetwork: showNetwork.checked
    property alias cfg_showStorage: showStorage.checked
    property alias cfg_showTemps: showTemps.checked
    property alias cfg_updateInterval: updateInterval.value
    property string cfg_sectionOrder: "temps,network,storage,cpu,ram"

    property bool cfg_showCpuDefault
    property bool cfg_showRamDefault
    property bool cfg_showNetworkDefault
    property bool cfg_showStorageDefault
    property bool cfg_showTempsDefault
    property int cfg_updateIntervalDefault
    property string cfg_sectionOrderDefault

    readonly property var defaultSectionOrder: ["temps", "network", "storage", "cpu", "ram"]
    property bool updatingSectionOrder: false

    function sectionLabel(key) {
        switch (key) {
        case "cpu": return "CPU"
        case "ram": return "RAM"
        case "network": return "Network"
        case "storage": return "Storage"
        case "temps": return "Temperatures"
        }
        return key
    }

    function normalizedSectionOrder(order) {
        var result = []
        var seen = {}
        var parts = String(order || "").split(",")
        for (var i = 0; i < parts.length; i++) {
            var key = parts[i].trim()
            if (defaultSectionOrder.indexOf(key) !== -1 && !seen[key]) {
                result.push(key)
                seen[key] = true
            }
        }
        for (var j = 0; j < defaultSectionOrder.length; j++) {
            var defaultKey = defaultSectionOrder[j]
            if (!seen[defaultKey]) {
                result.push(defaultKey)
            }
        }
        return result
    }

    function rebuildSectionOrderModel() {
        if (updatingSectionOrder) return
        sectionOrderModel.clear()
        var order = normalizedSectionOrder(cfg_sectionOrder)
        for (var i = 0; i < order.length; i++) {
            sectionOrderModel.append({ key: order[i], label: sectionLabel(order[i]) })
        }
    }

    function syncSectionOrderConfig() {
        var order = []
        for (var i = 0; i < sectionOrderModel.count; i++) {
            order.push(sectionOrderModel.get(i).key)
        }
        updatingSectionOrder = true
        cfg_sectionOrder = order.join(",")
        updatingSectionOrder = false
    }

    function moveSection(from, to) {
        if (to < 0 || to >= sectionOrderModel.count) return
        sectionOrderModel.move(from, to, 1)
        syncSectionOrderConfig()
    }

    onCfg_sectionOrderChanged: rebuildSectionOrderModel()
    Component.onCompleted: rebuildSectionOrderModel()

    ListModel {
        id: sectionOrderModel
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            QQC2.Switch {
                id: showCpu
                text: "CPU"
                Kirigami.FormData.label: "Show:"
            }

            QQC2.Switch {
                id: showRam
                text: "RAM"
            }

            QQC2.Switch {
                id: showNetwork
                text: "Network"
            }

            QQC2.Switch {
                id: showStorage
                text: "Storage"
            }

            QQC2.Switch {
                id: showTemps
                text: "Temperatures"
            }

            QQC2.SpinBox {
                id: updateInterval
                from: 500
                to: 10000
                stepSize: 500
                editable: true
                textFromValue: function(value) { return value + " ms" }
                valueFromText: function(text) { return parseInt(text) || 2000 }
                Kirigami.FormData.label: "Update interval:"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: "Panel section order"
                font.bold: true
            }

            Repeater {
                model: sectionOrderModel

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: model.label
                    }

                    QQC2.ToolButton {
                        enabled: index > 0
                        icon.name: "go-up-symbolic"
                        display: QQC2.AbstractButton.IconOnly
                        onClicked: configGeneral.moveSection(index, index - 1)
                        QQC2.ToolTip.text: "Move up"
                    }

                    QQC2.ToolButton {
                        enabled: index < sectionOrderModel.count - 1
                        icon.name: "go-down-symbolic"
                        display: QQC2.AbstractButton.IconOnly
                        onClicked: configGeneral.moveSection(index, index + 1)
                        QQC2.ToolTip.text: "Move down"
                    }
                }
            }
        }
    }
}
