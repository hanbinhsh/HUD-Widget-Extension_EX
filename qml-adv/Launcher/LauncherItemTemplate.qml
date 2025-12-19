import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.2
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

import "."
import "../../../top.mashiros.widget.advp/qml/" as ADVP

Item{
    id: thiz
    property Item view
    property NVG.SettingsMap settings
    property int index

    visible: settings.showWithLauncher ?? true
    
    z: settings.viewItemZ ?? 0

    property real showAnimationX: 0
    property real showAnimationY: 0
    property real moveAnimationX: 0
    property real moveAnimationY: 0
    
    x: {
        if(settings.enableShowAnimation){
            return (settings.viewBGX ?? 0) + showAnimationX + moveAnimationX
        }else{
            return (settings.viewBGX ?? 0) + moveAnimationX
        }
    }
    y: {
        if(settings.enableShowAnimation){
            return (settings.viewBGY ?? 0) + showAnimationY + moveAnimationY
        }else{
            return (settings.viewBGY ?? 0) + moveAnimationY
        }
    }
    width: settings.viewBGW ?? Screen.width
    height: settings.viewBGH ?? Screen.height

    Connections {
        enabled: true
        target: eXLauncherView
        onVChanged: onVisible()
        onShowItem: {if(i === index){hideItem()}}
        onHideItem: {if(i === index){showItem()}}
        onToggleItem: {if(i === index){toggleItem()}}
    }
    function onVisible() { 
        if(isVisible){if(settings.showWithLauncher ?? true){showItem()}
        }else{if(settings.hideWithLauncher ?? true){hideItem() }}
    }
    function toggleItem() { thiz.visible ? hideItem() : showItem() }
    function showItem(){
        hideAnimation.stop()
        
        // ---【新增/修改】初始化起始状态 ---
        // 1. 先把透明度设为 0，防止暂停期间直接显示出来
        thiz.opacity = 0; 
        
        // 2. 如果启用了移动动画，先把坐标设置到由 'from' 计算出的起始位置
        // 这样在 PauseAnimation 期间，物体也是在起始位置等待，而不是在终点等待
        if(settings.enableShowAnimation){
            var dist = Number(settings.showAnimation_Distance ?? 10);
            var dir = Number(settings.showAnimation_Direction ?? 0) * Math.PI / 180;
            
            // 下面的公式要和你 showMoveAnimationX/Y 里的 from 逻辑保持一致
            thiz.showAnimationX = dist * Math.cos(dir);
            thiz.showAnimationY = -dist * Math.sin(dir); 
        } else {
            // 如果没开动画，确保偏移归零
            thiz.showAnimationX = 0;
            thiz.showAnimationY = 0;
        }
        // --------------------------------

        thiz.visible = true
        showAnimation.start()
    }
    function hideItem(){
        showAnimation.stop()
        hideAnimation.start()
    }
    //////////////////////////////////Animations//////////////////////////////////
    SequentialAnimation {
        id: hideAnimation
        running: false
        PauseAnimation { duration: settings.hidePause ?? 0 }
        ScriptAction {
            script: {
                if(settings.enableShowAnimation){
                    hideMoveAnimationX.stop();
                    hideMoveAnimationY.stop();
                    showMoveAnimationX.stop();
                    showMoveAnimationY.stop();
                    hideMoveAnimationX.running = true;
                    hideMoveAnimationY.running = true;
                }
            }
        }
        NumberAnimation { target: thiz; property: "opacity"; to: 0; duration: settings.showhideDuration ?? 300 }
        ScriptAction {
            script: {
                thiz.visible = false  // 当动画完成时隐藏组件
            }
        }
    }
    SequentialAnimation {
        id: showAnimation
        running: false
        PauseAnimation { duration: settings.showPause ?? 0 }
        ScriptAction {
            script: {
                if(settings.enableShowAnimation){
                    hideMoveAnimationX.stop();
                    hideMoveAnimationY.stop();
                    showMoveAnimationX.stop();
                    showMoveAnimationY.stop();
                    showMoveAnimationX.running = true;
                    showMoveAnimationY.running = true;
                }
            }
        }
        NumberAnimation {
            target: thiz;
            property: "opacity";
            from: 0; 
            to: settings.viewO ? settings.viewO/100.0 : 1.0;
            duration: settings.showhideDuration ?? 300
        }
    }
    NumberAnimation {
        id: showMoveAnimationX
        target: thiz
        property: "showAnimationX";
        from: Number(settings.showAnimation_Distance ?? 10) * Math.cos(Number(settings.showAnimation_Direction ?? 0) * Math.PI / 180);
        to: 0
        duration: settings.showAnimation_Duration ?? 300
        easing.type: settings.showAnimation_Easing ?? 3
    }
    NumberAnimation {
        id: showMoveAnimationY
        target: thiz
        property: "showAnimationY";
        from: -Number(settings.showAnimation_Distance ?? 10) * Math.sin(Number(settings.showAnimation_Direction ?? 0) * Math.PI / 180)
        to: 0
        duration: settings.showAnimation_Duration ?? 300
        easing.type: settings.showAnimation_Easing ?? 3
    }
    NumberAnimation {
        id: hideMoveAnimationX
        target: thiz
        property: "showAnimationX";
        to: Number(settings.showAnimation_Distance ?? 10) * Math.cos(Number(settings.showAnimation_Direction ?? 0) * Math.PI / 180);
        from: 0
        duration: settings.showAnimation_Duration ?? 300
        easing.type: settings.showAnimation_Easing ?? 3
    }
    NumberAnimation {
        id: hideMoveAnimationY
        target: thiz
        property: "showAnimationY";
        to: -Number(settings.showAnimation_Distance ?? 10) * Math.sin(Number(settings.showAnimation_Direction ?? 0) * Math.PI / 180)
        from: 0
        duration: settings.showAnimation_Duration ?? 300
        easing.type: settings.showAnimation_Easing ?? 3
    }
    //////////////////////////////////Animations//////////////////////////////////
    NVG.ImageSource {
        id: eXLImage
        visible: Boolean(!settings.hideOriginal)
        fillMode: settings.viewBGImageFill ?? Image.PreserveAspectFit
        playing: status === Image.Ready
        //透明度
        opacity: settings.viewBGImageOpacity ? settings.viewBGImageOpacity/100.0 : 1.0
        configuration: settings.viewBGImage;
        anchors.fill: parent
        z: settings.viewBGZ ?? 0
    }
    ColorOverlay{
        visible:settings.colorOverlay ?? false
        anchors.fill: eXLImage
        source: eXLImage
        color: settings.overlayColor ?? "transparent"
        z: settings.overlayColorZ ?? 0
        opacity: settings.overlayColorOpacity ? settings.overlayColorOpacity/100.0 : 100
    }
    NumberAnimation {
        loops: Animation.Infinite
        target: thiz
        property: "moveAnimationX"
        from: settings.moveAnimation_XFrom ?? 0
        to: settings.moveAnimation_XTo ?? 0
        duration: settings.moveAnimation_DurationX ?? 3000
        running: settings.enableMoveAnimation ?? false
    }
    NumberAnimation {
        loops: Animation.Infinite
        target: thiz
        property: "moveAnimationY"
        from: settings.moveAnimation_YFrom ?? 0
        to: settings.moveAnimation_YTo ?? 0
        duration: settings.moveAnimation_DurationY ?? 3000
        running: settings.enableMoveAnimation ?? false
    }
    // 音频显示
    ColorOverlay{
        visible: settings.enableEXLADV ?? false
        anchors.fill: eXLImage
        source: eXLImage
        color: settings.eXLADVColor ?? "white"
        opacity: (opaADV/100.0)/((settings.eXLADVDecrease ?? 1000)/1000)
        z: settings.eXLADVZ ?? -1
    }
}