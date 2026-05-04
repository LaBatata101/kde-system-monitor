import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    property string label: ""
    property string value: ""

    Layout.fillWidth: true

    PlasmaComponents.Label {
        text: label
        font.pixelSize: 11
        Layout.fillWidth: true
    }
    PlasmaComponents.Label {
        text: value
        font.pixelSize: 11
        font.bold: true
        horizontalAlignment: Text.AlignRight
    }
}
