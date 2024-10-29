import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

Flickable {
    property var current_default: eXLauncherView.eXLSettings
    property bool is_default: false
    anchors.fill: parent
    contentWidth: width
    contentHeight: animationEXLS.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: animationEXLS
        width: parent.width
        P.ObjectPreferenceGroup {
            defaultValue: current_default
            syncProperties: true
            width: parent.width
            //必须资源
            P.SpinPreference {
                name: "showPause"
                label: qsTr("Show Pause")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 0
                from: 0
                to: 99999
                stepSize: 50
            }
            P.SpinPreference {
                name: "hidePause"
                label: qsTr("Hide Pause")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 0
                from: 0
                to: 99999
                stepSize: 50
            }
            //时间
            P.SpinPreference {
                name: "showhideDuration"
                label: qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            P.Separator{visible: !is_default}
            //显示动画
            P.SwitchPreference {
                id: enableShowAnimation
                name: "enableShowAnimation"
                label: qsTr("Enable Image Display Animation")
                visible: !is_default
            }
            //角度
            P.SpinPreference {
                name: "showAnimation_Direction"
                label: " --- " + qsTr("Direction")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableShowAnimation.value&&!is_default
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
                visible: enableShowAnimation.value&&!is_default
                defaultValue: 10
                from: -99999
                to: 99999
                stepSize: 10
            }
            //时间
            P.SpinPreference {
                name: "showAnimation_Duration"
                label: " --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableShowAnimation.value&&!is_default
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
                visible: enableShowAnimation.value&&!is_default
            }
            //全屏移动动画
            P.Separator{visible: !is_default}
            P.SwitchPreference {
                id: enableMoveAnimation
                name: "enableMoveAnimation"
                label: qsTr("Enable Image Move Animation")
                visible: !is_default
                message: qsTr("You need to Re-switch after changes. Try to set distance to the image size, adjust the background size and set fill mode to tile.")
            }
            Row{
                visible: enableMoveAnimation.value&&!is_default
                spacing: 8
                Column {
                    Label {
                        text: qsTr("X From To")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        defaultValue: current_default
                        P.SpinPreference {
                            name: "moveAnimation_XFrom"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 10
                        }
                        P.SpinPreference {
                            name: "moveAnimation_XTo"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 10
                        }
                    }
                }
                Column {
                    Label {
                        text: qsTr("Y From To")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        defaultValue: current_default
                        P.SpinPreference {
                            name: "moveAnimation_YFrom"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 10
                        }
                        P.SpinPreference {
                            name: "moveAnimation_YTo"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 10
                        }
                    }
                }
            }
            //时间
            P.SpinPreference {
                name: "moveAnimation_DurationX"
                label: " --- " + qsTr("Duration X")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableMoveAnimation.value&&!is_default
                defaultValue: 3000
                from: 0
                to: 99999
                stepSize: 10
            }
            P.SpinPreference {
                name: "moveAnimation_DurationY"
                label: " --- " + qsTr("Duration Y")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableMoveAnimation.value&&!is_default
                defaultValue: 3000
                from: 0
                to: 99999
                stepSize: 10
            }
        }
    }
}

