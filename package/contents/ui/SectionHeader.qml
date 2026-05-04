import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: sectionHeader

    property string title: ""
    property string icon: ""
    property string value: ""
    property real barValue: 0
    property string barColor: "#00aaff"
    property bool showBar: true
    property bool expanded: false

    signal toggled()

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 2

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? root.themeHoverColor : "transparent"
        radius: 4
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Kirigami.Units.smallSpacing
            rightMargin: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        SvgIcon {
            name: sectionHeader.icon
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
            Layout.alignment: Qt.AlignVCenter
        }

        PlasmaComponents.Label {
            text: sectionHeader.title
            font.bold: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            PlasmaComponents.Label {
                text: sectionHeader.value
                font.pixelSize: 10
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            Rectangle {
                visible: sectionHeader.showBar
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: root.themeTrackColor

                Rectangle {
                    width: parent.width * Math.min(1, Math.max(0, sectionHeader.barValue))
                    height: parent.height
                    radius: 2
                    color: sectionHeader.barColor
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
        }

        SvgIcon {
            name: sectionHeader.expanded ? "am-up-symbolic" : "am-down-symbolic"
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: sectionHeader.toggled()
        cursorShape: Qt.PointingHandCursor
    }
}
