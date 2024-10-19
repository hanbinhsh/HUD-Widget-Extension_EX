import QtQuick 2.12
import NERvGear 1.0 as NVG
//动画必备
import QtGraphicalEffects 1.12 
import "utils.js" as Utils

import QtWebSockets 1.1

import "../../top.mashiros.widget.advp/qml/" as ADVP
//二级挂件属性
MouseArea {
    // clip:true//超出父项直接裁剪
    id: delegate
    propagateComposedEvents: true

    property Item view // Note: CraftView type recusive
    property NVG.SettingsMap settings
    property int index
    property bool hidden

    property string interactionState: hidden ? "HIDDEN" :
                                      pressed ? "PRESSED" :
                                      containsMouse ? "HOVERED" : "NORMAL"
    property string interactionSource
    property NVG.SettingsMap interactionSettingsBase

    // private

    property Item interactionItem

    onInteractionSourceChanged:  {
        let newItem = null;
        const url = Utils.resolveInteraction(interactionSource);
        if (url) {
            const c = Qt.createComponent(url);
            if (c.status === Component.Ready) {
                newItem = c.createObject(delegate, {
                    // changed between independent and shared settings, or new settings replaced
                    settings: Qt.binding(()=>NVG.Settings.makeMap(interactionSettingsBase, "reaction")),
                    state: Qt.binding(()=>delegate.interactionState)
                });
            } else {
                if (c.status === Component.Error)
                    console.warn(c.errorString());
            }
        }
        if (interactionItem)
            interactionItem.destroy();
        interactionItem = newItem;
    }

    readonly property bool scaleEnabled: Boolean(settings.scale)
    readonly property bool rotateEnabled: Boolean(settings.rotate)
    // Item.transform is not a notifiable property,
    // we need to explicitly define the array property for binding.
    readonly property var transformArray: {
        const initProp = { item: delegate };
        const scale = Utils.makeObject(this, scaleEnabled, cScaleTransform, initProp, "scaleTransform_NB");
        const rotate = Utils.makeObject(this, rotateEnabled, cRotateTransform, initProp, "rotateTransform_NB");
        return [scale, rotate].concat(interactionItem?.extraTransform);
    }

    //增加
    //移动值
    property real mX : ((settings.translateSetting ? (settings.translateX ?? 0) : 0) + (animationX ?? 0)) + cycleMoveX + clickAnimationX + showAnimationX;
    property real mY : ((settings.translateSetting ? (settings.translateY ?? 0) : 0) + (animationY ?? 0)) + cycleMoveY + clickAnimationY + showAnimationY;
    //悬停移动动画
    property real animationX : 0
    property real animationY : 0
    //显示移动动画
    property real showAnimationX : 0
    property real showAnimationY : 0
    //悬停缩放动画
    property real animationZoomX : 0
    property real animationZoomY : 0
    //悬停旋转动画
    property real animationSpin : 0
    //悬停闪烁动画
    property real animationGlimmerTarget : 1
    readonly property real rotationStep: (settings.rotationSpeed ?? 5) * 6 / (settings.rotationFPS ?? 20)
    readonly property bool rotationEnabled: Boolean(delegate.settings.rotationDisplay)
    readonly property bool rotationAnimationEnabled: Boolean(delegate.settings.enableAdvancedRotationAnimation)
    //透明度动态显示
    property real endOpciMask : settings.fadeTransition_end_start ?? 1000
    property real staOpciMask : settings.fadeTransition_sta_start ?? 0
    property real endOpci: 0
    //点击移动动画
    property real clickAnimationX : 0
    property real clickAnimationY : 0
    property bool clickMoveStatus : false
    //动画变量
    readonly property real rotationAnimationStep: (settings.advancedRotationSpeed ?? 5) * 6 / (settings.advancedRotationFPS ?? 20)
    readonly property bool opacityAnimationEnabled: Boolean(settings.enableOpacityAnimation)
    //循环动画变量
        //移动
        property real cycleMoveX : 0
        property real cycleMoveY : 0
        readonly property bool moveCycleEnabled: Boolean(delegate.settings.cycleMove)
        property int moveCycle_Delay: settings.moveCycle_Delay ?? 300              // 启动前的延迟（毫秒）
        property int moveCycle_Duration: settings.moveCycle_Duration ?? 300        // 每次移动的持续时间（毫秒）
        property int moveCycle_Direction: settings.moveCycle_Direction ?? 0      // 移动的方向（度数）
        property int moveCycle_Distance: settings.moveCycle_Distance ?? 10        // 每次移动的距离（像素）
        property int moveCycle_Waiting: settings.moveCycle_Waiting ?? 300          // 每次移动后的等待时间（毫秒）
        property var moveCycle_Easing: settings.moveCycle_Easing ?? 3              // 使用的动画曲线
    //增加

    anchors.top: settings.alignment & Qt.AlignTop ? parent.top : undefined
    anchors.topMargin: settings.top
    anchors.bottom: settings.alignment & Qt.AlignBottom ? parent.bottom : undefined
    anchors.bottomMargin: settings.bottom
    anchors.left: settings.alignment & Qt.AlignLeft ? parent.left : undefined
    anchors.leftMargin: settings.left
    anchors.right: settings.alignment & Qt.AlignRight ? parent.right : undefined
    anchors.rightMargin: settings.right

    anchors.verticalCenter: {
        const align = settings.alignment;
        // default to vertical center
        if (!(align & Qt.AlignVertical_Mask))
            return parent.verticalCenter;

        return align & Qt.AlignTop || align & Qt.AlignBottom ? undefined : parent.verticalCenter;
    }
    anchors.verticalCenterOffset: settings.vertical ?? 0
    anchors.horizontalCenter: {
        const align = settings.alignment;
        // default to horizontal center
        if (!(align & Qt.AlignHorizontal_Mask))
            return parent.horizontalCenter;

        return align & Qt.AlignLeft || align & Qt.AlignRight ? undefined : parent.horizontalCenter;
    }
    anchors.horizontalCenterOffset: settings.horizon ?? 0
    
    //挂件高度
    z: interactionItem?.extraZ ?? settings.z ?? 0
    //挂件旋转
    rotation: (settings.rotation ?? 0)+(animationSpin??0)
    //透明度
    opacity: settings.opacity ?? 1
    //大小
    implicitWidth: 16
    implicitHeight: 16
    //其他
    hoverEnabled: view
    acceptedButtons: view ? Qt.LeftButton : Qt.NoButton
    // transform: transformArray //删除
    width: {
        const align = settings.alignment;
        return (align & Qt.AlignLeft && align & Qt.AlignRight) ?
                    undefined : settings.width
    }
    height: {
        const align = settings.alignment;
        return (align & Qt.AlignTop && align & Qt.AlignBottom) ?
                    undefined : settings.height
    }
    onEntered: if (view) view.currentHighlight = delegate
    onExited: if (view) view.currentHighlight = null
    onClicked: if (view) view.currentTarget = delegate
    //增加
    transform:[
        Rotation {
            origin.x: settings.enableAdvancedRotation ? settings.advancedRotationOriginX ?? 0 : 0
            origin.y: settings.enableAdvancedRotation ? settings.advancedRotationOriginY ?? 0 : 0
            axis {
                x: settings.enableAdvancedRotation ? settings.advancedRotationAxisX ?? 0 : 0
                y: settings.enableAdvancedRotation ? settings.advancedRotationAxisY ?? 0 : 0
                z: settings.enableAdvancedRotation ? settings.advancedRotationAxisZ ?? 0 : 0
            }
            angle: settings.enableAdvancedRotation ? settings.advancedRotationAngle ?? 0 : 0
        },
        Scale {//变换中设置了缩放中心按变换设置的
            origin.x: settings.scaleSetting ? settings.scaleOriginX ?? 0 : 0 + (settings.zoomMouse_OriginX ?? 0)
            origin.y: settings.scaleSetting ? settings.scaleOriginY ?? 0 : 0 + (settings.zoomMouse_OriginY ?? 0)
            xScale: settings.scaleSetting ? (settings.scaleX ?? 1000) / 1000 + (animationZoomX ?? 0) / 1000 : 1 + (animationZoomX ?? 0) / 1000
            yScale: settings.scaleSetting ? (settings.scaleY ?? 1000) / 1000 + (animationZoomY ?? 0) / 1000 : 1 + (animationZoomY ?? 0) / 1000
        },
        Translate {x:mX; y:mY}
    ]
    //旋转动画
    onRotationAnimationEnabledChanged: settings.advancedRotationAngle=0
    Timer {
        repeat: true
        interval: 1000 / (settings.advancedRotationFPS ?? 20)
        running: rotationAnimationEnabled&&widget.NVG.View.exposed
        onTriggered: settings.advancedRotationAngle = (settings.advancedRotationAngle + rotationAnimationStep) % 360
    }
    //透明度动画
    onOpacityAnimationEnabledChanged: settings.opacity=1
    SequentialAnimation {
        running: opacityAnimationEnabled && widget.NVG.View.exposed
        loops:Animation.Infinite
        NumberAnimation {
            target: delegate
            property: "opacity"
            duration: settings.opacityAnimationSpeed ?? 500
            from: 0
            to: 1
        }
        NumberAnimation {
            target: delegate
            property: "opacity"
            duration: settings.opacityAnimationSpeed ?? 500
            from: 1
            to: 0
        }
    }
    //旋转重置
    onRotationEnabledChanged: settings.rotation=0
    //旋转
    Timer {
        repeat: true//重复定时
        interval: 1000 / (settings.rotationFPS ?? 20)//定时时间
        running: rotationEnabled&&widget.NVG.View.exposed//开始条件
        onTriggered: settings.rotation = (settings.rotation + rotationStep) % 360//触发语句
    }
//循环动画
    // 移动动画定义
    SequentialAnimation {
        id: moveAnimation
        running: false              // 初始不运行
        ParallelAnimation {  // 使用 ParallelAnimation 同时动画化 x 和 y
            NumberAnimation {
                target: delegate
                property: "cycleMoveX"
                duration: moveCycle_Duration / 2   // 单程时间是总时间的一半
                easing.type: moveCycle_Easing
            }
            NumberAnimation {
                target: delegate
                property: "cycleMoveY"
                duration: moveCycle_Duration / 2
                easing.type: moveCycle_Easing
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: delegate
                property: "cycleMoveX"
                duration: moveCycle_Duration / 2
                easing.type: moveCycle_Easing
            }
            NumberAnimation {
                target: delegate
                property: "cycleMoveY"
                duration: moveCycle_Duration / 2
                easing.type: moveCycle_Easing
            }
        }
        onStopped:{
            if(!(moveCycleEnabled&&widget.NVG.View.exposed)){
                moveTimer.stop()
                return
            }
            moveTimer.start()  // 动画完成后重新启动定时器
        } 
    }
    // 延迟启动定时器
    Timer {
        id: delayTimer
        interval: moveCycle_Delay
        repeat: false
        running: moveCycleEnabled&&widget.NVG.View.exposed//开始条件
        onTriggered: {
            // 设置后续循环的定时器
            moveTimer.start()
        }
    }
    // 循环定时器
    Timer {
        id: moveTimer
        interval: moveCycle_Duration + moveCycle_Waiting
        running: false
        repeat: false
        onTriggered: {
            startAnimation()  // 启动延迟定时器
        }
    }
    // 启动动画函数
    function startAnimation() {
        // 计算移动的目标位置
        var radians = Math.PI * moveCycle_Direction / 180.0;
        var deltaX = Math.cos(radians) * moveCycle_Distance;
        var deltaY = Math.sin(radians) * moveCycle_Distance;
        // 更新动画目标位置
        moveAnimation.animations[0].animations[0].from = 0;
        moveAnimation.animations[0].animations[0].to = deltaX;
        moveAnimation.animations[0].animations[1].from = 0;
        moveAnimation.animations[0].animations[1].to = deltaY;
        moveAnimation.animations[1].animations[0].from = deltaX;
        moveAnimation.animations[1].animations[0].to = 0;
        moveAnimation.animations[1].animations[1].from = deltaY;
        moveAnimation.animations[1].animations[1].to = 0;
        // 启动动画
        moveAnimation.start();
    }
    Gradient {
        id: grad
        GradientStop { position: staOpciMask/1000.0; color: Qt.rgba(255, 255, 255, 1) }// sta
        GradientStop { position: endOpciMask/1000.0; color: Qt.rgba(255, 255, 255, endOpci/100.0) }// end
    }
    LinearGradient {
        id: linearG
        anchors.fill: parent
        visible: false
        gradient: grad
        start: {
            switch (settings.fadeTransitionDirect ?? 1) {
                case 0 : 
                case 1 : 
                case 2 : 
                case 3 : return Qt.point(0, 0); break; 
                case 5 : return Qt.point(settings.fadeTransitionAdvancedStartX ?? 0, settings.fadeTransitionAdvancedStartY ?? 0); break;
                default: return Qt.point(0, 0); break;
            }
            return Qt.point(0, 0);
        }
        end: {
            switch (settings.fadeTransitionDirect ?? 1) {
                case 0 : return Qt.point(delegate.width, 0); break;//1.横向渐变
                case 1 : return Qt.point(0, delegate.height); break;//2.竖向渐变
                case 2 : return Qt.point(delegate.width, delegate.height); break;//3.斜向渐变
                case 5 : return Qt.point(settings.fadeTransitionAdvancedEndX ?? 100, settings.fadeTransitionAdvancedEndY ?? 100); break;
                default: return Qt.point(delegate.width, 0); break; 
            }
            return Qt.point(delegate.width, 0);
        }
        cached: settings.fadeTransitionCached ?? false
    }
    // 3
    RadialGradient {
        id: radialG
        visible: false
        anchors.fill: parent
        gradient: grad
        angle: settings.fadeTransitionAngle ?? 0
        horizontalOffset: settings.fadeTransitionHorizontal ?? 0
        verticalOffset: settings.fadeTransitionVertical ?? 0
        horizontalRadius: settings.fadeTransitionHorizontalRadius ?? 50
        verticalRadius: settings.fadeTransitionVerticalRadius ?? 50
        cached: settings.fadeTransitionCached ?? false
    }
    // 4
    ConicalGradient {
        id: conicalG
        visible: false
        anchors.fill: parent
        gradient: grad
        angle: settings.fadeTransitionAngle ?? 0
        horizontalOffset: settings.fadeTransitionHorizontal ?? 0
        verticalOffset: settings.fadeTransitionVertical ?? 0
        cached: settings.fadeTransitionCached ?? false
    }
    layer {
        enabled: settings.enableFadeTransition ?? false
        effect: OpacityMask {
            maskSource: switch(settings.fadeTransitionDirect ?? 1){
                case 0:
                case 1:
                case 2:
                case 5: return linearG;
                case 3: return radialG;
                case 4: return conicalG;
                default: return linearG;
            }
        }
    }

    // 音频显示
    NVG.ImageSource {
        id: aDVImage_source
        anchors.fill: parent
        visible: Boolean(settings.enableADV && settings.showADVImage)
        fillMode: settings.aDVImageFill ?? Image.PreserveAspectFit
        //透明度
        opacity: 1
        configuration: settings.aDVImage;
    }
    GaussianBlur {
        id: aDVImage_source_gaussian
        anchors.fill: delegate
        source: settings.useADVGaussian ? aDVImage_source : null
        visible: Boolean(settings.useADVGaussian && settings.enableADV)
        radius: settings.aDVGaussianBlurRadius ?? 5//半径
        deviation: settings.aDVGaussianBlurDeviation ?? 3//偏差值
        samples: settings.aDVGaussianBlurSamples ?? 5//样本数
        transparentBorder: settings.aDVDropShadowTransparentBorder ?? false//透明边框
        cached: settings.aDVGaussianBlurCached ?? false//缓存
    }
    Connections {
        enabled: settings.enableADV ?? false
        target: ADVP.Common
        onAudioDataUpdated: updatedAudioData(audioData)
    }
    property int opaADV: 0
    ColorOverlay{
        visible: settings.enableADV ?? false
        anchors.fill: delegate
        source: settings.useADVGaussian ? aDVImage_source_gaussian : aDVImage_source
        color: settings.aDVColor ?? "white"
        opacity: opaADV/100.0
        z: settings.aDVZ ?? -1
    }
    function updatedAudioData(audioData) {
        let v = 0;
        let s = Math.pow(2,settings.aDVSample ?? 0)
        for (let i=0;i<128;i+=s) {
            v += audioData[i]
        }
        opaADV = v*5/(128/s)
    }
}