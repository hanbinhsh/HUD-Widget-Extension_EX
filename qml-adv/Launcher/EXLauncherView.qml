import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.2
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

import "."
import "../../../top.mashiros.widget.advp/qml/" as ADVP

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

    function toggleSetting() {
        dialog.active = true
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

    Connections {
        enabled: Boolean((eXLSettings.enableEXLADV||eXLSettings.adv_enableEXLADV)&&isVisible)
        target: ADVP.Common
        onAudioDataUpdated: updatedAudioData(audioData)
    }
    function updatedAudioData(audioData) {
        let v = 0;
        let s = Math.pow(2,eXLSettings.eXLADVSample ?? 0)
        for (let i=0;i<128;i+=s) {
            v += audioData[i]
        }
        opaADV = v*5/(128/s)
    }
    property int opaADV: 0

    Loader {
        id: dialog
        active: false
        sourceComponent: EXLDialog{
            onClosing: dialog.active = false
        }
    }
    //////////////////////////////////NOR  NOR  NOR  NOR  NOR  NOR  NOR  NOR//////////////////////////////////
    NVG.ImageSource {
        id: eXLImage
        visible: Boolean(eXLSettings.useViewImage&&!eXLSettings.hideOriginal)
        fillMode: eXLSettings.viewBGImageFill ?? Image.PreserveAspectFit
        playing: status === Image.Ready
        //透明度
        opacity: eXLSettings.viewBGImageOpacity ? eXLSettings.viewBGImageOpacity/100.0 : 1.0
        configuration: eXLSettings.viewBGImage;
        x: eXLSettings.enableShowAnimation ? Number(eXLSettings.showAnimation_Distance ?? 10) * Math.cos(Number(eXLSettings.showAnimation_Direction ?? 0) * Math.PI / 180) : (eXLSettings.viewBGX ?? 0)
        y: eXLSettings.enableShowAnimation ? -Number(eXLSettings.showAnimation_Distance ?? 10) * Math.sin(Number(eXLSettings.showAnimation_Direction ?? 0) * Math.PI / 180) : eXLSettings.viewBGY ?? 0
        width: eXLSettings.viewBGW ?? Screen.width
        height: eXLSettings.viewBGH ?? Screen.height
        z: eXLSettings.viewBGZ ?? 0
    }
    ColorOverlay{
        visible:eXLSettings.colorOverlay ?? false
        anchors.fill: eXLImage
        source: eXLImage
        color: eXLSettings.overlayColor ?? "transparent"
        z: eXLSettings.overlayColorZ ?? 0
        opacity: eXLSettings.overlayColorOpacity ? eXLSettings.overlayColorOpacity/100.0 : 100
    }
    NumberAnimation {
        loops: Animation.Infinite
        target: eXLImage
        property: "x"
        from: eXLSettings.moveAnimation_XFrom ?? 0
        to: eXLSettings.moveAnimation_XTo ?? 0
        duration: eXLSettings.moveAnimation_DurationX ?? 3000
        running: eXLSettings.enableMoveAnimation ?? false
    }
    NumberAnimation {
        loops: Animation.Infinite
        target: eXLImage
        property: "y"
        from: eXLSettings.moveAnimation_YFrom ?? 0
        to: eXLSettings.moveAnimation_YTo ?? 0
        duration: eXLSettings.moveAnimation_DurationY ?? 3000
        running: eXLSettings.enableMoveAnimation ?? false
    }
    // 音频显示
    ColorOverlay{
        visible: eXLSettings.enableEXLADV ?? false
        anchors.fill: eXLImage
        source: eXLImage
        color: eXLSettings.eXLADVColor ?? "white"
        opacity: (opaADV/100.0)/((eXLSettings.eXLADVDecrease ?? 1000)/1000)
        z: eXLSettings.eXLADVZ ?? -1
    }
    //////////////////////////////////ADV  ADV  ADV  ADV  ADV  ADV  ADV  ADV//////////////////////////////////
    NVG.ImageSource {
        id: adv_eXLImage
        visible: Boolean(eXLSettings.adv_useViewImage&&!eXLSettings.adv_hideOriginal)
        fillMode: eXLSettings.adv_viewBGImageFill ?? Image.PreserveAspectFit
        playing: status === Image.Ready
        //透明度
        opacity: eXLSettings.adv_viewBGImageOpacity ? eXLSettings.adv_viewBGImageOpacity/100.0 : 1.0
        configuration: eXLSettings.adv_viewBGImage;
        x: eXLSettings.adv_enableShowAnimation ? Number(eXLSettings.adv_showAnimation_Distance ?? 10) * Math.cos(Number(eXLSettings.adv_showAnimation_Direction ?? 0) * Math.PI / 180) : (eXLSettings.adv_viewBGX ?? 0)
        y: eXLSettings.adv_enableShowAnimation ? -Number(eXLSettings.adv_showAnimation_Distance ?? 10) * Math.sin(Number(eXLSettings.adv_showAnimation_Direction ?? 0) * Math.PI / 180) : eXLSettings.adv_viewBGY ?? 0
        width: eXLSettings.adv_viewBGW ?? Screen.width
        height: eXLSettings.adv_viewBGH ?? Screen.height
        z: eXLSettings.adv_viewBGZ ?? 0
    }
    ColorOverlay{
        visible:eXLSettings.adv_colorOverlay ?? false
        anchors.fill: adv_eXLImage
        source: adv_eXLImage
        color: eXLSettings.adv_overlayColor ?? "transparent"
        z: eXLSettings.adv_overlayColorZ ?? 0
        opacity: eXLSettings.adv_overlayColorOpacity ? eXLSettings.adv_overlayColorOpacity/100.0 : 100
    }
    NumberAnimation {
        loops: Animation.Infinite
        target: adv_eXLImage
        property: "x"
        from: eXLSettings.adv_moveAnimation_XFrom ?? 0
        to: eXLSettings.adv_moveAnimation_XTo ?? 0
        duration: eXLSettings.adv_moveAnimation_DurationX ?? 3000
        running: eXLSettings.adv_enableMoveAnimation ?? false
    }
    NumberAnimation {
        loops: Animation.Infinite
        target: adv_eXLImage
        property: "y"
        from: eXLSettings.adv_moveAnimation_YFrom ?? 0
        to: eXLSettings.adv_moveAnimation_YTo ?? 0
        duration: eXLSettings.adv_moveAnimation_DurationY ?? 3000
        running: eXLSettings.adv_enableMoveAnimation ?? false
    }
    // 音频显示
    ColorOverlay{
        id: adv_ADVCO
        visible: eXLSettings.adv_enableEXLADV ?? false
        anchors.fill: adv_eXLImage
        source: adv_eXLImage
        color: eXLSettings.adv_eXLADVColor ?? "white"
        opacity: (opaADV/100.0)/((eXLSettings.adv_eXLADVDecrease ?? 1000)/1000)
        z: eXLSettings.adv_eXLADVZ ?? -1
    }
}

