import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as PlasmaCore
// Required so KSvg resolves colors through the active Plasma theme.
import org.kde.plasma.core as PlasmaTheme

Item {
    id: root

    property string name: ""

    implicitWidth: Kirigami.Units.iconSizes.small
    implicitHeight: Kirigami.Units.iconSizes.small

    function svgPath(iconName) {
        var path = String(Qt.resolvedUrl("../icons/hicolor/scalable/actions/" + iconName + ".svg"));
        return path.indexOf("file://") === 0 ? path.substring(7) : path;
    }

    PlasmaCore.Svg {
        id: themedSvg
        imagePath: root.name !== "" ? root.svgPath(root.name) : ""
        colorSet: root.Kirigami.Theme.colorSet
    }

    PlasmaCore.SvgItem {
        anchors.fill: parent
        svg: themedSvg
    }
}
