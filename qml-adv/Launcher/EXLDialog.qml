import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

import "."
import "LauncherSettings"

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
                        id: pPage
                        width: parent.width
                        implicitHeight: switch(pBar.currentIndex){
                            case 0: return elemPage.height + 56;
                            case 1: return advancedElemPage.height + 56;
                            case 2: return menuElemPage.height + 56;
                            default: 0;
                        }
                        header:TabBar {
                            id: pBar
                            width: parent.width
                            clip:true//超出父项直接裁剪
                            Repeater {
                                model: [qsTr("Basic"), qsTr("Advanced"), qsTr("Menu")]
                                TabButton {
                                    text: modelData
                                    width: Math.max(128, elemBar.width / 3)
                                }
                            }
                        }
                        StackLayout {
                            width: parent.width
                            currentIndex: pBar.currentIndex
                            Page {
                                id: elemPage
                                width: parent.width
                                implicitHeight: switch(elemBar.currentIndex){
                                    case 0: return basicEXLS.contentHeight + 56;
                                    case 1: return backgroundEXLS.contentHeight + 56;
                                    case 2: return mouseEventEXLS.contentHeight + 56;
                                    case 3: return animationEXLS.contentHeight + 56;
                                    case 4: return aDVEXLS.contentHeight + 56;
                                    default: 0;
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
                                    width: parent.width
                                    currentIndex: elemBar.currentIndex
                                    Item{BasicEXLS{id: basicEXLS}}
                                    Item{BackgroundEXLS{id: backgroundEXLS}}
                                    Item{MouseEventEXLS{id: mouseEventEXLS}}
                                    Item{AnimationEXLS{id: animationEXLS}}
                                }
                            }
                            // ADVANCED
                            Page {
                                id: advancedElemPage
                                width: parent.width
                                implicitHeight: switch(advancedElemBar.currentIndex){
                                    case 0: return backgroundEXLSA.contentHeight + 56;
                                    case 1: return animationEXLSA.contentHeight + 56;
                                    default: 0;
                                }
                                header:TabBar {
                                    id: advancedElemBar
                                    width: parent.width
                                    clip:true//超出父项直接裁剪
                                    Repeater {
                                        model: [qsTr("Background"),qsTr("Animation")]
                                        TabButton {
                                            text: modelData
                                            width: Math.max(128, advancedElemBar.width / 2)
                                        }
                                    }
                                }
                                StackLayout {
                                    width: parent.width
                                    currentIndex: advancedElemBar.currentIndex
                                    Item{BackgroundEXLS{id: backgroundEXLSA; itemName: "adv_"}}
                                    Item{AnimationEXLS{id: animationEXLSA; itemName: "adv_"}}
                                }
                            }
                            // Menu
                            Page {
                                id: menuElemPage
                                width: parent.width
                                implicitHeight: switch(menuElemBar.currentIndex){
                                    // case 0: return backgroundEXLSA.contentHeight + 56;
                                    // case 1: return animationEXLSA.contentHeight + 56;
                                    default: 0;
                                }
                                header:TabBar {
                                    id: menuElemBar
                                    width: parent.width
                                    clip:true//超出父项直接裁剪
                                    Repeater {
                                        model: [qsTr("Background"), qsTr("Animation")]
                                        TabButton {
                                            text: modelData
                                            width: Math.max(128, menuElemBar.width / 2)
                                        }
                                    }
                                }
                                StackLayout {
                                    width: parent.width
                                    currentIndex: menuElemBar.currentIndex
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}