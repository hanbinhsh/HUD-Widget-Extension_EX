import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

import "Launcher" as LC
import "elements"

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

    // widget 层高级特效（独立于整体渐变/涟漪，键写入 defaultSettings.advancedEffect）
    readonly property NVG.SettingsMap advancedEffectSettings: defaultSettings.advancedEffect ?? null
    readonly property bool advancedEffectEnabled: Boolean(advancedEffectSettings?.enabled)

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

    // --- 涟漪效果（已抽到 GlobalRippleController.qml，与 EX 启动器共用）---
    GlobalRippleController {
        id: globalRipple
        settings: widget.defaultSettings
        maskItem: itemView
    }
    function triggerGlobalRipple(srcItem, x, y) { globalRipple.triggerFromItem(srcItem, x, y) }

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
            // 物品层高级特效（独立于基础设置，键写入 modelData.advancedEffect）
            readonly property NVG.SettingsMap advancedEffectSettings: settings.advancedEffect ?? null
            readonly property bool advancedEffectEnabled: Boolean(advancedEffectSettings?.enabled)
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
                // 涟漪仅为视觉效果，任何异常都不得中断点击/动作触发
                try {
                    if (widget.defaultSettings && widget.defaultSettings.rippleEffectEnabled
                            && typeof widget.triggerGlobalRipple === "function") {
                        widget.triggerGlobalRipple(thiz, mouse.x, mouse.y);
                    }
                } catch (rippleErr) {
                    console.log("[HUDWidget] ripple trigger skipped:", rippleErr);
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
            // 物品层高级特效叠加（完整特效集，复用 ImageEffectStack；镜像 CraftElement 的实现）
            // 把物品内容(itemContent)捕获为纹理，叠加完整特效；仅在 advancedEffect.enabled 时实例化/渲染
            ShaderEffectSource {
                id: itemAdvFxSource
                anchors.fill: parent
                sourceItem: itemContent
                live: thiz.advancedEffectEnabled
                hideSource: false
                visible: false
            }
            Loader {
                id: itemAdvFxLoader
                anchors.fill: itemAdvFxSource
                active: thiz.advancedEffectEnabled && Boolean(thiz.advancedEffectSettings)
                sourceComponent: Item {
                    anchors.fill: parent
                    ColorCycleGradient {
                        id: itemAdvColorCycle
                        settings: thiz.advancedEffectSettings
                        viewExposed: thiz.NVG.View.exposed
                    }
                    ImageEffectStack {
                        sourceItem: itemAdvFxSource
                        settings: thiz.advancedEffectSettings
                        dataSource: thiz.dataSource
                        itemPressed: thiz.pressed
                        itemHovered: thiz.containsMouse
                        gradient: itemAdvColorCycle.gradient
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

    // widget 层高级特效叠加（完整特效集，复用 ImageEffectStack；镜像 CraftElement/物品层）
    // 捕获整个 itemView（所有物品）为纹理，叠加完整特效；仅在 advancedEffect.enabled 时实例化/渲染
    ShaderEffectSource {
        id: widgetAdvFxSource
        anchors.fill: parent
        sourceItem: itemView
        live: widget.advancedEffectEnabled
        hideSource: false
        visible: false
    }
    Loader {
        id: widgetAdvFxLoader
        anchors.fill: widgetAdvFxSource
        active: widget.advancedEffectEnabled && Boolean(widget.advancedEffectSettings)
        sourceComponent: Item {
            anchors.fill: parent
            ColorCycleGradient {
                id: widgetAdvColorCycle
                settings: widget.advancedEffectSettings
                viewExposed: widget.NVG.View.exposed
            }
            ImageEffectStack {
                sourceItem: widgetAdvFxSource
                settings: widget.advancedEffectSettings
                itemHovered: widget.NVG.View.hovered
                gradient: widgetAdvColorCycle.gradient
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
