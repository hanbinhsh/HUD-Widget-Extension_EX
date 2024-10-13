import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

// 一般设置
//必须资源
Flickable {
    property var item: null
    id: normalPreferenceGroup
    anchors.fill: parent
    contentWidth: width
    contentHeight: layoutNormalSetting.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: layoutNormalSetting
        width: parent.width
        P.ObjectPreferenceGroup {
            syncProperties: true
            enabled: item
            width: parent.width
            defaultValue: item
            //必须资源
            //部件编辑界面的背景设置
            P.BackgroundPreference {
                name: "background"
                label: qsTr("Background")
                defaultBackground {
                    normal:  pDefaultBackground.value?.normal ??
                            pDefaultBackground.defaultBackground.normal
                    hovered: pDefaultBackground.value?.hovered ??
                            pDefaultBackground.defaultBackground.hovered
                    pressed: pDefaultBackground.value?.pressed ??
                            pDefaultBackground.defaultBackground.pressed
                }
                preferableFilter: pDefaultBackground.preferableFilter
            }
            P.SelectPreference {
                name: "separate"
                label: qsTr("Background Hierarchy")
                textRole: "label"
                valueRole: "value"
                defaultValue: 0
                model: [
                    { label: qsTr("<Default>"), value: undefined },
                    { label: qsTr("Element"), value: 0 },
                    { label: qsTr("Item"), value: 1 }
                ]
            }
            //部件编辑界面的颜色设置
            NoDefaultColorPreference {
                name: "color"
                label: qsTr("Color")
                defaultValue: ctx_widget.defaultBackgroundColor
            }
            //部件编辑界面的数据设置
            P.DataPreference {
                name: "data"
                label: qsTr("Data")
            }
        }
    }
}