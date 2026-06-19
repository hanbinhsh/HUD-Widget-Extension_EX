import QtQuick 2.12
import QtQuick.Window 2.12
import QtGraphicalEffects.private 1.12
import QtGraphicalEffects 1.12 

import NERvGear 1.0 as NVG

import "utils.js" as Utils

import "elements"

import "Launcher" as LC

import "./Utils/ColorAnimation.js" as GradientUtils

CraftDelegate {
    id: craftElement

    readonly property string title: loader.item?.title ?? ""

    readonly property Component preference: loader.item?.preference ?? null
    readonly property NVG.SettingsMap effectSettings: settings.effect ?? null
    // 高级特效（独立于上面的基础 layer 特效）
    readonly property NVG.SettingsMap advancedEffectSettings: settings.advancedEffect ?? null
    readonly property bool advancedEffectEnabled: Boolean(advancedEffectSettings?.enabled)

    property NVG.SettingsMap itemSettings
    property NVG.DataSource itemData
    property NVG.BackgroundSource itemBackground

    //  最新原版新增
    property MouseArea itemArea
    property MouseArea superArea
    property alias contentEnabled: loader.enabled
    visible: animationVisible
    hidden: {
        switch (settings.visibility) {
        case "normal":  return superArea.containsMouse;
        case "hovered": return !superArea.containsMouse;
        default: break;
        }
        return false;
    }
    interactionIndependent: Boolean(loader.item?.independentInteractionArea)
    Component.onCompleted: {
        // upgrade settings
        if (settings.effect?.enabled && !settings.filter) {
            settings.effect.enabled = undefined;
            settings.filter = "basic";
        }

        // don't animate intial state
        loader.opacity = hidden ? 0 : 1;
        animationVisible = !hidden;
        hiddenChanged.connect(function () {
            if (!visibilityAnimation) {
                visibilityAnimation = cVisibilityAnimation.createObject(craftElement, {
                                                                            target: loader
                                                                        });
                visibilityAnimation.started.connect(() => animationVisible = true);
                visibilityAnimation.finished.connect(() => animationVisible = visibilityAnimation.to > 0);
            }
            visibilityAnimation.to = (hidden ? 0 : 1);
            if (visibilityAnimation.to !== loader.opacity)
                visibilityAnimation.restart();
        });
    }

    implicitWidth: Math.max(loader.implicitWidth, 16)
    implicitHeight: Math.max(loader.implicitHeight, 16)

    Connections {
        enabled: true
        target: LC.LauncherCore
    }

    property NumberAnimation visibilityAnimation
    property bool animationVisible: true

    Loader {
        id: loader
        anchors.fill: parent
        z: 0

        // enabled: !widget.editing

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

            // 为了让EXL能够正常处理颜色逻辑，这里加上了interactionMouseArea.pressed和visualMouseArea.containsMouse
            readonly property color color: (itemBackground.pressed || interactionMouseArea.pressed) ? pressedColor : 
                                   (itemBackground.hovered || visualMouseArea.containsMouse) ? hoveredColor : 
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
            Component.onCompleted: {
                rebuildShaders();
                Qt.callLater(gradLayer.initCustomGradient)
            }

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

    // 高级特效叠加层（完整 QtGraphicalEffects 集，复用 ImageEffectStack）。
    // 把元素内容(loader)捕获为纹理，叠加完整特效；仅在 advancedEffect.enabled 时实例化/渲染。
    ShaderEffectSource {
        id: advFxSource
        anchors.fill: parent
        sourceItem: loader
        live: craftElement.advancedEffectEnabled
        hideSource: false   // 保留原内容可见，特效在其上叠加
        visible: false
    }
    Loader {
        id: advFxLoader
        anchors.fill: advFxSource
        active: craftElement.advancedEffectEnabled && Boolean(craftElement.advancedEffectSettings)
        sourceComponent: Item {
            anchors.fill: parent
            // cycleColor 颜色循环渐变驱动器（为下面的 ImageEffectStack 提供 gradient）
            ColorCycleGradient {
                id: advColorCycle
                settings: craftElement.advancedEffectSettings
                viewExposed: craftElement.NVG.View.exposed
            }
            ImageEffectStack {
                sourceItem: advFxSource
                settings: craftElement.advancedEffectSettings
                dataSource: craftElement.itemData
                itemPressed: (craftElement.itemBackground?.pressed ?? false) || interactionMouseArea.pressed
                itemHovered: (craftElement.itemBackground?.hovered ?? false) || visualMouseArea.containsMouse
                gradient: advColorCycle.gradient
            }
        }
    }

    MouseArea {
        id: visualMouseArea
        anchors.fill: parent
        z: -1
        
        propagateComposedEvents: true
        hoverEnabled: Boolean(settings.moveOnHover||settings.zoomOnHover||settings.spinOnHover||settings.glimmerOnHover||
                        (effectSettings?.hoveredColor ?? false)||(effectSettings?.pressedColor ?? false))
        //这里为了让EXL能够正常处理颜色逻辑，这里加上了(effectSettings?.hoveredColor ?? false)||(effectSettings?.pressedColor ?? false))
        acceptedButtons: Qt.NoButton

        // --- 悬停进入 ---
        onEntered: {
            // 编辑态：仅抑制悬停动画，不在悬停时选中（选中走点击，避免带悬停特效的元素一划过就被选中）
            if (widget.editing) return;
            animator.hoverEnter()
        }

        // --- 悬停退出 ---
        onExited: {
            if (widget.editing) return;
            animator.hoverExit()
        }
    }

    MouseArea {
        id: interactionMouseArea
        anchors.fill: parent
        z: 1000
        
        propagateComposedEvents: true
        hoverEnabled: false
        acceptedButtons: Qt.LeftButton

        onPressed: (mouse)=> {
            // TODO EXL增加点击涟漪
            if (widget !== undefined){
                if (widget.editing) {
                    mouse.accepted = false;
                    return;
                }
                // 1.1 触发涟漪（涟漪仅为视觉效果，任何异常都不得中断点击/动作触发）
                try {
                    if (widget.defaultSettings && widget.defaultSettings.rippleEffectEnabled
                            && typeof widget.triggerGlobalRipple === "function") {
                        widget.triggerGlobalRipple(interactionMouseArea, mouse.x, mouse.y);
                    }
                } catch (rippleErr) {
                    console.log("[CraftElement] ripple trigger skipped:", rippleErr);
                }
            }

            // ========== 1. 视觉反馈 ==========
            // 1.2 触发按压音效
            if (actionSource.status) {
                NVG.SystemCall.playSound(NVG.SFX.FeedbackClick)
            }
            // 1.3/1.4 按压缩放 + 旋转
            animator.clickZoomSpinPress()

            // ========== 2. 功能触发 ==========
            // 2.1 触发 Action
            if (actionSource.configuration) {
                actionSource.trigger(thiz);
            }
            // 2.2 触发启动器逻辑
            if(settings.showEXLauncher) {
                LC.LauncherCore.toggleLauncherView()
            }
            if(settings.showOriMenu) {
                LC.LauncherCore.showOriMenu()
            }
            // 2.3 点击移动逻辑
            animator.clickMove()

            // [关键] 穿透事件给 Switch
            mouse.accepted = false;
        }

        onReleased: (mouse)=> {
            if (widget.editing) {
                mouse.accepted = false;
                return;
            }
            animator.clickZoomSpinRelease()
            mouse.accepted = false;
        }
        
        NVG.ActionSource {
            id: actionSource
            configuration: settings.action
        }
    }
    //鼠标动作/数据驱动动画（已抽到 CraftAnimator.qml）
    CraftAnimator {
        id: animator
        target: craftElement
        settings: craftElement.settings
        viewExposed: craftElement.NVG.View.exposed
    }

    // --- 整体颜色渐变（机制已抽到 GradientAnimationLayer.qml）---
    GradientAnimationLayer {
        id: gradLayer
        settings: craftElement.settings
        sourceItem: craftElement
    }

    layer {
        enabled: settings.enableOverallGradientEffect ?? false
        samplerName: "maskSource" 
        effect: OpacityMask {
            anchors.fill: craftElement
            source: gradLayer.activeGradient
        }
    }

    // -- 渐变结束 --
}