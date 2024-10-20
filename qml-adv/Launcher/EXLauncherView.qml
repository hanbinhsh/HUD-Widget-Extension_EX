import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.2
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

import "."

NVG.View {
    id: eXLauncherView
    property bool isVisible: false  // 用于接收外部的 visible 状态
    opacity: 0.0  // 初始 opacity 为 0
    z: eXLSettings.viewZ ?? 0
    y: eXLSettings.viewY ?? 0
    x: eXLSettings.viewX ?? 0
    width: eXLSettings.viewW ?? Screen.width
    height: eXLSettings.viewH ?? Screen.height
    color: eXLSettings.viewBGColor ?? "#777777"

    property NVG.SettingsMap eXLSettings: NVG.Settings.load("com.hanbinhsh.widget.hud_edit", "eXLSettings", eXLauncherView);

    Component.onCompleted: {
        init()
    }

    function init(){
        const object = NVG.Settings.load("com.hanbinhsh.widget.hud_edit", "eXLSettings", eXLauncherView);
        if (object instanceof NVG.SettingsMap){
            eXLSettings = object;
        }else{
            eXLSettings = NVG.Settings.createMap(eXLauncherView)
            NVG.Settings.save(eXLSettings, "com.hanbinhsh.widget.hud_edit", "eXLSettings")
        }
    }

    // 当 isVisible 改变时触发动画
    onIsVisibleChanged: {
        if (isVisible) {
            hideAnimation.stop()
            eXLauncherView.visible = true  // 仅当需要显示时将 visible 设为 true
            showAnimation.start()
        } else {
            showAnimation.stop()
            hideAnimation.start()
        }
    }

    SequentialAnimation {
        id: hideAnimation
        running: false
        PauseAnimation { duration: eXLSettings.hidePause ?? 0 }
        ScriptAction {
            script: {
                if(eXLSettings.enableShowAnimation){
                    hideMoveAnimationX.stop();
                    hideMoveAnimationY.stop();
                    showMoveAnimationX.stop();
                    showMoveAnimationY.stop();
                    hideMoveAnimationX.running = true;
                    hideMoveAnimationY.running = true;
                }
            }
        }
        NumberAnimation { target: eXLauncherView; property: "opacity"; to: 0; duration: eXLSettings.showhideDuration ?? 300 }
        ScriptAction {
            script: {
                eXLauncherView.visible = false  // 当动画完成时隐藏组件
            }
        }
    }
    SequentialAnimation {
        id: showAnimation
        running: false
        PauseAnimation { duration: eXLSettings.showPause ?? 0 }
        ScriptAction {
            script: {
                if(eXLSettings.enableShowAnimation){
                    hideMoveAnimationX.stop();
                    hideMoveAnimationY.stop();
                    showMoveAnimationX.stop();
                    showMoveAnimationY.stop();
                    showMoveAnimationX.running = true;
                    showMoveAnimationY.running = true;
                }
            }
        }
        NumberAnimation { target: eXLauncherView; property: "opacity"; to: eXLSettings.viewO ? eXLSettings.viewO/100.0 : 1.0; duration: eXLSettings.showhideDuration ?? 300 }
    }

    NumberAnimation {
        id: showMoveAnimationX
        target: eXLImage;
        property: "x";
        from: Number(eXLSettings.showAnimation_Distance ?? 10) * Math.cos(Number(eXLSettings.showAnimation_Direction ?? 0) * Math.PI / 180);
        to: eXLSettings.viewBGX ?? 0
        duration: eXLauncherView.showAnimation_Duration ?? 300
        easing.type: eXLSettings.showAnimation_Easing ?? 3
    }
    NumberAnimation {
        id: showMoveAnimationY
        target: eXLImage;
        property: "y";
        from: -Number(eXLSettings.showAnimation_Distance ?? 10) * Math.sin(Number(eXLSettings.showAnimation_Direction ?? 0) * Math.PI / 180)
        to: eXLSettings.viewBGY ?? 0
        duration: eXLauncherView.showAnimation_Duration ?? 300
        easing.type: eXLSettings.showAnimation_Easing ?? 3
    }
    NumberAnimation {
        id: hideMoveAnimationX
        target: eXLImage;
        property: "x";
        to: Number(eXLSettings.showAnimation_Distance ?? 10) * Math.cos(Number(eXLSettings.showAnimation_Direction ?? 0) * Math.PI / 180);
        from: eXLSettings.viewBGX ?? 0
        duration: eXLauncherView.showAnimation_Duration ?? 300
        easing.type: eXLSettings.showAnimation_Easing ?? 3
    }
    NumberAnimation {
        id: hideMoveAnimationY
        target: eXLImage;
        property: "y";
        to: -Number(eXLSettings.showAnimation_Distance ?? 10) * Math.sin(Number(eXLSettings.showAnimation_Direction ?? 0) * Math.PI / 180)
        from: eXLSettings.viewBGY ?? 0
        duration: eXLauncherView.showAnimation_Duration ?? 300
        easing.type: eXLSettings.showAnimation_Easing ?? 3
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onClicked: {
            if (mouse.button === Qt.LeftButton) {
                switch(eXLSettings.leftClickEvent ?? 3){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionL.configuration)
                            actionL.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
                switch(eXLSettings.leftClickEvent2 ?? 3){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionL.configuration)
                            actionL.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
            }
            if (mouse.button === Qt.RightButton) {
                switch(eXLSettings.rightClickEvent ?? 0){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionR.configuration)
                            actionR.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
                switch(eXLSettings.rightClickEvent2 ?? 3){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionR.configuration)
                            actionR.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
            }
            if (mouse.button === Qt.MiddleButton) {
                switch(eXLSettings.middleClickEvent ?? 1){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionM.configuration)
                            actionM.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
                switch(eXLSettings.middleClickEvent2 ?? 3){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionM.configuration)
                            actionM.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
            }
        }
    }

    Loader {
        id: dialog
        active: false
        sourceComponent: EXLDialog{
            onClosing: dialog.active = false
        }
    }

    NVG.ImageSource {
        id: eXLImage
        visible: Boolean(eXLSettings.useViewImage)
        fillMode: eXLSettings.viewBGImageFill ?? Image.PreserveAspectFit
        //透明度
        opacity: eXLSettings.viewBGImageOpacity ? eXLSettings.viewBGImageOpacity/100.0 : 1.0
        configuration: eXLSettings.viewBGImage;
        x: eXLSettings.enableShowAnimation ? Number(eXLSettings.showAnimation_Distance ?? 10) * Math.cos(Number(eXLSettings.showAnimation_Direction ?? 0) * Math.PI / 180) : (eXLSettings.viewBGX ?? 0)
        y: eXLSettings.enableShowAnimation ? -Number(eXLSettings.showAnimation_Distance ?? 10) * Math.sin(Number(eXLSettings.showAnimation_Direction ?? 0) * Math.PI / 180) : eXLSettings.viewBGY ?? 0
        width: eXLSettings.viewBGW ?? Screen.width
        height: eXLSettings.viewBGH ?? Screen.height
    }

    NVG.ActionSource {
        id: actionL
        configuration: eXLSettings.action_L
    }
    NVG.ActionSource {
        id: actionR
        configuration: eXLSettings.action_R
    }
    NVG.ActionSource {
        id: actionM
        configuration: eXLSettings.action_M
    }
}

