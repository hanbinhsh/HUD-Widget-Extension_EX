import QtQuick 2.12
import QtQuick.Controls 2.12

import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

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
    title: qsTr("HUD Edit")
    solid: settings.solid ?? false
    resizable: true
    editing: dialog.item?.visible ?? false

    implicitWidth: 64
    implicitHeight: 64

    //菜单中的编辑模式
    menu: Menu {
        Action {
            text: qsTr("Editing Mode...")

            onTriggered: dialog.active = true
        }
    }

    // Component.onCompleted: { // upgrade settings
    //     if (settings.font !== undefined) {
    //         defaultSettings.font = settings.font;
    //         settings.font = undefined;
    //     }
    //     if (settings.background !== undefined) {
    //         defaultSettings.background = settings.background;
    //         settings.background = undefined;
    //     }
    //     if (settings.foreground !== undefined) {
    //         defaultSettings.foreground = settings.foreground;
    //         settings.foreground = undefined;
    //     }
    //     if (settings.base !== undefined) {
    //         defaultSettings.base = settings.base;
    //         settings.base = undefined;
    //     }
    // }

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

        readonly property font defaultFont: Qt.font(settings.font ?? initialFont)

        readonly property var defaultBackground: settings.background
        readonly property color defaultBackgroundColor: settings.base ?? "transparent"

        readonly property color defaultTextColor: settings.foreground ?? "#BBFFFFFF"
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

            view: itemView
            settings: modelData
            index: model.index
            visible: widget.editing || targetVisible
            //挂件默认大小
            implicitWidth: Math.max(bgSource.implicitWidth, 16)
            implicitHeight: Math.max(bgSource.implicitHeight, 16)

            //编辑可见性界面
            hidden: {
                switch (modelData.visibility) {
                case "normal": return widget.NVG.View.hovered;
                case "hovered": return !widget.NVG.View.hovered;
                case "data": return !Boolean(dataOutput.result);
                case "data&hovered": return !Boolean(dataOutput.result)&&widget.NVG.View.hovered;//新增
                case "data&normal": return !Boolean(dataOutput.result)&&!widget.NVG.View.hovered;//新增
                default: break;
                }
                return false;
            }

            interactionSource: modelData.interaction ?? defaultItemInteraction
            interactionSettingsBase: modelData.interaction ? modelData : widget.defaultSettings

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

            Item {
                id: itemContent
                anchors.fill: parent
                parent: thiz.interactionItem?.contentParent ?? thiz

                state: thiz.hidden ? "HIDE" : "SHOW"
                states: [
                    State {
                        name: "SHOW"
                        PropertyChanges{ target: itemContent; opacity: 1.0 }
                        PropertyChanges{ target: thiz; targetVisible: true }
                    },
                    State {
                        name: "HIDE"
                        PropertyChanges{ target: itemContent; opacity: 0.0 }
                        PropertyChanges{ target: thiz; targetVisible: false }
                    }
                ]
                transitions: [
                    Transition {
                        from: "SHOW"
                        to: "HIDE"
                        SequentialAnimation{
                            NumberAnimation { target: itemContent; property: "opacity"; duration: 250 }
                            PropertyAnimation { target: thiz; property: "targetVisible"; duration: 0 }
                        }
                    },
                    Transition {
                        from: "HIDE"
                        to: "SHOW"
                        PropertyAnimation { target: thiz; property: "targetVisible"; duration: 0 }
                        NumberAnimation { target: itemContent; property: "opacity"; duration: 250 }
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
                        interactionState: thiz.interactionState
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
