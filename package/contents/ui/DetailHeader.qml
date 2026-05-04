import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: detailHeader

    required property var parentRef

    property string title: ""
    property string icon: ""
    property string value: ""
    property real barValue: 0
    property string barColor: "#00aaff"
    property bool showBar: true
    property bool valueInsideBar: false
    property real rightReservedWidth: 0
    property bool showUsageRow: true

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Item {
        Layout.preferredHeight: Kirigami.Units.smallSpacing
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        text: detailHeader.title
        font.bold: true
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
    }
}
