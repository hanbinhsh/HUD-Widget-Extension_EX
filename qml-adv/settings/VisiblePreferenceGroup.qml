import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

//必须资源
Flickable {
    property var item: null
    id: visiblePreferenceGroup
    anchors.fill: parent
    contentWidth: width
    contentHeight: layoutVisibleSetting.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: layoutVisibleSetting
        width: parent.width
        P.ObjectPreferenceGroup {
            syncProperties: true
            enabled: item
            width: parent.width
            defaultValue: item
            //必须资源
            //部件编辑界面的可见性设置
            P.SelectPreference {
                name: "visibility"
                label: qsTr("Visibility")
                model:[ qsTr("Always"), qsTr("Normal"), qsTr("Hovered"), qsTr("Data"), qsTr("Data&Hovered"), qsTr("Data&Normal"), qsTr("Hide"), qsTr("HideBeforeAction")]
                defaultValue: 0
                load: function (newValue) {
                    if (newValue === undefined) {
                        value = defaultValue;
                        return;
                    }
                    switch (newValue) {
                    case "normal": value = 1; break;
                    case "hovered": value = 2; break;
                    case "data": value = 3; break;
                    case "data&hovered": value = 4; break;
                    case "data&normal": value = 5; break;
                    case "hide": value = 6; break;
                    case "action": value = 7; break;
                    default: value = -1; break;
                    }
                }
                save: function () {
                    switch (value) {
                    case 7: return "action";
                    case 6: return "hide";
                    case 5: return "data&normal";
                    case 4: return "data&hovered";
                    case 3: return "data";
                    case 2: return "hovered";
                    case 1: return "normal";
                    case 0:
                    default: break;
                    }
                    // undefined
                }
            }
            P.SwitchPreference {
                name: "onlyDisplayOnEXLauncher"
                label: qsTr("Only Display On EXLauncher")
            }
            P.Separator{}
            //显示时间
            P.SpinPreference {
                name: "displayTime"
                label: qsTr("Display Time")
                editable: true
                defaultValue: 250
                from: 0
                to: 10000
                stepSize: 50
                display: P.TextFieldPreference.ExpandLabel
            }
            //隐藏时间
            P.SpinPreference {
                name: "hideTime"
                label: qsTr("Hide Time")
                editable: true
                defaultValue: 250
                from: 0
                to: 10000
                stepSize: 50
                display: P.TextFieldPreference.ExpandLabel
            }
            //显示前暂停
            P.SpinPreference {
                name: "showPauseTime"
                label: qsTr("Display Pause Time")
                editable: true
                defaultValue: 0
                from: 0
                to: 10000
                stepSize: 50
                display: P.TextFieldPreference.ExpandLabel
            }
            //隐藏前暂停
            P.SpinPreference {
                name: "hidePauseTime"
                label: qsTr("Hide Pause Time")
                editable: true
                defaultValue: 0
                from: 0
                to: 10000
                stepSize: 50
                display: P.TextFieldPreference.ExpandLabel
            }
            P.Separator{}
        //显示动画
            P.SwitchPreference {
                id: enableShowAnimation
                name: "enableShowAnimation"
                label: qsTr("Enable Show Animation")
            }
            //角度
            P.SpinPreference {
                name: "showAnimation_Direction"
                label: " --- " + qsTr("Direction")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableShowAnimation.value
                defaultValue: 0
                from: -360
                to: 360
                stepSize: 10
            }
            //距离
            P.SpinPreference {
                name: "showAnimation_Distance"
                label: " --- " + qsTr("Distance")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableShowAnimation.value
                defaultValue: 10
                from: -1000
                to: 1000
                stepSize: 10
            }
            //时间
            P.SpinPreference {
                name: "showAnimation_Duration"
                label: " --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableShowAnimation.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "showAnimation_Easing"
                label: " --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableShowAnimation.value
            }
            P.Separator{}
        //消逝动画
            P.SwitchPreference {
                id: enableFadeTransition
                name: "enableFadeTransition"
                label: qsTr("Enable Fade Animation")
            }
            P.SelectPreference {
                id: fadeTransitionDirect
                name: "fadeTransitionDirect"
                label: " --- " + qsTr("Animation Direction")
                defaultValue: 1
                //从左到右,从下到上,从左上到右下
                //旋转 3
                //中心 4
                //高级选项5 用于改变线性的start,end值
                model: [ qsTr("Horizontal"), qsTr("Vertical"), qsTr("Oblique"), qsTr("Center"), qsTr("Conical"),qsTr("Advanced")]
                visible: enableFadeTransition.value
            }
            //高级设置 5
            //s.x x轴起始值
            P.SpinPreference {
                name: "fadeTransitionAdvancedStartX"
                label: " --- --- " + qsTr("Start X")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: fadeTransitionDirect.value==5&&enableFadeTransition.value
                defaultValue: 0
                from: -10000
                to: 10000
                stepSize: 5
            }
            //s.y y轴起始值
            P.SpinPreference {
                name: "fadeTransitionAdvancedStartY"
                label: " --- --- " + qsTr("Start Y")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: fadeTransitionDirect.value==5&&enableFadeTransition.value
                defaultValue: 0
                from: -10000
                to: 10000
                stepSize: 5
            }
            //e.x x轴结束值
            P.SpinPreference {
                name: "fadeTransitionAdvancedEndX"
                label: " --- --- " + qsTr("End X")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: fadeTransitionDirect.value==5&&enableFadeTransition.value
                defaultValue: 100
                from: -10000
                to: 10000
                stepSize: 5
            }
            //e.y y轴结束值
            P.SpinPreference {
                name: "fadeTransitionAdvancedEndY"
                label: " --- --- " + qsTr("End Y")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: fadeTransitionDirect.value==5&&enableFadeTransition.value
                defaultValue: 100
                from: -10000
                to: 10000
                stepSize: 5
            }
            //方向为3,4时提供的垂直水平角度选项,为4时提供水平/垂直半径
            //水平
            P.SpinPreference {
                name: "fadeTransitionHorizontal"
                label: " --- --- " + qsTr("Horizontal")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: (fadeTransitionDirect.value==4||fadeTransitionDirect.value==3)&&enableFadeTransition.value
                defaultValue: 0
                from: -10000
                to: 10000
                stepSize: 5
            }
            //垂直
            P.SpinPreference {
                name: "fadeTransitionVertical"
                label: " --- --- " + qsTr("Vertical")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: (fadeTransitionDirect.value==4||fadeTransitionDirect.value==3)&&enableFadeTransition.value
                defaultValue: 0
                from: -10000
                to: 10000
                stepSize: 5
            }
            //角度
            P.SpinPreference {
                name: "fadeTransitionAngle"
                label: " --- --- " + qsTr("Angle")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: (fadeTransitionDirect.value==4||fadeTransitionDirect.value==3)&&enableFadeTransition.value
                defaultValue: 0
                from: -10000
                to: 10000
                stepSize: 5
            }
            //水平半径 3
            P.SpinPreference {
                name: "fadeTransitionHorizontalRadius"
                label: " --- --- " + qsTr("Horizontal Radius")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: fadeTransitionDirect.value==3&&enableFadeTransition.value
                defaultValue: 50
                from: -10000
                to: 10000
                stepSize: 5
            }
            //垂直半径 3
            P.SpinPreference {
                name: "fadeTransitionVerticalRadius"
                label: " --- --- " + qsTr("Vertical Radius")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: fadeTransitionDirect.value==3&&enableFadeTransition.value
                defaultValue: 50
                from: -10000
                to: 10000
                stepSize: 5
            }
            //上方控制动画形状
            //渐变开始 开始值
            P.SpinPreference {
                name: "fadeTransition_sta_start"
                label: " --- " + qsTr("Start Edge Start")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableFadeTransition.value
                defaultValue: 0
                from: -100000
                to: 100000
                stepSize: 100
            }
            //渐变开始 结束值
            P.SpinPreference {
                name: "fadeTransition_sta_end"
                label: " --- " + qsTr("Start Edge End")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableFadeTransition.value
                defaultValue: 0
                from: -100000
                to: 100000
                stepSize: 100
            }
            //时间
            P.SpinPreference {
                name: "showAnimation_sta_Duration"
                label: " --- " + qsTr("Start Edge Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableFadeTransition.value
                defaultValue: 250
                from: 0
                to: 10000
                stepSize: 50
            }
            //渐变结束 开始值
            P.SpinPreference {
                name: "fadeTransition_end_start"
                label: " --- " + qsTr("End Edge Start")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableFadeTransition.value
                defaultValue: 1500
                from: -100000
                to: 100000
                stepSize: 100
            }
            //渐变开始 结束值
            P.SpinPreference {
                name: "fadeTransition_end_end"
                label: " --- " + qsTr("End Edge End")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableFadeTransition.value
                defaultValue: 0
                from: -100000
                to: 100000
                stepSize: 100
            }
            //时间
            P.SpinPreference {
                name: "showAnimation_end_Duration"
                label: " --- " + qsTr("End Edge Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableFadeTransition.value
                defaultValue: 250
                from: 0
                to: 10000
                stepSize: 50
            }
            //动画结束时间
            P.SpinPreference {
                name: "showAnimation_fade_Duration"
                label: " --- " + qsTr("End Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableFadeTransition.value
                defaultValue: 100
                from: 0
                to: 10000
                stepSize: 50
            }
            //缓存
            P.SwitchPreference {
                name: "fadeTransitionCached"
                label: " --- " + qsTr("Cached")
                visible: enableFadeTransition.value
            }
        }
    }
}