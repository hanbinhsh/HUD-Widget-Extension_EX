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
    // --- 整体颜色渐变（机制已抽到 GradientAnimationLayer.qml）---
    GradientAnimationLayer {
        id: gradLayerTop
        settings: widget.defaultSettings
        sourceItem: widget
    }

    layer {
        enabled: defaultSettings.enableOverallGradientEffect ?? false
        effect: OpacityMask {
            anchors.fill: widget;
            source: gradLayerTop.activeGradient
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
            //移动/缩放/旋转/闪烁/数据驱动动画（已抽到 CraftAnimator.qml）
            CraftAnimator {
                id: animator
                target: thiz
                settings: modelData
                viewExposed: thiz.NVG.View.exposed
            }
            onEntered: {
                if (!widget.editing) itemView.currentTarget = thiz
                animator.hoverEnter()
            }
            onExited: {
                animator.hoverExit()
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
                animator.clickMove()
            }
            onPressed: {
                if (actionSource.status) NVG.SystemCall.playSound(NVG.SFX.FeedbackClick)
                animator.clickZoomSpinPress()
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
                animator.clickZoomSpinRelease()
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

                // --- 整体颜色渐变（机制已抽到 GradientAnimationLayer.qml）---
                GradientAnimationLayer {
                    id: gradLayerItem
                    settings: thiz.settings
                    sourceItem: itemContent
                }

                layer {
                    enabled: settings.enableOverallGradientEffect ?? false
                    samplerName: "maskSource" 
                    effect: OpacityMask {
                        anchors.fill: itemContent
                        source: gradLayerItem.activeGradient
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
