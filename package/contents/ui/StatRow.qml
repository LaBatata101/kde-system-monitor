import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

RowLayout {
    id: statRow

    property string label: ""
    property string value: ""

    Layout.fillWidth: true

    PlasmaComponents.Label {
        text: statRow.label
        font.pixelSize: 11
        Layout.fillWidth: true
    }

    PlasmaComponents.Label {
        text: statRow.value
        font.pixelSize: 11
        font.bold: true
        horizontalAlignment: Text.AlignRight
    }
}
