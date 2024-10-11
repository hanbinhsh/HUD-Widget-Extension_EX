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
                model:[ qsTr("Always"), qsTr("Normal"), qsTr("Hovered"), qsTr("Data"), qsTr("Data&Hovered"), qsTr("Data&Normal")]
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
                    default: value = -1; break;
                    }
                }
                save: function () {
                    switch (value) {
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
        //消逝动画
            P.SwitchPreference {
                id: enableFadeTransition
                name: "enableFadeTransition"
                label: qsTr("Enable Fade Animation")
            }
            P.SwitchPreference {
                name: "fadeTransitionHorizontal"
                label: " --- " + qsTr("Horizontal Direction")
                visible: enableFadeTransition.value
            }
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
                defaultValue: 1000
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
                name: "showAnimation_Duration"
                label: " --- " + qsTr("End Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableFadeTransition.value
                defaultValue: 100
                from: 0
                to: 10000
                stepSize: 50
            }
        }
    }
}