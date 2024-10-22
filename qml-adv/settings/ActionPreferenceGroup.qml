import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

//动作设置
//必须资源
Flickable {
    property var item: null
    id: actionPreferenceGroup
    anchors.fill: parent
    contentWidth: width
    contentHeight: layoutActionSetting.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: layoutActionSetting
        width: parent.width
        P.ObjectPreferenceGroup {
            syncProperties: true
            enabled: item
            defaultValue: item
            width: parent.width
            //必须资源
            //动作
            P.SwitchPreference {
                id: enableAction
                name: "enableAction"
                label: qsTr("Enable Action")
            }
            // 部件编辑界面的动作设置
            P.ActionPreference {
                name: "action"
                label: " --- " + qsTr("Action")
                visible: enableAction.value
            }
            //显示exl
            P.SwitchPreference {
                name: "showEXLauncher"
                label: " --- " + qsTr("Click To Show EXLauncher")
                visible: enableAction.value
            }
            // TODO 悬停动作 （移动，缩放）
            //中心
            P.SpinPreference {
                name: "zoomMouse_OriginX"
                label: " --- " + qsTr("Origin X")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value
                defaultValue: 0
                from: -10000
                to: 10000
                stepSize: 10
            }
            P.SpinPreference {
                name: "zoomMouse_OriginY"
                label: " --- " + qsTr("Origin Y")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value
                defaultValue: 0
                from: -10000
                to: 10000
                stepSize: 10
            }
            P.Separator{visible: enableAction.value}
        //悬停移动
            P.SwitchPreference {
                id: moveOnHover
                name: "moveOnHover"
                label: " --- " + qsTr("Move On Hover")
                visible: enableAction.value
            }
            //距离
            P.SpinPreference {
                name: "moveHover_Distance"
                label: " --- --- " + qsTr("Distance")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&moveOnHover.value
                defaultValue: 10
                from: -1000
                to: 1000
                stepSize: 10
            }
            //方向
            P.SpinPreference {
                name: "moveHover_Direction"
                label: " --- --- " + qsTr("Direction")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&moveOnHover.value
                defaultValue: 0
                from: -180
                to: 180
                stepSize: 5
            }
            //持续时间
            P.SpinPreference {
                name: "moveHover_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&moveOnHover.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "moveOnHover_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableAction.value&&moveOnHover.value
            }
            P.Separator{visible: enableAction.value}
        //悬停缩放
            P.SwitchPreference {
                id: zoomOnHover
                name: "zoomOnHover"
                label: " --- " + qsTr("Zoom On Hover")
                visible: enableAction.value
            }
            //大小
            P.SpinPreference {
                name: "zoomHover_XSize"
                label: " --- --- " + qsTr("X Scale")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&zoomOnHover.value
                defaultValue: 100
                from: -100000
                to: 100000
                stepSize: 10
            }
            P.SpinPreference {
                name: "zoomHover_YSize"
                label: " --- --- " + qsTr("Y Scale")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&zoomOnHover.value
                defaultValue: 100
                from: -100000
                to: 100000
                stepSize: 10
            }
            //持续时间
            P.SpinPreference {
                name: "zoomHover_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&zoomOnHover.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "zoomHover_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableAction.value&&zoomOnHover.value
            }
            P.Separator{visible: enableAction.value}
        //悬停旋转
            P.SwitchPreference {
                id: spinOnHover
                name: "spinOnHover"
                label: " --- " + qsTr("Spin On Hover")
                visible: enableAction.value
            }
            //角度
            P.SpinPreference {
                name: "spinHover_Direction"
                label: " --- --- " + qsTr("Direction")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&spinOnHover.value
                defaultValue: 360
                from: -3600
                to: 3600
                stepSize: 180
            }
            //时间
            P.SpinPreference {
                name: "spinHover_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&spinOnHover.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "spinHover_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableAction.value&&spinOnHover.value
            }
            P.Separator{visible: enableAction.value}
        // TODO 3D旋转
        // TODO 持续旋转
        //悬停闪烁
            P.SwitchPreference {
                id: glimmerOnHover
                name: "glimmerOnHover"
                label: " --- " + qsTr("Glimmer On Hover")
                visible: enableAction.value
            }
            //时间
            P.SpinPreference {
                name: "glimmerHover_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&glimmerOnHover.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //最小透明度
            P.SpinPreference {
                name: "glimmerHover_MinOpacity"
                label: " --- --- " + qsTr("Min Opacity")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&glimmerOnHover.value
                defaultValue: 0
                from: 0
                to: 100
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "glimmerHover_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableAction.value&&glimmerOnHover.value
            }
            P.Separator{visible: enableAction.value}
    //// 点击
        //点击缩放
            P.SwitchPreference {
                id: zoomOnClick
                name: "zoomOnClick"
                label: " --- " + qsTr("Zoom On Click")
                visible: enableAction.value
            }
            //大小
            P.SpinPreference {
                name: "zoomClick_XSize"
                label: " --- --- " + qsTr("X Scale")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&zoomOnClick.value
                defaultValue: 100
                from: -100000
                to: 100000
                stepSize: 10
            }
            P.SpinPreference {
                name: "zoomClick_YSize"
                label: " --- --- " + qsTr("Y Scale")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&zoomOnClick.value
                defaultValue: 100
                from: -100000
                to: 100000
                stepSize: 10
            }
            //持续时间
            P.SpinPreference {
                name: "zoomClick_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&zoomOnClick.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "zoomClick_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableAction.value&&zoomOnClick.value
            }
            P.Separator{visible: enableAction.value}
        //点击旋转
            P.SwitchPreference {
                id: spinOnClick
                name: "spinOnClick"
                label: " --- " + qsTr("Spin On Click")
                visible: enableAction.value
            }
            //单次旋转
            P.SwitchPreference {
                name: "spinOnClickInstantRecuvery"
                label: " --- --- " + qsTr("Instant Recuvery")
                visible: enableAction.value&&spinOnClick.value
            }
            //角度
            P.SpinPreference {
                name: "spinClick_Direction"
                label: " --- --- " + qsTr("Direction")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&spinOnClick.value
                defaultValue: 360
                from: -3600
                to: 3600
                stepSize: 180
            }
            //时间
            P.SpinPreference {
                name: "spinClick_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&spinOnClick.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "spinClick_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableAction.value&&spinOnClick.value
            }
            P.Separator{visible: enableAction.value}
        //点击移动
            P.SwitchPreference {
                id: moveOnClick
                name: "moveOnClick"
                label: " --- " + qsTr("Move On Click")
                visible: enableAction.value
            }
            //点击第二次后移回
            P.SwitchPreference {
                name: "moveBackAfterClick"
                label: " --- --- " + qsTr("Move Back After Click")
                visible: enableAction.value&&moveOnClick.value
            }
            //角度
            P.SpinPreference {
                name: "moveClick_Direction"
                label: " --- --- " + qsTr("Direction")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&moveOnClick.value
                defaultValue: 0
                from: -360
                to: 360
                stepSize: 10
            }
            //距离
            P.SpinPreference {
                name: "moveClick_Distance"
                label: " --- --- " + qsTr("Distance")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&moveOnClick.value
                defaultValue: 10
                from: -1000
                to: 1000
                stepSize: 10
            }
            //时间
            P.SpinPreference {
                name: "moveClick_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAction.value&&moveOnClick.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "moveClick_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableAction.value&&moveOnClick.value
            }
        }
    }
}