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

    RowLayout {
        visible: detailHeader.showUsageRow
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

        Item {
            id: barContainer

            visible: detailHeader.showBar
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            Layout.minimumHeight: 6
            height: 6

            Rectangle {
                id: barTrack

                anchors.fill: barContainer
                radius: 3
                color: detailHeader.parentRef.themeTrackColor

                Rectangle {
                    width: barTrack.width * Math.min(1, Math.max(0, detailHeader.barValue))
                    height: barTrack.height
                    radius: 3
                    color: detailHeader.barColor

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                visible: detailHeader.valueInsideBar
                anchors.fill: barContainer
                anchors.rightMargin: 4
                text: detailHeader.value
                color: detailHeader.parentRef.themeBarLabelColor
                font.pixelSize: 9
                font.bold: true
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        PlasmaComponents.Label {
            visible: !detailHeader.valueInsideBar
            Layout.fillWidth: !detailHeader.showBar
            Layout.preferredWidth: detailHeader.showBar ? Kirigami.Units.gridUnit * 5 : -1
            text: detailHeader.value
            font.pixelSize: 10
            horizontalAlignment: detailHeader.showBar ? Text.AlignRight : Text.AlignHCenter
            elide: Text.ElideRight
        }

        Item {
            visible: detailHeader.rightReservedWidth > 0
            Layout.preferredWidth: detailHeader.rightReservedWidth
            Layout.minimumWidth: detailHeader.rightReservedWidth
        }
    }
}
