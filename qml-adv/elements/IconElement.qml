import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

HUDElementTemplate {
    id:  thiz

    title: qsTranslate("utils", "Icon")
    implicitWidth: iconSource.implicitWidth
    implicitHeight: iconSource.implicitHeight

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.IconPreference {
            name: "icon"
            label: qsTr("Icon")
            defaultIcon: iconSource.defaultIcon
        }
    }

    NVG.IconSource {
        id: iconSource
        anchors.fill: parent

        configuration: thiz.settings.icon
        hovered: thiz.itemHovered
        pressed: thiz.itemPressed

        defaultIcon.normal: "../../Images/icon/Default.png"

        icon { width: 38; height: 38 }
    }
}
