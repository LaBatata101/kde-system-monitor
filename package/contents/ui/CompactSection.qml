import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Rectangle {
    id: compactSection

    default property alias content: contentLayout.data
    property string title: ""
    property string summary: ""
    property int contentMinimumHeight: 0
    property int horizontalPadding: Kirigami.Units.smallSpacing
    property int verticalPadding: Kirigami.Units.smallSpacing
    property color hoverColor: "transparent"
    property bool tooltipActive: true

    signal clicked

    implicitWidth: contentLayout.implicitWidth + compactSection.horizontalPadding * 2
    implicitHeight: Math.max(compactSection.contentMinimumHeight, contentLayout.implicitHeight) + compactSection.verticalPadding * 2
    radius: 3
    color: compactSectionToolTipArea.containsMouse ? compactSection.hoverColor : "transparent"

    RowLayout {
        id: contentLayout

        anchors.verticalCenter: compactSection.verticalCenter
        anchors.left: compactSection.left
        anchors.leftMargin: compactSection.horizontalPadding
        anchors.rightMargin: compactSection.horizontalPadding
        spacing: Kirigami.Units.smallSpacing
    }

    PlasmaCore.ToolTipArea {
        id: compactSectionToolTipArea

        anchors.fill: compactSection
        mainText: compactSection.title
        subText: compactSection.summary
        location: Plasmoid.location
        active: compactSection.tooltipActive

        MouseArea {
            anchors.fill: compactSectionToolTipArea
            hoverEnabled: true
            onClicked: compactSection.clicked()
        }
    }
}
