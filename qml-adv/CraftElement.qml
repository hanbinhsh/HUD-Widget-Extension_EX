import QtQuick 2.12
import QtQuick.Window 2.12
import QtGraphicalEffects.private 1.12
import QtGraphicalEffects 1.12 

import NERvGear 1.0 as NVG

import "utils.js" as Utils

import "Launcher" as LC

import "./Utils/ColorAnimation.js" as GradientUtils

CraftDelegate {
    id: craftElement

    readonly property string title: loader.item?.title ?? ""

    readonly property Component preference: loader.item?.preference ?? null
    readonly property NVG.SettingsMap effectSettings: settings.effect ?? null

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
            Component.onCompleted: {
                rebuildShaders();
                Qt.callLater(initCustomGradient_item)
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
    //数据移动
    NVG.DataSource {
        id: distanceDataSource
        // BUG 以下一行会导致报错107
        configuration: (settings.dataAnimation&&settings.dataAnimation_move&&settings.moveData_Distance_data) ? settings.distanceData : null
    }
    NVG.DataSource {
        id: directionDataSource
        configuration: (settings.dataAnimation&&settings.dataAnimation_move&&settings.moveData_Direction_data) ? settings.directionData : null
    }
    NVG.DataSourceRawOutput {
        id: distanceData
        source: distanceDataSource
    }
    NVG.DataSourceRawOutput {
        id: directionData
        source: directionDataSource
    }
    NumberAnimation on moveDataX {
        id: moveDataX
        running: false
        duration: settings.moveData_Duration ?? 300// 动画持续时间，单位为毫秒
        easing.type: settings.moveData_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    NumberAnimation on moveDataY {
        id: moveDataY
        running: false
        duration: settings.moveData_Duration ?? 300 // 动画持续时间，单位为毫秒
        easing.type: settings.moveData_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    Timer {
        repeat: true
        interval: settings.moveData_Trigger ?? 300
        running: Boolean(settings.dataAnimation&&settings.dataAnimation_move)&&craftElement.NVG.View.exposed
        onTriggered: {
            moveDataX.stop()
            moveDataX.to = Number(settings.moveData_Distance_data ? distanceData.result??0 : settings.moveData_Distance ?? 10) 
            * Math.cos(Number(settings.moveData_Direction_data ? directionData.result??0 : settings.moveData_Direction ?? 0) * Math.PI / 180)
            moveDataX.start()
        }
    }
    Timer {
        repeat: true
        interval: settings.moveData_Trigger ?? 300
        running: Boolean(settings.dataAnimation&&settings.dataAnimation_move)&&craftElement.NVG.View.exposed
        onTriggered: {
            moveDataY.stop()
            moveDataY.to = -Number(settings.moveData_Distance_data ? distanceData.result??0 : settings.moveData_Distance ?? 10)
            * Math.sin(Number(settings.moveData_Direction_data ? directionData.result??0 : settings.moveData_Direction ?? 0) * Math.PI / 180)
            moveDataY.start()
        }
    }
    //数据旋转
    NVG.DataSource {
        id: spinDataSource
        configuration: (settings.dataAnimation&&settings.dataAnimation_spin) ? settings.spinData : null
    }
    NVG.DataSourceRawOutput {
        id: spinData
        source: spinDataSource
    }
    NumberAnimation on spinDataA {
        id: spinDataAnimation
        running: false
        duration: settings.spinData_Duration ?? 300 // 动画持续时间，单位为毫秒
        easing.type: settings.spinData_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    Timer {
        repeat: true
        interval: settings.spinData_Trigger ?? 300
        running: Boolean(settings.dataAnimation&&settings.dataAnimation_spin)&&craftElement.NVG.View.exposed
        onTriggered: {
            spinDataAnimation.stop()
            spinDataAnimation.to = spinData.result ?? 0
            spinDataAnimation.start()
        }
    }
    //点击移动
    property bool isAnimationRunning: false // 标志变量，控制动画状态
    NumberAnimation on clickAnimationX {
        id: moveClickAnimationX
        running: false
        duration: settings.moveClick_Duration ?? 300// 动画持续时间，单位为毫秒
        easing.type: settings.moveClick_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    NumberAnimation on clickAnimationY {
        id: moveClickAnimationY
        running: false
        duration: settings.moveClick_Duration ?? 300 // 动画持续时间，单位为毫秒
        easing.type: settings.moveClick_Easing ?? 3 // 使用缓动函数使动画更平滑
    }
    Connections {
        target: moveClickAnimationX
        onStopped: {
            if(!settings.moveBackAfterClick && isAnimationRunning) {
                isAnimationRunning = false // 动画结束，重置标志
                moveClickAnimationX.stop()
                moveClickAnimationY.stop()
                moveClickAnimationX.to = 0
                moveClickAnimationY.to = 0
                moveClickAnimationX.running = true
                moveClickAnimationY.running = true
            }
            isAnimationRunning = false // 动画结束，重置标志
        }
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
        id: animationSpin_Normal
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
                animationSpin_Normal.stop()
                animationSpin_Normal.to = Number(settings.spinHover_Direction??360)
                animationSpin_Normal.running = true
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
                animationSpin_Normal.stop()
                animationSpin_Normal.to = 0
                animationSpin_Normal.running = true
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
            }
            if(settings.showEXLauncher){
                LC.LauncherCore.toggleLauncherView()
            }
            if(settings.showOriMenu){
                LC.LauncherCore.showOriMenu()
            }
            if(settings.moveOnClick && !isAnimationRunning){
                isAnimationRunning = true // 标记动画已经开始
                if(settings.moveBackAfterClick){
                    clickMoveStatus = !clickMoveStatus
                }
                moveClickAnimationX.stop()
                moveClickAnimationY.stop()
                moveClickAnimationX.to =  Number(settings.moveClick_Distance??10) * Math.cos(Number(settings.moveClick_Direction??0) * Math.PI / 180)
                moveClickAnimationY.to = -Number(settings.moveClick_Distance??10) * Math.sin(Number(settings.moveClick_Direction??0) * Math.PI / 180)
                moveClickAnimationX.running = true
                moveClickAnimationY.running = true
                if(settings.moveBackAfterClick){
                    if(!clickMoveStatus){
                        moveClickAnimationX.stop()
                        moveClickAnimationY.stop()
                        moveClickAnimationX.to = 0
                        moveClickAnimationY.to = 0
                        moveClickAnimationX.running = true
                        moveClickAnimationY.running = true
                    }
                }
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
    // --- 颜色渐变逻辑 ---
    // 1. 定义默认数据 (用于保底)
    property var defaultStops: [{ position: 0.0, color: "#a18cd1" },{ position: 0.5, color: "#fbc2eb" }]
    
    // 2. 定义安全的数据源属性
    // 如果 settings.fillStops 为空/无效，强制使用 defaultStops
    // 这样能保证 rebuildGradientStops 永远有数据可处理，不会返回空
    property var safeFillStops: (settings.fillStops && settings.fillStops.length > 0) 
                                ? settings.fillStops 
                                : defaultStops

    // 3. 核心变量
    property var innerLevelStopCache: []
    property var customGradObject_item: null
    
    // [修复] 绑定逻辑：
    // 只有当“开启了自定义”且“自定义对象已创建”时，才使用自定义对象
    // 否则回退到 simpleGrad_item
    property var currentGradient_item: (settings.useFillGradient && customGradObject_item) 
                                       ? customGradObject_item 
                                       : simpleGrad_item

    property var overallGradientAnimDurationItem: settings.overallGradientAnimDuration ?? 5000
    property real itemGradientAnimPhase: 0.0

    onOverallGradientAnimDurationItemChanged: {
        gradientAnimPhaseAnimation_item.restart();
    }

    NumberAnimation on itemGradientAnimPhase {
        id: gradientAnimPhaseAnimation_item
        running: (settings.enableOverallGradientEffect ?? false) && (settings.enableOverallGradientAnim ?? false)
        from: 0.0
        to: 1.0
        duration: overallGradientAnimDurationItem
        loops: Animation.Infinite
    }

    onItemGradientAnimPhaseChanged: {
        if (settings.useFillGradient && settings.enableOverallGradientAnim) {
            GradientUtils.updateGradientPositions(itemGradientAnimPhase, innerLevelStopCache);
        }
    }

    Connections {
        target: settings
        // 监听 safeFillStops 变化会自动涵盖 fillStops 的变化
        onUseFillGradientChanged: initCustomGradient_item()
        onEnableOverallGradientAnimChanged: initCustomGradient_item()
        onOverallGradientColor0Changed: initCustomGradient_item()
        onOverallGradientColor1Changed: initCustomGradient_item()
    }
    
    // 监听数据源变化 (比直接监听 settings.fillStops 更安全)
    onSafeFillStopsChanged: initCustomGradient_item()

    function initCustomGradient_item() {
        // A. 如果用户没开自定义颜色，直接清理并退出
        if (!settings.useFillGradient) {
            if (customGradObject_item) {
                GradientUtils.clearGradientCache(innerLevelStopCache);
                innerLevelStopCache = [];
                customGradObject_item.destroy();
                customGradObject_item = null;
            }
            return; // currentGradient_item 会自动回退到 simple
        }

        // B. 开启了自定义颜色 -> 重建对象
        
        // 1. 清理旧数据
        GradientUtils.clearGradientCache(innerLevelStopCache);
        innerLevelStopCache = [];

        if (customGradObject_item) {
            customGradObject_item.destroy();
            customGradObject_item = null;
        }

        // 2. 创建新对象 (挂载到 craftElement 以防 linearG 未就绪)
        var newGradObj = customGradComponent_item.createObject(craftElement);

        if (newGradObj) {
            // [关键修复] 构造一个临时的 settings 对象传给 JS
            // 强制使用 safeFillStops，确保一定有数据
            var tempSettings = {
                fillStops: safeFillStops, // 使用保底数据
                enableOverallGradientEffect: settings.enableOverallGradientEffect,
                enableOverallGradientAnim: settings.enableOverallGradientAnim,
                useFillGradient: true
            };

            var result = GradientUtils.rebuildGradientStops(
                tempSettings, 
                itemGradientStopComponent, 
                newGradObj
            );

            // 因为使用了 safeFillStops，result.qmlStops 几乎不可能为空
            if (result.qmlStops.length > 0) {
                newGradObj.stops = result.qmlStops;
                innerLevelStopCache = result.cache;
                
                // 赋值，触发绑定更新
                customGradObject_item = newGradObj;
            } else {
                // 极端的异常情况
                newGradObj.destroy();
                customGradObject_item = null;
            }
        }
    }

    // --- 组件定义 ---

    Gradient {
        id: simpleGrad_item
        GradientStop { 
            position: 0.0; 
            color: GradientUtils.adjustGradientColor(settings.overallGradientColor0 ?? "#a18cd1", itemGradientAnimPhase, settings) 
        }
        GradientStop { 
            position: 1.0; 
            color: GradientUtils.adjustGradientColor(settings.overallGradientColor1 ?? "#fbc2eb", itemGradientAnimPhase, settings) 
        }
    }

    Component {
        id: customGradComponent_item
        Gradient { }
    }

    Component { 
        id: itemGradientStopComponent; 
        GradientStop { } 
    }
    
    // --- 渐变组件应用 ---
    
    LinearGradient {
        id: linearG
        anchors.fill: craftElement
        visible: false
        
        // 绑定属性
        gradient: currentGradient_item
        
        start: {
            switch (settings.overallGradientDirect ?? 1) {
                case 0 : 
                case 1 : 
                case 2 : 
                case 3 : return Qt.point(0, 0); break; 
                case 5 : return Qt.point(settings.overallGradientStartX ?? 0, settings.overallGradientStartY ?? 0); break;
                default: return Qt.point(0, 0); break;
            }
            return Qt.point(0, 0);
        }
        end: {
            switch (settings.overallGradientDirect ?? 1) {
                case 0 : return Qt.point(width, 0); break; // 这里的 width 是 LinearGradient 自身的宽度
                case 1 : return Qt.point(0, height); break;
                case 2 : return Qt.point(width, height); break;
                case 5 : return Qt.point(settings.overallGradientEndX ?? 100, settings.overallGradientEndY ?? 100); break;
                default: return Qt.point(width, 0); break; 
            }
            return Qt.point(width, 0);
        }
        cached: settings.overallGradientCached ?? false
    }

    RadialGradient {
        id: radialG
        visible: false
        anchors.fill: craftElement
        gradient: currentGradient_item
        angle: settings.overallGradientAngle ?? 0
        horizontalOffset: settings.overallGradientHorizontal ?? 0
        verticalOffset: settings.overallGradientVertical ?? 0
        horizontalRadius: settings.overallGradientHorizontalRadius ?? 50
        verticalRadius: settings.overallGradientVerticalRadius ?? 50
        cached: settings.overallGradientCached ?? false
    }

    ConicalGradient {
        id: conicalG
        visible: false
        anchors.fill: craftElement
        gradient: currentGradient_item
        angle: settings.overallGradientAngle ?? 0
        horizontalOffset: settings.overallGradientHorizontal ?? 0
        verticalOffset: settings.overallGradientVertical ?? 0
        cached: settings.overallGradientCached ?? false
    }

    layer {
        enabled: settings.enableOverallGradientEffect ?? false
        samplerName: "maskSource" 
        effect: OpacityMask {
            anchors.fill: craftElement
            source: switch(settings.overallGradientDirect ?? 1){
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

    // -- 渐变结束 --
}