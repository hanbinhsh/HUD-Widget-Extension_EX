import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

import "Launcher" as LC

import "utils.js" as Utils
//一级挂件属性
T.Widget {
    id: widget

    readonly property QtObject craftSettings: NVG.Settings.makeMap(settings, "craft")
    readonly property NVG.SettingsMap defaultSettings: NVG.Settings.makeMap(settings, "defaults")

    readonly property var initialFont: ({ family: "Source Han Sans SC", pixelSize: 24 })
    readonly property string defaultItemInteraction: defaultSettings.interaction ?? ""

    readonly property Item interactionItem: makeInteractionItem(widget, settings, "interactionItem_NB")

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
    // 颜色渐变
    property var defaultStops: [{ position: 0.0, color: "#a18cd1" },{ position: 1.0, color: "#fbc2eb" }]
    Gradient {
        id: grad
        GradientStop { position: 0.0; color: defaultSettings.overallGradientColor0 ?? "#a18cd1" }
        GradientStop { position: 1.0; color: defaultSettings.overallGradientColor1 ?? "#fbc2eb" }
    }
    // 渐变组件生成
    function makeGradient(stopdefs) {
        if(Array.isArray(stopdefs))
            return gradientComponent.createObject(null, {stopdefs});
        return makeGradient(defaultStops)
    }
    Component {
        id: gradientComponent
        Gradient {
            property var stopdefs
            stops: stopdefs.map( d => gradientStopComponent.createObject(null, d) );
        }
    }
    Component { id: gradientStopComponent; GradientStop { } }
    // 渐变组件生成完成
    LinearGradient {
        id: linearG
        anchors.fill: widget
        visible: false
        gradient: {
            if (!defaultSettings.useFillGradient){
                return grad;
            }else{
                return makeGradient(defaultSettings.fillStops);
            }
        }
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
                case 0 : return Qt.point(widget.width, 0); break;//1.横向渐变
                case 1 : return Qt.point(0, widget.height); break;//2.竖向渐变
                case 2 : return Qt.point(widget.width, widget.height); break;//3.斜向渐变
                case 5 : return Qt.point(defaultSettings.overallGradientEndX ?? 100, defaultSettings.overallGradientEndY ?? 100); break;
                default: return Qt.point(widget.width, 0); break; 
            }
            return Qt.point(widget.width, 0);
        }
        cached: defaultSettings.overallGradientCached ?? false
    }
    // 3
    RadialGradient {
        id: radialG
        visible: false
        anchors.fill: widget
        gradient: {
            if (!defaultSettings.useFillGradient){
                return grad;
            }else{
                return makeGradient(defaultSettings.fillStops);
            }
        }
        angle: defaultSettings.overallGradientAngle ?? 0
        horizontalOffset: defaultSettings.overallGradientHorizontal ?? 0
        verticalOffset: defaultSettings.overallGradientVertical ?? 0
        horizontalRadius: defaultSettings.overallGradientHorizontalRadius ?? 50
        verticalRadius: defaultSettings.overallGradientVerticalRadius ?? 50
        cached: defaultSettings.overallGradientCached ?? false
    }
    // 4
    ConicalGradient {
        id: conicalG
        visible: false
        anchors.fill: widget
        gradient: {
            if (!defaultSettings.useFillGradient){
                return grad;
            }else{
                return makeGradient(defaultSettings.fillStops);
            }
        }
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
    // 颜色渐变结束

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
            view: itemView
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
                    case "data&hovered": return !Boolean(dataOutput.result)&&widget.NVG.View.hovered;//新增
                    case "data&normal": return !Boolean(dataOutput.result)&&!widget.NVG.View.hovered;//新增
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

                Repeater {
                    model: NVG.Settings.makeList(modelData, "elements")
                    delegate: CraftElement {
                        itemSettings: thiz.settings
                        itemData: dataSource
                        itemBackground: bgSource
                        interactionState: thiz.interactionState // override
                        interactionSource: modelData.interaction ?? ""
                        interactionSettingsBase: modelData
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
