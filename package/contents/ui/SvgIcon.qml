import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as PlasmaCore

Item {
    id: root

    property string name: ""

    function svgPath(iconName) {
        let path = String(Qt.resolvedUrl("../icons/hicolor/scalable/actions/" + iconName + ".svg"));
        return path.indexOf("file://") === 0 ? path.substring(7) : path;
    }

    implicitWidth: Kirigami.Units.iconSizes.small
    implicitHeight: Kirigami.Units.iconSizes.small

    PlasmaCore.Svg {
        id: themedSvg

        imagePath: root.name !== "" ? root.svgPath(root.name) : ""
        colorSet: root.Kirigami.Theme.colorSet
    }

    PlasmaCore.SvgItem {
        anchors.fill: root
        svg: themedSvg
    }
}
