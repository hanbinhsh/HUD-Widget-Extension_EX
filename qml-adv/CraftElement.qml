import QtQuick 2.12
import QtQuick.Window 2.12
import QtGraphicalEffects.private 1.12

import NERvGear 1.0 as NVG

import "utils.js" as Utils

CraftDelegate {
    id: craftElement

    readonly property string title: loader.item?.title ?? ""

    readonly property Component preference: loader.item?.preference ?? null
    readonly property NVG.SettingsMap effectSettings: settings.effect ?? null

    property NVG.SettingsMap itemSettings
    property NVG.DataSource itemData
    property NVG.BackgroundSource itemBackground

    implicitWidth: Math.max(loader.implicitWidth, 16)
    implicitHeight: Math.max(loader.implicitHeight, 16)

    Loader {
        id: loader
        anchors.fill: parent

        parent: craftElement.interactionItem?.contentParent ?? craftElement
        opacity: craftElement.settings.opacity ?? 1.0
        sourceComponent: {
            const element = Utils.findElement(craftElement.settings.content);
            if (element)
                return element.component;

            return Qt.createComponent(Qt.resolvedUrl(craftElement.settings.content));
        }

        layer.enabled: Boolean(effectSettings?.enabled)
        layer.effect: Item {
            id: effect

            readonly property color normalColor: effectSettings.color ?? "transparent"
            readonly property color hoveredColor: effectSettings.hoveredColor ?? normalColor
            readonly property color pressedColor: effectSettings.pressedColor ?? hoveredColor

            readonly property color color: itemBackground.pressed ? pressedColor : 
                                           itemBackground.hovered ? hoveredColor : 
                                           normalColor

            readonly property real xOffset: effectSettings.horizon ?? 0
            readonly property real yOffset: effectSettings.vertical ?? 0

            // GaussianBlur
            property var source
            property var maskSource
            readonly property real radius: effectSettings.blur ?? 0
            readonly property real deviation: (radius + 1) / 3.3333
            readonly property int samples: Math.floor(radius * 2) + 1
            readonly property int paddedTexWidth: width + 2 * radius
            readonly property int paddedTexHeight: height + 2 * radius
            readonly property int kernelRadius: Math.max(0, samples / 2)
            readonly property int kernelSize: kernelRadius * 2 + 1
            readonly property int dpr: Screen.devicePixelRatio
            readonly property bool alphaOnly: color.a
            readonly property real thickness: effectSettings.spread ?? 0

            onSamplesChanged: rebuildShaders();
            onKernelSizeChanged: rebuildShaders();
            onDeviationChanged: rebuildShaders();
            onDprChanged: rebuildShaders();
            onMaskSourceChanged: rebuildShaders();
            onAlphaOnlyChanged: rebuildShaders();
            Component.onCompleted: rebuildShaders();

            function rebuildShaders() {
                var params = {
                    radius: kernelRadius,
                    // Limit deviation to something very small avoid getting NaN in the shader.
                    deviation: Math.max(0.00001, deviation),
                    alphaOnly: effect.alphaOnly,
                    masked: maskSource !== undefined,
                    fallback: effect.radius != kernelRadius
                }
                var shaders = ShaderBuilder.gaussianBlur(params);
                horizontalBlur.fragmentShader = shaders.fragmentShader;
                horizontalBlur.vertexShader = shaders.vertexShader;
            }

            Item {
                x: -effectSource.x - effect.radius
                y: -effectSource.y
                width: effect.paddedTexWidth + Math.max(Math.abs(effect.xOffset) - effect.radius, 0)
                height: effect.paddedTexHeight + Math.max(Math.abs(effect.yOffset) - effect.radius, 0)

                layer.enabled: effectSettings.original === 2
                layer.smooth: true

                SourceProxy {
                    id: sourceProxy
                    interpolation: SourceProxy.LinearInterpolation
                    input: effect.source
                    sourceRect: Qt.rect(-effect.radius, 0, effect.paddedTexWidth, effect.height)
                }

                ShaderEffect {
                    id: horizontalBlur
                    width: effect.paddedTexWidth
                    height: effect.height

                    // Used by all shaders
                    property Item source: sourceProxy.output
                    property real spread: effect.radius / effect.kernelRadius
                    property vector2d dirstep: Qt.vector2d(1 / (effect.paddedTexWidth * effect.dpr), 0)

                    // Used by fallback shader (sampleCount exceeds number of varyings)
                    property real deviation: effect.deviation

                    // Only in use for DropShadow and Glow
                    property color color: "white"
                    property real thickness: Math.max(0, Math.min(0.98, 1 - effect.thickness * 0.98))

                    // Only in use for MaskedBlur
                    property var mask: effect.maskSource

                    layer.enabled: true
                    layer.smooth: true
                    layer.sourceRect: Qt.rect(0, -effect.radius, width, effect.paddedTexHeight)
                    visible: false
                    blending: false
                }

                ShaderEffect {
                    id: verticalBlur
                    x: Math.max(effect.xOffset - effect.radius, 0)
                    y: Math.max(effect.yOffset - effect.radius, 0)
                    width: effect.paddedTexWidth
                    height: effect.paddedTexHeight
                    fragmentShader: horizontalBlur.fragmentShader
                    vertexShader: horizontalBlur.vertexShader

                    property Item source: horizontalBlur
                    property real spread: horizontalBlur.spread
                    property vector2d dirstep: Qt.vector2d(0, 1 / (effect.paddedTexHeight * effect.dpr))

                    property real deviation: horizontalBlur.deviation

                    property color color: effect.color
                    property real thickness: horizontalBlur.thickness

                    property var mask: horizontalBlur.mask
                }

                ShaderEffect {
                    id: effectSource
                    x: -effect.xOffset + verticalBlur.x
                    y: effect.radius - effect.yOffset + verticalBlur.y
                    width: sourceProxy.sourceRect.width
                    height:sourceProxy.sourceRect.height
                    visible: Boolean(effectSettings.original)

                    readonly property var source: sourceProxy.output
                }
            }
        }
    }
    //鼠标动作，悬停动作
    // TODO 点击动作
    //移动动画
    NumberAnimation on animationX {
        id: moveAnimationX
        running: false
        duration: settings.moveHover_Duration ?? 300// 动画持续时间，单位为毫秒
        easing.type: settings.moveOnHover_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    NumberAnimation on animationY {
        id: moveAnimationY
        running: false
        duration: settings.moveHover_Duration ?? 300 // 动画持续时间，单位为毫秒
        easing.type: settings.moveOnHover_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    //缩放动画
    NumberAnimation on animationZoomX {
        id: animationZoomX
        running: false
        duration: settings.zoomHover_Duration ?? 300// 动画持续时间，单位为毫秒
        easing.type: settings.zoomHover_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    NumberAnimation on animationZoomY {
        id: animationZoomY
        running: false
        duration: settings.zoomHover_Duration ?? 300 // 动画持续时间，单位为毫秒
        easing.type: settings.zoomHover_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    NumberAnimation on animationZoomX {
        id: animationZoomX_Click
        running: false
        duration: settings.zoomClick_Duration ?? 300// 动画持续时间，单位为毫秒
        easing.type: settings.zoomHover_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    NumberAnimation on animationZoomY {
        id: animationZoomY_Click
        running: false
        duration: settings.zoomClick_Duration ?? 300 // 动画持续时间，单位为毫秒
        easing.type: settings.zoomHover_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    //旋转动画
    NumberAnimation on animationSpin {
        id: animationSpin
        running: false
        duration: settings.spinHover_Duration ?? 300 // 动画持续时间，单位为毫秒
        easing.type: settings.spinHover_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    NumberAnimation on animationSpin {
        id: animationSpin_Click
        running: false
        duration: settings.spinClick_Duration ?? 300 // 动画持续时间，单位为毫秒
        easing.type: settings.spinClick_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    //闪烁动画
    SequentialAnimation {
        id: animationGlimmer
        running: false
        loops:Animation.Infinite
        NumberAnimation{
            target: craftElement
            property: "opacity"
            from: 1
            to: (settings.glimmerHover_MinOpacity ?? 0)/100
            duration: settings.glimmerHover_Duration ?? 300
            easing.type: settings.glimmerHover_Easing ?? 3
        }

        NumberAnimation{
            target: craftElement
            property: "opacity"
            from: (settings.glimmerHover_MinOpacity ?? 0)/100
            to: 1
            duration: settings.glimmerHover_Duration ?? 300
            easing.type: settings.glimmerHover_Easing ?? 3
        }
    }
    NumberAnimation{
        id: recoverOpacity
        running: false
        target: craftElement
        property: "opacity"
        from: craftElement.opacity
        to: 1
        duration: 100 // 动画持续时间，单位为毫秒
        easing.type: settings.glimmerHover_Easing ?? 3// 使用缓动函数使动画更平滑
    }
    //鼠标区域
    MouseArea{
        hoverEnabled: Boolean(settings.moveOnHover||settings.zoomOnHover||settings.spinOnHover||settings.glimmerOnHover)
        anchors.fill: settings.enableAction ? parent : undefined
        onEntered: {
            if(settings.moveOnHover){
                moveAnimationX.stop()
                moveAnimationY.stop()
                moveAnimationX.to =  Number(settings.moveHover_Distance??10) * Math.cos(Number(settings.moveHover_Direction??0) * Math.PI / 180)
                moveAnimationY.to = -Number(settings.moveHover_Distance??10) * Math.sin(Number(settings.moveHover_Direction??0) * Math.PI / 180)
                moveAnimationX.running = true
                moveAnimationY.running = true
            }
            if(settings.zoomOnHover){
                animationZoomX.stop()
                animationZoomY.stop()
                animationZoomX.to = Number(settings.zoomHover_XSize??100)
                animationZoomY.to = Number(settings.zoomHover_YSize??100)
                animationZoomX.running = true
                animationZoomY.running = true
            }
            if(settings.spinOnHover){
                animationSpin.stop()
                animationSpin.to = Number(settings.spinHover_Direction??360)
                animationSpin.running = true
            }
            if(settings.glimmerOnHover){
                animationGlimmer.running = true
            }
        }
        onExited: {
            if(settings.moveOnHover){
                moveAnimationX.stop()
                moveAnimationY.stop()
                moveAnimationX.to = 0
                moveAnimationY.to = 0
                moveAnimationX.running = true
                moveAnimationY.running = true
            }
            if(settings.zoomOnHover){
                animationZoomX.stop()
                animationZoomY.stop()
                animationZoomX.to = 0
                animationZoomY.to = 0
                animationZoomX.running = true
                animationZoomY.running = true
            }
            if(settings.spinOnHover){
                animationSpin.stop()
                animationSpin.to = 0
                animationSpin.running = true
            }
            if(settings.glimmerOnHover){
                animationGlimmer.running = false
                recoverOpacity.start()
            }
        }
        onClicked: {
            //选择了动作
            if (settings.action&&settings.enableAction) {
                actionSource.trigger(this);
                return;
            }
        }
        onPressed: {
            if(settings.zoomOnClick){
                animationZoomX_Click.stop()
                animationZoomY_Click.stop()
                animationZoomX_Click.to = Number(settings.zoomClick_XSize ?? 100)
                animationZoomY_Click.to = Number(settings.zoomClick_YSize ?? 100)
                animationZoomX_Click.running = true
                animationZoomY_Click.running = true
            }
            if(settings.spinOnClick){
                animationSpin_Click.stop()
                animationSpin_Click.to += Number(settings.spinClick_Direction??360)
                animationSpin_Click.running = true
            }
        }
        onReleased:{
            if(settings.zoomOnClick){
                animationZoomX_Click.stop()
                animationZoomY_Click.stop()
                animationZoomX_Click.to = settings.zoomOnHover ? Number(settings.zoomHover_XSize ?? 100) : 0
                animationZoomY_Click.to = settings.zoomOnHover ? Number(settings.zoomHover_YSize ?? 100) : 0
                animationZoomX_Click.running = true
                animationZoomY_Click.running = true
            }
            if(settings.spinOnClick&&!settings.spinOnClickInstantRecuvery){
                animationSpin_Click.stop()
                animationSpin_Click.to = 0
                animationSpin_Click.running = true
            }
        }
        NVG.ActionSource {
            id: actionSource
            configuration: settings.action
        }
    }
}