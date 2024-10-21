import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

Flickable {
    property string itemName: ""
    anchors.fill: parent
    contentWidth: width
    contentHeight: animationEXLS.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: animationEXLS
        width: parent.width
        P.ObjectPreferenceGroup {
            defaultValue: eXLauncherView.eXLSettings
            syncProperties: true
            width: parent.width
            //必须资源
            P.SpinPreference {
                name: itemName + "showPause"
                label: qsTr("Show Pause")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 0
                from: -9999
                to: 9999
                stepSize: 50
                visible: itemName===""
            }
            P.SpinPreference {
                name: itemName + "hidePause"
                label: qsTr("Hide Pause")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 0
                from: -9999
                to: 9999
                stepSize: 50
                visible: itemName===""
            }
            //时间
            P.SpinPreference {
                name: itemName + "showhideDuration"
                label: qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
                visible: itemName===""
            }
            P.Separator{visible: itemName===""}
            //显示动画
            P.SwitchPreference {
                id: enableShowAnimation
                name: itemName + "enableShowAnimation"
                label: qsTr("Enable Image Display Animation")
                visible: itemName===""
            }
            //角度
            P.SpinPreference {
                name: itemName + "showAnimation_Direction"
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
                name: itemName + "showAnimation_Distance"
                label: " --- " + qsTr("Distance")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableShowAnimation.value
                defaultValue: 10
                from: -99999
                to: 99999
                stepSize: 10
            }
            //时间
            P.SpinPreference {
                name: itemName + "showAnimation_Duration"
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
                name: itemName + "showAnimation_Easing"
                label: " --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: enableShowAnimation.value
            }
            //全屏移动动画
            P.Separator{visible: itemName===""}
            P.SwitchPreference {
                id: enableMoveAnimation
                name: itemName + "enableMoveAnimation"
                label: qsTr("Enable Image Move Animation")
                message: qsTr("You need to Re-switch after changes. Try to set distance to the image size, adjust the background size and set fill mode to tile.")
            }
            Row{
                visible: enableMoveAnimation.value
                spacing: 8
                Column {
                    Label {
                        text: qsTr("X From To")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        defaultValue: eXLauncherView.eXLSettings
                        P.SpinPreference {
                            name: itemName + "moveAnimation_XFrom"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 10
                        }
                        P.SpinPreference {
                            name: itemName + "moveAnimation_XTo"
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
                        defaultValue: eXLauncherView.eXLSettings
                        P.SpinPreference {
                            name: itemName + "moveAnimation_YFrom"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 10
                        }
                        P.SpinPreference {
                            name: itemName + "moveAnimation_YTo"
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
                name: itemName + "moveAnimation_DurationX"
                label: " --- " + qsTr("Duration X")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableMoveAnimation.value
                defaultValue: 3000
                from: 0
                to: 99999
                stepSize: 10
            }
            P.SpinPreference {
                name: itemName + "moveAnimation_DurationY"
                label: " --- " + qsTr("Duration Y")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableMoveAnimation.value
                defaultValue: 3000
                from: 0
                to: 99999
                stepSize: 10
            }
        }
    }
}

