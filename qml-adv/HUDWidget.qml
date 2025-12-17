import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

import "Launcher" as LC

import "utils.js" as Utils

import "./Utils/ColorAnimation.js" as GradientUtils
//一级挂件属性
T.Widget {
    id: widget

    readonly property NVG.SettingsMap tempCraftSettings: NVG.Settings.createMap(widget)
    readonly property QtObject craftSettings: NVG.Settings.makeMap(settings, "craft")
    readonly property NVG.SettingsMap defaultSettings: NVG.Settings.makeMap(settings, "defaults")

    readonly property var initialEnvironment: Utils.widgetEnvironment(ctx_widget)
    readonly property var initialFont: ({ family: "Source Han Sans SC", pixelSize: 24 })
    readonly property string defaultItemInteraction: defaultSettings.interaction ?? ""

    readonly property Item interactionItem: makeInteractionItem(widget, settings, "interactionItem_NB")
    readonly property var hoverHandlers: new Map

    //挂件框上的名称&&编辑界面蓝条上的字
    title: qsTr("HUD EX")
    solid: settings.solid ?? false
    resizable: true
    editing: dialog.item?.visible ?? false

    implicitWidth: 64
    implicitHeight: 64

    // EXL动作
    action: LC.EXLActions{}
    function showEXL(){LC.LauncherCore.showLauncherView()}
    function hideEXL(){LC.LauncherCore.hideLauncherView()}
    function toggleEXL(){LC.LauncherCore.toggleLauncherView()}
    function showEXLItem(i){LC.LauncherCore.showLauncherViewItem(i)}
    function hideEXLItem(i){LC.LauncherCore.hideLauncherViewItem(i)}
    function toggleEXLItem(i){LC.LauncherCore.toggleLauncherViewItem(i)}
    // 挂件动作
    signal showHUDItem(int i)
    signal hideHUDItem(int i)
    signal toggleHUDItem(int i)
    function getHUDItemView(){return itemView.model}
    // --- 颜色渐变
    // 默认渐变
    property var defaultStops: [{ position: 0.0, color: "#a18cd1" },{ position: 0.5, color: "#fbc2eb" }]
    
    // 动画时长更新
    property var overallGradientAnimDuration: defaultSettings.overallGradientAnimDuration ?? 5000
    onOverallGradientAnimDurationChanged: {
        gradientAnimPhaseAnimation.restart();
    }

    // --- 动画驱动器 ---
    property real gradientAnimPhase: 0.0
    NumberAnimation on gradientAnimPhase {
        id: gradientAnimPhaseAnimation
        running: (defaultSettings.enableOverallGradientEffect ?? false) && (defaultSettings.enableOverallGradientAnim ?? false)
        from: 0.0
        to: 1.0
        duration: overallGradientAnimDuration
        loops: Animation.Infinite
    }

    // --- 变量定义 ---
    // 1. 缓存数组 (持有 Stop 对象的引用)
    property var topLevelStopCache: []
    // 2. 动态 Gradient 对象容器
    property var customGradObject: null
    // 3. 当前使用的 Gradient (用于绑定到 LinearGradient)
    property var currentGradient: defaultSettings.useFillGradient ? customGradObject : simpleGrad

    // --- 核心逻辑 1: 高频动画更新 ---
    // 每一帧只运行这个，不创建对象，不排序，只做加法
    onGradientAnimPhaseChanged: {
        if (defaultSettings.useFillGradient && defaultSettings.enableOverallGradientAnim) {
            GradientUtils.updateGradientPositions(gradientAnimPhase, topLevelStopCache);
        }
    }

    // --- 核心逻辑 2: 初始化/设置改变 ---
    Connections {
        target: defaultSettings
        // 任何相关设置改变，触发重建
        onFillStopsChanged: initCustomGradient()
        onUseFillGradientChanged: initCustomGradient()
        onEnableOverallGradientAnimChanged: initCustomGradient()

        onOverallGradientColor0Changed: initCustomGradient()
        onOverallGradientColor1Changed: initCustomGradient()
    }

    function initCustomGradient() {
        // 1. 清理旧数据引用
        GradientUtils.clearGradientCache(topLevelStopCache);
        topLevelStopCache = [];

        // 2. 销毁旧的 Gradient 对象 (强制刷新渲染的关键)
        if (customGradObject) {
            customGradObject.destroy();
            customGradObject = null;
        }

        // 3. 如果启用了自定义颜色，创建新对象
        if (defaultSettings.useFillGradient) {
            // 3.1 动态创建 Gradient 容器，父对象设为 linearG 以跟随生命周期
            customGradObject = customGradComponent.createObject(linearG);

            if (customGradObject) {
                // 3.2 调用 JS 生成 3 倍数量的 Stops
                var result = GradientUtils.rebuildGradientStops(
                    defaultSettings, 
                    gradientStopComponent, 
                    customGradObject // Parent
                );

                if (result.qmlStops.length > 0) {
                    customGradObject.stops = result.qmlStops;
                    topLevelStopCache = result.cache; // 保存缓存供动画使用
                } else {
                    // 出错回退
                    customGradObject.stops = defaultGradientComponent.createObject(customGradObject).stops;
                }
            }
        }
        // currentGradient 属性会自动更新，因为 customGradObject 变了
    }

    // --- 组件定义 ---

    // A. 简易模式渐变 (Simple Gradient)
    Gradient {
        id: simpleGrad
        GradientStop { 
            position: 0.0; 
            color: GradientUtils.adjustGradientColor(defaultSettings.overallGradientColor0 ?? "#a18cd1", gradientAnimPhase, defaultSettings) 
        }
        GradientStop { 
            position: 1.0; 
            color: GradientUtils.adjustGradientColor(defaultSettings.overallGradientColor1 ?? "#fbc2eb", gradientAnimPhase, defaultSettings) 
        }
    }

    // B. 高级模式渐变组件 (Component)
    Component {
        id: customGradComponent
        Gradient {
            // 空容器，Stops 由 JS 注入
        }
    }

    // C. 基础 Stop 组件 (Component)
    Component { 
        id: gradientStopComponent; 
        GradientStop { } 
    }
    
    // D. 默认 Stops 组件 (Component)
    Component {
        id: defaultGradientComponent
        Gradient {
            GradientStop { position: 0.0; color: "#a18cd1" }
            GradientStop { position: 1.0; color: "#fbc2eb" }
        }
    }

    // --- 渐变组件应用 ---
    LinearGradient {
        id: linearG
        anchors.fill: widget
        visible: false
        
        // [优化] 绑定属性，而非函数调用
        gradient: currentGradient
        
        start: {
            switch (defaultSettings.overallGradientDirect ?? 1) {
                case 0 : 
                case 1 : 
                case 2 : 
                case 3 : return Qt.point(0, 0); break; 
                case 5 : return Qt.point(defaultSettings.overallGradientStartX ?? 0, defaultSettings.overallGradientStartY ?? 0); break;
                default: return Qt.point(0, 0); break;
            }
            return Qt.point(0, 0);
        }
        end: {
            switch (defaultSettings.overallGradientDirect ?? 1) {
                case 0 : return Qt.point(widget.width, 0); break;
                case 1 : return Qt.point(0, widget.height); break;
                case 2 : return Qt.point(widget.width, widget.height); break;
                case 5 : return Qt.point(defaultSettings.overallGradientEndX ?? 100, defaultSettings.overallGradientEndY ?? 100); break;
                default: return Qt.point(widget.width, 0); break; 
            }
            return Qt.point(widget.width, 0);
        }
        cached: defaultSettings.overallGradientCached ?? false
    }

    // 3. 径向渐变
    RadialGradient {
        id: radialG
        visible: false
        anchors.fill: widget
        gradient: currentGradient
        angle: defaultSettings.overallGradientAngle ?? 0
        horizontalOffset: defaultSettings.overallGradientHorizontal ?? 0
        verticalOffset: defaultSettings.overallGradientVertical ?? 0
        horizontalRadius: defaultSettings.overallGradientHorizontalRadius ?? 50
        verticalRadius: defaultSettings.overallGradientVerticalRadius ?? 50
        cached: defaultSettings.overallGradientCached ?? false
    }

    // 4. 锥形渐变
    ConicalGradient {
        id: conicalG
        visible: false
        anchors.fill: widget
        gradient: currentGradient
        angle: defaultSettings.overallGradientAngle ?? 0
        horizontalOffset: defaultSettings.overallGradientHorizontal ?? 0
        verticalOffset: defaultSettings.overallGradientVertical ?? 0
        cached: defaultSettings.overallGradientCached ?? false
    }

    layer {
        enabled: defaultSettings.enableOverallGradientEffect ?? false
        effect: OpacityMask {
            anchors.fill: widget;
            source: switch(defaultSettings.overallGradientDirect ?? 1){
                case 0:
                case 1:
                case 2:
                case 5: return linearG;
                case 3: return radialG;
                case 4: return conicalG;
                default: return linearG;
            }
            maskSource: widget
        }
    }
    // --- 颜色渐变结束

    // --- 涟漪效果实现 ---
    Timer {
        id: burstTimer
        property real targetX: 0
        property real targetY: 0
        property int remainingCount: 0
        
        repeat: true
        // 只有当开启涟漪且剩余次数大于0时才触发
        onTriggered: {
            if (remainingCount > 0) {
                internalCreateRipple(targetX, targetY);
                remainingCount--;
            } else {
                stop();
            }
        }
    }
    // 1. 涟漪逻辑控制
    function triggerGlobalRipple(x, y) {
        // 1. 立即生成第一个涟漪
        internalCreateRipple(x, y);

        // 2. 如果开启了连发模式
        if (defaultSettings.rippleBurstMode) {
            // 配置定时器参数
            burstTimer.targetX = x;
            burstTimer.targetY = y;
            // 剩余次数 = 总次数 - 1 (因为刚刚已经生成了一个)
            burstTimer.remainingCount = (defaultSettings.rippleBurstCount ?? 3) - 1;
            burstTimer.interval = defaultSettings.rippleBurstInterval ?? 150;
            burstTimer.restart(); // 重置并启动
        }
    }

    function internalCreateRipple(x, y) {
        if (globalRippleComponent.status === Component.Ready) {
            
            // 颜色逻辑 (每次生成都重新计算，这样如果是随机颜色，连发的每一个颜色都不一样)
            var finalColor = defaultSettings.rippleColor ?? "#40FFFFFF";
            if (defaultSettings.rippleColorMode === 1) { 
                finalColor = Qt.hsla(Math.random(), 0.8, 0.6, 1.0);
            }
            
            var bezier = [
                (defaultSettings.ripple_bezierX1 ?? 25) / 100.0,
                (defaultSettings.ripple_bezierY1 ?? 10) / 100.0,
                (defaultSettings.ripple_bezierX2 ?? 25) / 100.0,
                (defaultSettings.ripple_bezierY2 ?? 100) / 100.0,
                1, 1
            ];

            // 动态创建涟漪对象
            var ripple = globalRippleComponent.createObject(rippleContainer, {
                "centerX": x, 
                "centerY": y,
                "color": finalColor,
                "maxRadius": defaultSettings.maxRadius ?? 200,
                "duration": defaultSettings.duration ?? 600,
                
                // 缓动参数
                "easingType": defaultSettings.ripple_easingType ?? 1,
                "easingAmplitude": (defaultSettings.ripple_easingAmplitude ?? 100) / 100.0,
                "easingOvershoot": (defaultSettings.ripple_easingOvershoot ?? 170) / 100.0,
                "easingPeriod": (defaultSettings.ripple_easingPeriod ?? 30) / 100.0,
                "easingBezier": bezier,

                "styleMode": defaultSettings.rippleStyle ?? 0, 
                "strokeWidth": defaultSettings.strokeWidth ?? 2,
                "shapeType": defaultSettings.rippleShape ?? 0, 
                "sides": defaultSettings.ripplePolygonSides ?? 5,
                "baseRotation": defaultSettings.rippleRotation ?? 0,
                "randomizeRotation": defaultSettings.randomizeRippleRotation ?? false,
                "rotationOffset": defaultSettings.rippleRotationSpeed ?? 0,
                "shrinkMode": defaultSettings.rippleShrinkMode ?? false,
            });
        }
    }

    // 2. 涟漪显示层
    Item {
        id: globalRippleOverlay
        anchors.fill: parent
        z: 9999 
        visible: defaultSettings.rippleEffectEnabled ?? false
        enabled: false 

        layer.enabled: defaultSettings.globalRippleMaskToContent ?? false
        layer.samplerName: "maskSource"
        layer.effect: OpacityMask {
            anchors.fill: parent
            source: rippleContainer
            maskSource: itemView 
        }

        Item {
            id: rippleContainer
            anchors.fill: parent
            clip: !(defaultSettings.globalRippleMaskToContent ?? false)
        }
    }

    // 3. 涟漪个体组件
    Component {
        id: globalRippleComponent
        Item {
            id: rippleItem
            
            // --- 基础参数 ---
            property real centerX: 0
            property real centerY: 0
            property color color: "white"
            property real maxRadius: 100
            property int duration: 600
            
            // --- 缓动参数 ---
            property int easingType: Easing.OutQuad
            property real easingAmplitude: 1.0
            property real easingOvershoot: 1.7
            property real easingPeriod: 0.3
            property var easingBezier: [0.25, 0.1, 0.25, 1.0, 1, 1]

            // --- 样式与特效 ---
            property int styleMode: 0
            property int strokeWidth: 2
            property int shapeType: 0
            property int sides: 5
            property real baseRotation: 0
            property real currentRadius: 0
            property real currentOpacity: 1.0
            property bool shrinkMode: false
            property bool randomizeRotation: false
            property real rotationOffset: 0
            property real startRotation: randomizeRotation ? Math.random() * 360 : baseRotation
            property real currentRotation: startRotation
            
            width: maxRadius * 2
            height: maxRadius * 2
            x: centerX - maxRadius
            y: centerY - maxRadius

            // --- 绘图逻辑 (Canvas) ---
            Canvas {
                id: rCanvas
                anchors.fill: parent
                renderStrategy: Canvas.Immediate
                renderTarget: Canvas.Image

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    var alpha = rippleItem.currentOpacity;
                    if (alpha <= 0.01) return;
                    
                    ctx.globalAlpha = alpha;
                    drawShape(ctx, rippleItem.currentRadius, rippleItem.color);
                    ctx.globalAlpha = 1.0;
                }

                function drawShape(ctx, r, paintColor) {
                    if (r <= 0) return;
                    ctx.beginPath();
                    if (rippleItem.shapeType === 0) {
                        ctx.arc(width/2, height/2, r, 0, 2 * Math.PI);
                    } else {
                        var cx = width / 2;
                        var cy = height / 2;
                        var sides = Math.max(3, rippleItem.sides);
                        var angleStep = (2 * Math.PI) / sides;
                        var rotRad = (rippleItem.currentRotation - 90) * Math.PI / 180;
                        for (var i = 0; i < sides; i++) {
                            var theta = i * angleStep + rotRad;
                            var px = cx + r * Math.cos(theta);
                            var py = cy + r * Math.sin(theta);
                            if (i === 0) ctx.moveTo(px, py);
                            else ctx.lineTo(px, py);
                        }
                        ctx.closePath();
                    }
                    if (rippleItem.styleMode === 0) { 
                        ctx.fillStyle = paintColor; ctx.fill(); 
                    } else { 
                        ctx.strokeStyle = paintColor; ctx.lineWidth = rippleItem.strokeWidth; ctx.stroke(); 
                    }
                }
            }

            onCurrentRadiusChanged: rCanvas.requestPaint()
            onCurrentOpacityChanged: rCanvas.requestPaint()

            // --- 动画逻辑 ---
            
            // 1. 在组件创建完成时，动态配置动画参数并启动
            Component.onCompleted: {
                // 配置半径动画的缓动参数
                setupEasing(radiusAnim);
                // 启动动画
                anim.start();
            }

            // 辅助函数：只设置需要的参数
            function setupEasing(animation) {
                animation.easing.type = rippleItem.easingType;

                // 贝塞尔曲线 (Type 41)
                if (rippleItem.easingType === Easing.BezierSpline) {
                    animation.easing.bezierCurve = rippleItem.easingBezier;
                } 
                // Elastic (29-32) & Bounce (37-40) -> 需要 Amplitude
                else if ((rippleItem.easingType >= 29 && rippleItem.easingType <= 32) || 
                         (rippleItem.easingType >= 37 && rippleItem.easingType <= 40)) {
                    animation.easing.amplitude = rippleItem.easingAmplitude;
                    // Elastic 还需要 Period
                    if (rippleItem.easingType <= 32) {
                        animation.easing.period = rippleItem.easingPeriod;
                    }
                }
                // Back (33-36) -> 需要 Overshoot
                else if (rippleItem.easingType >= 33 && rippleItem.easingType <= 36) {
                    animation.easing.overshoot = rippleItem.easingOvershoot;
                }
            }

            ParallelAnimation {
                id: anim
                running: false // [修改] 默认为 false，由 onCompleted 启动
                onFinished: rippleItem.destroy()

                NumberAnimation { 
                    id: radiusAnim
                    target: rippleItem
                    property: "currentRadius"
                    from: rippleItem.shrinkMode ? rippleItem.maxRadius : 0
                    to:   rippleItem.shrinkMode ? 0 : rippleItem.maxRadius
                    duration: rippleItem.duration
                }

                NumberAnimation { 
                    target: rippleItem
                    property: "currentOpacity"
                    from: rippleItem.shrinkMode ? 0.0 : 1.0
                    to:   rippleItem.shrinkMode ? 1.0 : 0.0
                    duration: rippleItem.duration
                    easing.type: rippleItem.shrinkMode ? Easing.InQuad : Easing.OutQuad 
                }

                NumberAnimation {
                    target: rippleItem
                    property: "currentRotation"
                    from: rippleItem.startRotation
                    to:   rippleItem.startRotation + rippleItem.rotationOffset
                    duration: rippleItem.duration
                }
            }
        }
    }
    // --- 涟漪效果结束

    //菜单中的编辑模式
    menu: Menu {
        Action {
            text: qsTr("Editing Mode...")
            onTriggered: dialog.active = true
        }
        Action {
            text: qsTr("Save shot to Sao root")
            onTriggered: {
                widget.grabToImage(function(result) {
                    result.saveToFile("../Widget.png");
                });
                NVG.SystemCall.messageBox({
                    title: "Success",
                    modal: true,
                    text: qsTr("Save success.")
                });
            }
        }
        Action {
            text: qsTr("Open EX Launcher")
            onTriggered: {
                LC.LauncherCore.toggleLauncherView()
            }
        }
        Action {
            text: qsTr("EX Launcher Setting")
            onTriggered: {
                LC.LauncherCore.toggleLauncherSetting()
            }
        }
    }

    Connections {
        enabled: true
        target: LC.LauncherCore
    }

    Component.onCompleted: { // upgrade settings
        initCustomGradient()
        if (settings.font !== undefined) {
            defaultSettings.font = settings.font;
            settings.font = undefined;
        }
        if (settings.background !== undefined) {
            defaultSettings.background = settings.background;
            settings.background = undefined;
        }
        if (settings.foreground !== undefined) {
            defaultSettings.foreground = settings.foreground;
            settings.foreground = undefined;
        }
        if (settings.base !== undefined) {
            defaultSettings.base = settings.base;
            settings.base = undefined;
        }
    }

    function makeInteractionItem(parent, settings, key) {
        let c = null;
        let o = null;
        const url = Utils.resolveInteraction(settings.interaction);
        if (url) {
            c = Qt.createComponent(url);
            if (c.status !== Component.Ready) {
                if (c.status === Component.Error)
                    console.warn(c.errorString());
                c = null;
            }
        }
        if (parent[key]) {
            parent[key].destroy();
            delete parent[key];
        }
        if (c) {
            o = c.createObject(parent, {
                settings: NVG.Settings.makeMap(settings, "reaction")
            });
            Object.defineProperty(parent, key, { value: o, configurable: true });
            c.destroy();
        }
        return o;
    }

    QtObject { // Public API
        id: ctx_widget

        readonly property font defaultFont: Qt.font(defaultSettings.font ?? initialFont)

        readonly property var defaultBackground: defaultSettings.background
        readonly property color defaultBackgroundColor: defaultSettings.base ?? "transparent"

        readonly property color defaultTextColor: defaultSettings.foreground ?? "#BBFFFFFF"
        readonly property color defaultStyleColor: "#33FFFFFF"

        readonly property bool exposed: widget.NVG.View.exposed
        readonly property bool editing: widget.editing
    }

    Component {
        id: cDataSource
        NVG.DataSource {}
    }

    Component {
        id: cDataRawOutput
        NVG.DataSourceRawOutput {
            source: NVG.DataSource {}
        }
    }

    Component { // any items with settings property
        id: cScaleTransform
        ConfigurableScale { config: item.settings.scale ?? {} }
    }

    Component { // any items with settings property
        id: cRotateTransform
        ConfigurableRotation { config: item.settings.rotate ?? {} }
    }

    MouseArea {
        anchors.fill: parent

        visible: widget.editing
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: itemView.currentTarget = null
    }

    CraftView {
        id: itemView
        anchors.fill: parent

        // for transform components
        readonly property NVG.SettingsMap settings: widget.settings
        readonly property bool rotateEnabled: Boolean(widget.settings.rotate)

        transform: {
            const initProp = { item: itemView };
            const rotate = Utils.makeObject(this, rotateEnabled, cRotateTransform, initProp, "rotateTransform_NB");
            return [rotate].concat(widget.interactionItem?.extraTransform);
        }

        parent: widget.interactionItem?.contentParent ?? widget
        interactive: widget.editing
        gridSize: widget.craftSettings.grid ?? 10
        gridSnap: widget.craftSettings.snap ?? true
        model: NVG.Settings.makeList(widget.settings, "items")
        delegate: CraftDelegate {
            id: thiz
            readonly property NVG.DataSource dataSource: dataSource
            property bool targetVisible: true
            property bool widgetVisibilityAction: modelData.visibility == "action" ? 1 : 0
            property bool animationVisible: true
            view: itemView
            environment: Utils.itemEnvironment(thiz, initialEnvironment)
            settings: modelData
            index: model.index
            visible: widget.editing || targetVisible
            //挂件默认大小
            implicitWidth: Math.max(bgSource.implicitWidth, 16)
            implicitHeight: Math.max(bgSource.implicitHeight, 16)

            //编辑可见性界面
            // TODO 尝试通过数据更改某些物品的颜色或者渐变？？？
            hidden: {
                if(widgetVisibilityAction ?? false){
                    return true
                }
                if(settings.onlyDisplayOnEXLauncher&&!LC.LauncherCore.vis){
                    return true
                }
                switch (modelData.visibility) {
                    case "hide": return true;
                    case "normal": return widget.NVG.View.hovered;
                    case "hovered": return !widget.NVG.View.hovered;
                    case "data": return !Boolean(dataOutput.result);
                    case "data&normal": return !Boolean(dataOutput.result) || widget.NVG.View.hovered;//新增
                    case "data&hovered": return !Boolean(dataOutput.result) || !widget.NVG.View.hovered;//新增
                    default: break;
                }
                return false;
            }
            //自定义动作控制显示
            Connections {
                enabled: true
                target: widget
                onShowHUDItem: {if(i === index){hideItem()}}
                onHideHUDItem: {if(i === index){showItem()}}
                onToggleHUDItem: {if(i === index){toggleItem()}}
            }
            function toggleItem() { widgetVisibilityAction ? hideItem() : showItem() }
            function showItem(){
                widgetVisibilityAction = true
            }
            function hideItem(){
                widgetVisibilityAction = false
            }

            defaultText: modelData.label ?? ""
            defaultData: dataSource

            interactionSource: modelData.interaction ?? defaultItemInteraction
            interactionSettingsBase: modelData.interaction ? modelData : widget.defaultSettings

            // FIXME 将此处改为settings.onlyDisplayOnEXLauncher，才不会遮挡？
            hoverEnabled: true//Boolean(settings.moveOnHover||settings.zoomOnHover||settings.spinOnHover||settings.glimmerOnHover)
            //控制挂件是否显示
            // TODO 显示时的动画效果
            // TODO 外层挂件的悬浮动作
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
                configuration: (modelData.dataAnimation&&modelData.dataAnimation_move&&modelData.moveData_Distance_data) ? modelData.distanceData : null
            }
            NVG.DataSource {
                id: directionDataSource
                configuration: (modelData.dataAnimation&&modelData.dataAnimation_move&&modelData.moveData_Direction_data) ? modelData.directionData : null
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
                duration: modelData.moveData_Duration ?? 300// 动画持续时间，单位为毫秒
                easing.type: modelData.moveData_Easing ?? 3 // 使用缓动函数使动画更平滑
            }
            NumberAnimation on moveDataY {
                id: moveDataY
                running: false
                duration: modelData.moveData_Duration ?? 300 // 动画持续时间，单位为毫秒
                easing.type: modelData.moveData_Easing ?? 3 // 使用缓动函数使动画更平滑
            }
            Timer {
                repeat: true
                interval: modelData.moveData_Trigger ?? 300
                running: Boolean(modelData.dataAnimation&&modelData.dataAnimation_move)&&thiz.NVG.View.exposed
                onTriggered: {
                    moveDataX.stop()
                    moveDataX.to = Number(modelData.moveData_Distance_data ? distanceData.result??0 : modelData.moveData_Distance ?? 10) 
                    * Math.cos(Number(modelData.moveData_Direction_data ? directionData.result??0 : modelData.moveData_Direction ?? 0) * Math.PI / 180)
                    moveDataX.start()
                }
            }
            Timer {
                repeat: true
                interval: modelData.moveData_Trigger ?? 300
                running: Boolean(modelData.dataAnimation&&modelData.dataAnimation_move)&&thiz.NVG.View.exposed
                onTriggered: {
                    moveDataY.stop()
                    moveDataY.to = -Number(modelData.moveData_Distance_data ? distanceData.result??0 : modelData.moveData_Distance ?? 10)
                    * Math.sin(Number(modelData.moveData_Direction_data ? directionData.result??0 : modelData.moveData_Direction ?? 0) * Math.PI / 180)
                    moveDataY.start()
                }
            }
            //数据旋转
            NVG.DataSource {
                id: spinDataSource
                configuration: (modelData.dataAnimation&&modelData.dataAnimation_spin) ? modelData.spinData : null
            }
            NVG.DataSourceRawOutput {
                id: spinData
                source: spinDataSource
            }
            NumberAnimation on spinDataA {
                id: spinDataAnimation
                running: false
                duration: modelData.spinData_Duration ?? 300 // 动画持续时间，单位为毫秒
                easing.type: modelData.spinData_Easing ?? 3 // 使用缓动函数使动画更平滑
            }
            Timer {
                repeat: true
                interval: modelData.spinData_Trigger ?? 300
                running: Boolean(modelData.dataAnimation&&modelData.dataAnimation_spin)&&thiz.NVG.View.exposed
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
                    target: thiz
                    property: "opacity"
                    from: 1
                    to: (settings.glimmerHover_MinOpacity ?? 0)/100
                    duration: settings.glimmerHover_Duration ?? 300
                    easing.type: settings.glimmerHover_Easing ?? 3
                }   
                NumberAnimation{
                    target: thiz
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
                target: thiz
                property: "opacity"
                from: thiz.opacity
                to: 1
                duration: 100 // 动画持续时间，单位为毫秒
                easing.type: settings.glimmerHover_Easing ?? 3 // 使用缓动函数使动画更平滑
            }
            onEntered: {
                if (!widget.editing) itemView.currentTarget = thiz
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
                if (!widget.editing) {// TODO 2级界面加入此行
                    if (actionSource.configuration)
                        actionSource.trigger(thiz);
                    if(settings.showEXLauncher)
                        LC.LauncherCore.toggleLauncherView()
                    if(settings.showOriMenu)
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
                if (actionSource.status) NVG.SystemCall.playSound(NVG.SFX.FeedbackClick)
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
                if (widget.defaultSettings.rippleEffectEnabled) {
                    var enableGlobal = widget.defaultSettings.rippleEffectEnabled;
                    if (enableGlobal) {
                        if (widget) {
                            var mappedPos = thiz.mapToItem(widget, mouse.x, mouse.y);
                            widget.triggerGlobalRipple(mappedPos.x, mappedPos.y);
                        } else {
                            console.error("[Child] Error: 'widget' (root id) is not accessible or null!");
                        }
                    }
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
            NVG.DataSource {
                id: dataSource
                configuration: modelData.data
            }
            NVG.DataSourceRawOutput {//加了||"data&hovered"
                id: dataOutput
                source: modelData.visibility === "data"||"data&hovered"||"data&normal" ? dataSource : null
            }
            NVG.ActionSource {
                id: actionSource
                text: modelData.label || this.title
                configuration: modelData.action
            }
            // 外层挂件独有
            NumberAnimation on showAnimationX {
                id: showMoveAnimationX
                running: false
                duration: settings.showAnimation_Duration ?? 300// 动画持续时间，单位为毫秒
                easing.type: settings.showAnimation_Easing ?? 3 // 使用缓动函数使动画更平滑
            }
            NumberAnimation on showAnimationY {
                id: showMoveAnimationY
                running: false
                duration: settings.showAnimation_Duration ?? 300 // 动画持续时间，单位为毫秒
                easing.type: settings.showAnimation_Easing ?? 3 // 使用缓动函数使动画更平滑
            }
            //消逝动画
            property bool opciMaskForward: false
            NumberAnimation on staOpciMask {
                running: false
                id: opciMask_sta
                from: opciMaskForward ? settings.fadeTransition_sta_end ?? 0 : settings.fadeTransition_sta_start ?? 0
                to: opciMaskForward ? settings.fadeTransition_sta_start ?? 0 : settings.fadeTransition_sta_end ?? 0
                duration: settings.showAnimation_sta_Duration ?? 250
            }
            NumberAnimation on endOpciMask {
                id: opciMask_end
                running: false
                from: opciMaskForward ? settings.fadeTransition_end_end ?? 0 : settings.fadeTransition_end_start ?? 1500
                to: opciMaskForward ? settings.fadeTransition_end_start ?? 1500 : settings.fadeTransition_end_end ?? 0
                duration: settings.showAnimation_end_Duration ?? 250
            }
            NumberAnimation on endOpci {
                id: opciMaskAnimation_End
                running: false
                from: opciMaskForward ? 0 : 100
                to: opciMaskForward ? 100 : 0
                duration: settings.showAnimation_fade_Duration ?? 100
            }
            Item {
                id: itemContent
                anchors.fill: parent
                parent: thiz.interactionItem?.contentParent ?? thiz

                Item {
                    id: fadeMask
                    visible: settings.usedisplayMask ?? true
                    opacity: (settings.maskOpacity ?? 100)/100
                    Image { 
                        rotation: settings.maskRotation ?? 0
                        id: fadeImage; 
                        source: settings.usedisplayMask ? (settings.displayMaskSource ?? "") : ""
                        height: settings.displayMaskTranslateScaleHeight ?? 54
                        width: settings.displayMaskTranslateScaleWidth ?? 54
                        x: settings.displayMaskTranslateX ?? 0
                        y: settings.displayMaskTranslateY ?? 0
                        fillMode: settings.displayMaskFill ?? 1
                    }
                }

                state: thiz.hidden ? "HIDE" : "SHOW"
                states: [
                    State {
                        name: "SHOW"
                        PropertyChanges{ target: itemContent; opacity: 1.0 }
                        PropertyChanges{ target: fadeImage; opacity: (settings.maskOpacity ?? 100)/100; }
                        PropertyChanges{ target: thiz; targetVisible: true }
                    },
                    State {
                        name: "HIDE"
                        PropertyChanges{ target: itemContent; opacity: 0.0 }
                        PropertyChanges{ target: fadeImage; opacity: 0.0; }
                        PropertyChanges{ target: thiz; targetVisible: false }
                    }
                ]
                transitions: [
                    Transition {
                        from: "SHOW"
                        to: "HIDE"
                        SequentialAnimation{
                            ScriptAction {script: {thiz.playingFadeAnimation = true}}
                            PauseAnimation { duration: settings.hidePauseTime ?? 0 }
                            NumberAnimation {
                                target: fadeImage
                                property: "opacity"
                                duration: (settings.usedisplayMask ?? false)&&(settings.maskVisibleAfterAnimation ?? true) ? (settings.hideMaskTime ?? 250) : 0
                            }
                            ScriptAction {
                                script: {
                                    opciMaskAnimation_End.stop()
                                    opciMaskForward = false;
                                    opciMaskAnimation_End.start()
                                }
                            }
                            PauseAnimation { duration: settings.enableFadeTransition ? settings.showAnimation_Duration ?? 100 : 0 }
                            ParallelAnimation{
                                ScriptAction {
                                    script: {
                                        opciMask_sta.stop()
                                        opciMaskForward = false;
                                        opciMask_sta.start()
                                    }
                                }
                                ScriptAction {
                                    script: {
                                        opciMask_end.stop()
                                        opciMaskForward = false;
                                        opciMask_end.start()
                                    }
                                }
                                ScriptAction {
                                    script: {
                                        if(settings.enableShowAnimation){
                                            showMoveAnimationX.stop();
                                            showMoveAnimationY.stop();
                                            showMoveAnimationX.to = Number(settings.showAnimation_Distance ?? 10) * Math.cos(Number(settings.showAnimation_Direction ?? 0) * Math.PI / 180);
                                            showMoveAnimationY.to = -Number(settings.showAnimation_Distance ?? 10) * Math.sin(Number(settings.showAnimation_Direction ?? 0) * Math.PI / 180);
                                            showMoveAnimationX.running = true;
                                            showMoveAnimationY.running = true;
                                        }
                                    }
                                }
                                NumberAnimation { target: itemContent; property: "opacity"; duration: settings.hideTime ?? 250 }
                            }
                            PropertyAnimation { target: thiz; property: "targetVisible"; duration: 0 }
                            ScriptAction {script: {thiz.playingFadeAnimation = false}}
                        }
                    },
                    Transition {
                        from: "HIDE"
                        to: "SHOW"
                        SequentialAnimation{
                            ScriptAction {script: {thiz.playingFadeAnimation = true}}
                            PauseAnimation { duration: settings.showPauseTime ?? 0 }
                            PropertyAnimation { target: fadeImage; property: "visible"; duration: 0; to: settings.usedisplayMask }
                            PropertyAnimation { target: thiz; property: "targetVisible"; duration: 0 }
                            ParallelAnimation{
                                ScriptAction {
                                    script: {
                                        opciMask_sta.stop()
                                        opciMaskForward = true;
                                        opciMask_sta.start()
                                    }
                                }
                                ScriptAction {
                                    script: {
                                        opciMask_end.stop()
                                        opciMaskForward = true;
                                        opciMask_end.start()
                                    }
                                }
                                ScriptAction {
                                    script: {
                                        if(settings.enableShowAnimation){
                                            showMoveAnimationX.stop();
                                            showMoveAnimationY.stop();
                                            showMoveAnimationX.to = 0;
                                            showMoveAnimationY.to = 0;
                                            showMoveAnimationX.running = true;
                                            showMoveAnimationY.running = true;
                                        }
                                    }
                                }
                                NumberAnimation { target: itemContent; property: "opacity"; duration: settings.displayTime ?? 250 }
                            }
                            ScriptAction {
                                script: {
                                    opciMaskAnimation_End.stop()
                                    opciMaskForward = true;
                                    opciMaskAnimation_End.start()
                                }
                            }
                            ScriptAction {script: {thiz.playingFadeAnimation = false}}
                            NumberAnimation { target: fadeImage; property: "opacity"; duration: settings.displayMaskTime ?? 250 }
                            NumberAnimation { 
                                target: fadeImage;
                                property: "opacity";
                                duration: (settings.maskVisibleAfterAnimation??true) ? 0 : (settings.displayMaskTime ?? 250);
                                to: (settings.maskVisibleAfterAnimation??true) ? (settings.maskOpacity ?? 100)/100 : 0;
                            }
                            PropertyAnimation { 
                                target: fadeImage
                                property: "visible"
                                duration: 0
                                to: (settings.maskVisibleAfterAnimation??true)&&settings.usedisplayMask
                            }
                        }
                    }
                ]

                ColorBackgroundSource {
                   id: bgSource
                   anchors.fill: parent

                   parent: (modelData.separate ?? widget.defaultSettings.separate) ? thiz : itemContent
                   opacity: parent === itemContent ? 1 : itemContent.opacity
                    z: -99.5 // NOTE: element.z < 99 will be placed behind background
                   //挂件的背景颜色
                   color: modelData.color ?? ctx_widget.defaultBackgroundColor
                   configuration: modelData.background ?? ctx_widget.defaultBackground
                   hovered: thiz.containsMouse
                   pressed: thiz.pressed
                   //挂件的默认背景
                   defaultBackground {
                       normal: Utils.NormalBackground
                       hovered: Utils.HoveredBackground
                       pressed: Utils.PressedBackground
                   }
                }

                // --- 颜色渐变逻辑 ---
                property var defaultStops: [{ position: 0.0, color: "#a18cd1" },{ position: 0.5, color: "#fbc2eb" }]
                property var innerLevelStopCache: []
                property var customGradObject_item: null
                property var currentGradient_item: settings.useFillGradient ? customGradObject_item : simpleGrad_item

                property var overallGradientAnimDurationItem: settings.overallGradientAnimDuration ?? 5000
                property real itemGradientAnimPhase: 0.0

                onOverallGradientAnimDurationItemChanged: {
                    gradientAnimPhaseAnimation_item.restart();
                }

                // 动画驱动器
                NumberAnimation on itemGradientAnimPhase {
                    id: gradientAnimPhaseAnimation_item
                    running: (settings.enableOverallGradientEffect ?? false) && (settings.enableOverallGradientAnim ?? false)
                    from: 0.0
                    to: 1.0
                    duration: itemContent.overallGradientAnimDurationItem
                    loops: Animation.Infinite
                }

                onItemGradientAnimPhaseChanged: {
                    if (settings.useFillGradient && settings.enableOverallGradientAnim) {
                        // 将本地缓存 innerLevelStopCache 传给 JS
                        GradientUtils.updateGradientPositions(itemContent.itemGradientAnimPhase, itemContent.innerLevelStopCache);
                    }
                }

                Connections {
                    target: settings
                    onFillStopsChanged: itemContent.initCustomGradient_item()
                    onUseFillGradientChanged: itemContent.initCustomGradient_item()
                    onEnableOverallGradientAnimChanged: itemContent.initCustomGradient_item()

                    onOverallGradientColor0Changed: itemContent.initCustomGradient_item()
                    onOverallGradientColor1Changed: itemContent.initCustomGradient_item()
                }

                Component.onCompleted: itemContent.initCustomGradient_item()

                function initCustomGradient_item() {
                    // console.log("Initializing custom gradient for item at index" + settings.fillStops);
                    // 1. 清理旧数据引用
                    GradientUtils.clearGradientCache(itemContent.innerLevelStopCache);
                    itemContent.innerLevelStopCache = [];

                    // 2. 销毁旧的 Gradient 对象 (强制刷新渲染)
                    if (itemContent.customGradObject_item) {
                        itemContent.customGradObject_item.destroy();
                        itemContent.customGradObject_item = null;
                    }

                    // 3. 如果需要使用自定义渐变，则创建新的对象
                    if (settings.useFillGradient) {
                        // 3.1 动态创建 Gradient 容器，父对象设为 linearG (或其他存在的对象)
                        itemContent.customGradObject_item = customGradComponent_item.createObject(linearG);

                        if (itemContent.customGradObject_item) {
                            // 3.2 调用 JS 生成 Stops
                            var result = GradientUtils.rebuildGradientStops(
                                settings, 
                                itemGradientStopComponent, 
                                itemContent.customGradObject_item // Parent
                            );

                            if (result.qmlStops.length > 0) {
                                itemContent.customGradObject_item.stops = result.qmlStops;
                                itemContent.innerLevelStopCache = result.cache; // 保存到本地缓存
                            } else {
                                // 回退
                                itemContent.customGradObject_item.stops = defaultGradientComponent_item.createObject(itemContent.customGradObject_item).stops;
                            }
                        }
                    }
                }

                // --- 组件定义 ---

                // A. 简易模式渐变
                Gradient {
                    id: simpleGrad_item
                    GradientStop { 
                        position: 0.0; 
                        color: GradientUtils.adjustGradientColor(settings.overallGradientColor0 ?? "#a18cd1", itemContent.itemGradientAnimPhase, settings) 
                    }
                    GradientStop { 
                        position: 1.0; 
                        color: GradientUtils.adjustGradientColor(settings.overallGradientColor1 ?? "#fbc2eb", itemContent.itemGradientAnimPhase, settings) 
                    }
                }

                // B. 高级模式渐变组件 (Component)
                Component {
                    id: customGradComponent_item
                    Gradient { }
                }

                // C. 基础 Stop 组件
                Component { 
                    id: itemGradientStopComponent; 
                    GradientStop { } 
                }
                
                // D. 默认 Stops 组件
                Component {
                    id: defaultGradientComponent_item
                    Gradient {
                        GradientStop { position: 0.0; color: "#a18cd1" }
                        GradientStop { position: 1.0; color: "#fbc2eb" }
                    }
                }

                // --- 渐变组件应用 ---
                
                LinearGradient {
                    id: linearG
                    anchors.fill: itemContent
                    visible: false
                    // [优化] 绑定属性
                    gradient: itemContent.currentGradient_item
                    
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
                            case 0 : return Qt.point(itemContent.width, 0); break;
                            case 1 : return Qt.point(0, itemContent.height); break;
                            case 2 : return Qt.point(itemContent.width, itemContent.height); break;
                            case 5 : return Qt.point(settings.overallGradientEndX ?? 100, settings.overallGradientEndY ?? 100); break;
                            default: return Qt.point(itemContent.width, 0); break; 
                        }
                        return Qt.point(itemContent.width, 0);
                    }
                    cached: settings.overallGradientCached ?? false
                }

                RadialGradient {
                    id: radialG
                    visible: false
                    anchors.fill: itemContent
                    gradient: itemContent.currentGradient_item
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
                    anchors.fill: itemContent
                    gradient: itemContent.currentGradient_item
                    angle: settings.overallGradientAngle ?? 0
                    horizontalOffset: settings.overallGradientHorizontal ?? 0
                    verticalOffset: settings.overallGradientVertical ?? 0
                    cached: settings.overallGradientCached ?? false
                }

                layer {
                    enabled: settings.enableOverallGradientEffect ?? false
                    samplerName: "maskSource" 
                    effect: OpacityMask {
                        anchors.fill: itemContent
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

                Repeater {
                    model: NVG.Settings.makeList(modelData, "elements")
                    delegate: CraftElement {
                        itemSettings: thiz.settings
                        itemData: dataSource
                        defaultData: dataSource
                        defaultText: thiz.defaultText
                        superArea: thiz
                        itemBackground: bgSource
                        interactionArea: interactionIndependent ? this : thiz // override
                        interactionState: thiz.interactionState // override
                        interactionSource: modelData.interaction ?? ""
                        interactionSettingsBase: modelData
                        environment: Utils.elementEnvironment(this, thiz.environment)
                        settings: modelData
                        index: model.index
                    }
                }
            }
        }

        onDeselectRequest: currentTarget = null
        onDeleteRequest: dialog.item?.requestDeleteItem()

        onModelChanged: {
            // add default item
            if (model.count < 1) {
                const itemSettings = NVG.Settings.createMap(model);
                const elements = NVG.Settings.makeList(itemSettings, "elements");
                const elemSettings = NVG.Settings.createMap(elements);
                elemSettings.content = "icon";
                elements.append(elemSettings);

                model.append(itemSettings);
            }
        }
    }

    Loader {
        id: dialog
        active: false
        sourceComponent: EditDialog {
            onClosing: dialog.active = false
        }
    }
}
