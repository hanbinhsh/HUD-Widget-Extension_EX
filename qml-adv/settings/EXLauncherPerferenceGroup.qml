import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

//动作设置
//必须资源
Flickable {
    property var item: null
    id: eXLauncherPerferenceGroup
    anchors.fill: parent
    contentWidth: width
    contentHeight: layoutEXSetting.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: layoutEXSetting
        width: parent.width
        P.ObjectPreferenceGroup {
            syncProperties: true
            enabled: item
            defaultValue: item
            width: parent.width
            //必须资源
            P.SwitchPreference {
                name: "onlyDisplayOnEXLauncher"
                label: qsTr("Only Display On EXLauncher")
            }
        }
    }
}