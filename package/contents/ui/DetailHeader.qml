import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: detailHeader

    property string title: ""
    property string icon: ""
    property string value: ""
    property real barValue: 0
    property string barColor: "#00aaff"
    property bool showBar: true

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Item { Layout.preferredHeight: Kirigami.Units.smallSpacing }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        text: detailHeader.title
        font.bold: true
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        SvgIcon {
            visible: detailHeader.icon.length > 0
            name: detailHeader.icon
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            visible: detailHeader.showBar
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: root.themeTrackColor

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, detailHeader.barValue))
                height: parent.height
                radius: 3
                color: detailHeader.barColor
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: !detailHeader.showBar
            Layout.preferredWidth: detailHeader.showBar ? Kirigami.Units.gridUnit * 5 : -1
            text: detailHeader.value
            font.pixelSize: 10
            horizontalAlignment: detailHeader.showBar ? Text.AlignRight : Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
