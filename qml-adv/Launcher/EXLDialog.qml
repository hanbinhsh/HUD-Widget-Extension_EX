import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

import "."

NVG.Window {
    id: eXLDialog
    Style.theme: Style.Dark

    title: qsTr("EXL Settings")
    visible: true
    minimumWidth: 360
    maximumWidth: 360
    minimumHeight: 700
    //transientParent: eXLauncherView.window
    onClosing: saveSettings()
    
    function saveSettings() {
        if (NVG.Settings.isModified(eXLauncherView.eXLSettings)){
            NVG.Settings.save(eXLauncherView.eXLSettings, "com.hanbinhsh.widget.hud_edit", "eXLSettings");
        } 
    }

    property var easingModel : [qsTr("Linear"),//0
                                qsTr("InQuad"),qsTr("OutQuad"),qsTr("InOutQuad"),qsTr("OutInQuad"),//1-4
                                qsTr("InCubic"),qsTr("OutCubic"),qsTr("InOutCubic"),qsTr("OutInCubic"),//5-8
                                qsTr("InQuart"),qsTr("OutQuart"),qsTr("InOutQuart"),qsTr("OutInQuart"),//9-12
                                qsTr("InQuint"),qsTr("OutQuint"),qsTr("InOutQuint"),qsTr("OutInQuint"),//13-16
                                qsTr("InSine"),qsTr("OutSine"),qsTr("InOutSine"),qsTr("OutInSine"),//17-20
                                qsTr("InExpo"),qsTr("OutExpo"),qsTr("InOutExpo"),qsTr("OutInExpo"),//21-24
                                qsTr("InCirc"),qsTr("OutCirc"),qsTr("InOutCirc"),qsTr("OutInCirc"),//25-28
                                qsTr("InElastic"),qsTr("OutElastic"),qsTr("InOutElastic"),qsTr("OutInElastic"),//28-32
                                qsTr("InBack"),qsTr("OutBack"),qsTr("InOutBack"),qsTr("OutInBack"),//33-36
                                qsTr("InBounce"),qsTr("OutBounce"),qsTr("InOutBounce"),qsTr("OutInBounce"),//36-40
                                qsTr("BezierSpline")];

    Page {
        anchors.fill: parent
        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: preferencesLayout.height
            topMargin: 16
            bottomMargin: 16
            leftMargin: 16
            rightMargin: 16
            Column {
                id: preferencesLayout
                width: parent.width - 32
                P.ObjectPreferenceGroup {
                    label: qsTr("EX Launcher Settings")
                    defaultValue: eXLauncherView.eXLSettings
                    syncProperties: true
                    enabled: true
                    width: parent.width
                    Page {
                        id: elemPage
                        width: parent.width
                        implicitHeight: switch(elemBar.currentIndex){
                            case 0: return basicEXLS.height + 56;
                            case 1: return backgroundEXLS.height + 56;
                            case 2: return mouseEventEXLS.height + 56;
                            case 3: return animationEXLS.height + 56;
                            return 0;
                        }
                        header:TabBar {
                            id: elemBar
                            width: parent.width
                            clip:true//超出父项直接裁剪
                            Repeater {
                                model: [qsTr("Basic"),qsTr("Background"),qsTr("Mouse Event"),qsTr("Animation")]
                                TabButton {
                                    text: modelData
                                    width: Math.max(128, elemBar.width / 3)
                                }
                            }
                        }
                        StackLayout {
                            //anchors.centerIn: parent
                            width: parent.width
                            currentIndex: elemBar.currentIndex
                            Item{
                                //必须资源
                                Flickable {
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: basicEXLS.height
                                    topMargin: 16
                                    bottomMargin: 16
                                    Column {
                                        id: basicEXLS
                                        width: parent.width
                                        P.ObjectPreferenceGroup {
                                            defaultValue: eXLauncherView.eXLSettings
                                            syncProperties: true
                                            width: parent.width
                                            //必须资源
                                            Row{
                                                spacing: 8
                                                Column {
                                                    Label {
                                                        text: qsTr("X   Y")
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }
                                                    P.ObjectPreferenceGroup {
                                                        syncProperties: true
                                                        defaultValue: eXLauncherView.eXLSettings
                                                        P.SpinPreference {
                                                            name: "viewX"
                                                            editable: true
                                                            display: P.TextFieldPreference.ExpandLabel
                                                            defaultValue: 0
                                                            from: -99999
                                                            to: 99999
                                                            stepSize: 5
                                                        }
                                                        P.SpinPreference {
                                                            name: "viewY"
                                                            editable: true
                                                            display: P.TextFieldPreference.ExpandLabel
                                                            defaultValue: 0
                                                            from: -99999
                                                            to: 99999
                                                            stepSize: 5
                                                        }
                                                    }
                                                }
                                                Column {
                                                    Label {
                                                        text: qsTr("W   H")
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }
                                                    P.ObjectPreferenceGroup {
                                                        syncProperties: true
                                                        defaultValue: eXLauncherView.eXLSettings
                                                        P.SpinPreference {
                                                            name: "viewW"
                                                            editable: true
                                                            display: P.TextFieldPreference.ExpandLabel
                                                            defaultValue: Screen.width
                                                            from: -99999
                                                            to: 99999
                                                            stepSize: 5
                                                        }
                                                        P.SpinPreference {
                                                            name: "viewH"
                                                            editable: true
                                                            display: P.TextFieldPreference.ExpandLabel
                                                            defaultValue: Screen.height
                                                            from: -99999
                                                            to: 99999
                                                            stepSize: 5
                                                        }
                                                    }
                                                }
                                            }
                                            P.SpinPreference {
                                                name: "viewZ"
                                                label: qsTr("EXL Z")
                                                editable: true
                                                display: P.TextFieldPreference.ExpandLabel
                                                defaultValue: 0
                                                from: -9999
                                                to: 9999
                                                stepSize: 1
                                            }
                                            P.SpinPreference {
                                                name: "viewO"
                                                label: qsTr("Max Opacity")
                                                editable: true
                                                display: P.TextFieldPreference.ExpandLabel
                                                defaultValue: 100
                                                from: 0
                                                to: 100
                                                stepSize: 5
                                            }
                                            P.ColorPreference {
                                                name: "viewBGColor"
                                                label: qsTr("Background Color")
                                                defaultValue: "#777777"
                                            }
                                        }
                                    }
                                }
                            }
                            Item{
                                //必须资源
                                Flickable {
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: backgroundEXLS.height
                                    topMargin: 16
                                    bottomMargin: 16
                                    Column {
                                        id: backgroundEXLS
                                        width: parent.width
                                        P.ObjectPreferenceGroup {
                                            defaultValue: eXLauncherView.eXLSettings
                                            syncProperties: true
                                            width: parent.width
                                            //必须资源
                                            P.SwitchPreference {
                                                id: useViewImage
                                                name: "useViewImage"
                                                label: qsTr("Use Background Image")
                                            }
                                            P.ImagePreference {
                                                name: "viewBGImage"
                                                label: qsTr("Image")
                                                visible: useViewImage.value
                                            }
                                            P.SelectPreference {
                                                name: "viewBGImageFill"
                                                label: qsTr("Fill Mode")
                                                model: [ qsTr("Stretch"), qsTr("Fit"), qsTr("Crop"), qsTr("Tile"), qsTr("Tile Vertically"), qsTr("Tile Horizontally"), qsTr("Pad") ]
                                                defaultValue: 1
                                                visible: useViewImage.value
                                            }
                                            Row{
                                                spacing: 8
                                                Column {
                                                    Label {
                                                        text: qsTr("X Y")
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }
                                                    P.ObjectPreferenceGroup {
                                                        syncProperties: true
                                                        defaultValue: eXLauncherView.eXLSettings
                                                        P.SpinPreference {
                                                            name: "viewBGX"
                                                            editable: true
                                                            display: P.TextFieldPreference.ExpandLabel
                                                            defaultValue: 0
                                                            from: -99999
                                                            to: 99999
                                                            stepSize: 5
                                                        }
                                                        P.SpinPreference {
                                                            name: "viewBGY"
                                                            editable: true
                                                            display: P.TextFieldPreference.ExpandLabel
                                                            defaultValue: 0
                                                            from: -99999
                                                            to: 99999
                                                            stepSize: 5
                                                        }
                                                    }
                                                }
                                                Column {
                                                    Label {
                                                        text: qsTr("W H")
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }
                                                    P.ObjectPreferenceGroup {
                                                        syncProperties: true
                                                        defaultValue: eXLauncherView.eXLSettings
                                                        P.SpinPreference {
                                                            name: "viewBGW"
                                                            editable: true
                                                            display: P.TextFieldPreference.ExpandLabel
                                                            defaultValue: Screen.width
                                                            from: -99999
                                                            to: 99999
                                                            stepSize: 5
                                                        }
                                                        P.SpinPreference {
                                                            name: "viewBGH"
                                                            editable: true
                                                            display: P.TextFieldPreference.ExpandLabel
                                                            defaultValue: Screen.height
                                                            from: -99999
                                                            to: 99999
                                                            stepSize: 5
                                                        }
                                                    }
                                                }
                                            }
                                            P.SpinPreference {
                                                name: "viewBGImageOpacity"
                                                label: qsTr("Image Opacity")
                                                editable: true
                                                display: P.TextFieldPreference.ExpandLabel
                                                defaultValue: 100
                                                from: 0
                                                to: 100
                                                stepSize: 5
                                            }
                                        }
                                    }
                                }
                            }
                            Item{
                                //必须资源
                                Flickable {
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: mouseEventEXLS.height
                                    topMargin: 16
                                    bottomMargin: 16
                                    Column {
                                        id: mouseEventEXLS
                                        width: parent.width
                                        P.ObjectPreferenceGroup {
                                            defaultValue: eXLauncherView.eXLSettings
                                            syncProperties: true
                                            width: parent.width
                                            //必须资源
                                            P.SelectPreference {
                                                name: "leftClickEvent"
                                                label: qsTr("Left Click")
                                                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                                                defaultValue: 3
                                            }
                                            P.SelectPreference {
                                                name: "rightClickEvent"
                                                label: qsTr("Right Click")
                                                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                                                defaultValue: 0
                                            }
                                            P.SelectPreference {
                                                name: "middleClickEvent"
                                                label: qsTr("Middle Click")
                                                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                                                defaultValue: 1
                                            }
                                            P.Separator{}
                                            P.SelectPreference {
                                                name: "leftClickEvent2"
                                                label: qsTr("Left Click") + " Ⅱ"
                                                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                                                defaultValue: 3
                                            }
                                            P.SelectPreference {
                                                name: "rightClickEvent2"
                                                label: qsTr("Right Click") + " Ⅱ"
                                                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                                                defaultValue: 3
                                            }
                                            P.SelectPreference {
                                                name: "middleClickEvent2"
                                                label: qsTr("Middle Click") + " Ⅱ"
                                                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                                                defaultValue: 3
                                            }
                                            P.Separator{}
                                            P.ActionPreference {
                                                name: "action_L"
                                                label: qsTr("Left Action")
                                            }
                                            P.ActionPreference {
                                                name: "action_R"
                                                label: qsTr("Right Action")
                                            }
                                            P.ActionPreference {
                                                name: "action_M"
                                                label: qsTr("Middle Action")
                                            }
                                        }
                                    }
                                }
                            }
                            Item{
                                //必须资源
                                Flickable {
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
                                                name: "showPause"
                                                label: qsTr("Show Pause")
                                                editable: true
                                                display: P.TextFieldPreference.ExpandLabel
                                                defaultValue: 0
                                                from: -9999
                                                to: 9999
                                                stepSize: 50
                                            }
                                            P.SpinPreference {
                                                name: "hidePause"
                                                label: qsTr("Hide Pause")
                                                editable: true
                                                display: P.TextFieldPreference.ExpandLabel
                                                defaultValue: 0
                                                from: -9999
                                                to: 9999
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
                                            P.Separator{}
                                            //显示动画
                                            P.SwitchPreference {
                                                id: enableShowAnimation
                                                name: "enableShowAnimation"
                                                label: qsTr("Enable Image Display Animation")
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
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

