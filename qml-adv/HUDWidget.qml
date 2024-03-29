import QtQuick 2.12
import QtQuick.Controls 2.12

import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

import "utils.js" as Utils
//一级挂件属性
T.Widget {
    id: widget

    readonly property QtObject craftSettings: NVG.Settings.makeMap(settings, "craft")

    readonly property var initialFont: ({ family: "Source Han Sans SC", pixelSize: 24 })

//挂件框上的名称&&编辑界面蓝条上的字
    title: qsTr("HUD Edit")
    solid: false
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

    Component {
        id: cScaleTransform
        Scale {
            property CraftDelegate item

            readonly property var config: item.settings.scale ?? {}

            origin {
                x: {
                    switch (config.origin) {
                    case Item.Left:
                    case Item.TopLeft:
                    case Item.BottomLeft:
                        return config.originX ?? 0;
                    case Item.Right:
                    case Item.TopRight:
                    case Item.BottomRight:
                        return item.width + (config.originX ?? 0);
                    case Item.Center:
                    default: break;
                    }
                    return item.width / 2 + (config.originX ?? 0);
                }
                y: {
                    switch (config.origin) {
                    case Item.Top:
                    case Item.TopLeft:
                    case Item.TopRight:
                        return config.originY ?? 0;
                    case Item.Bottom:
                    case Item.BottomLeft:
                    case Item.BottomRight:
                        return item.height + (config.originY ?? 0);
                    case Item.Center:
                    default: break;
                    }
                    return item.height / 2 + (config.originY ?? 0);
                }
            }

            xScale: config.xScale ?? 1
            yScale: config.yScale ?? 1
        }
    }

    Component {
        id: cRotateTransform
        Rotation {
            property CraftDelegate item

            readonly property var config: item.settings.rotate ?? {}

            angle: config.angle ?? 0

            axis {
                x: config.axisX ?? 0
                y: config.axisY ?? 0
                z: config.axisZ ?? 1
            }

            origin {
                x: {
                    switch (config.origin) {
                    case Item.Left:
                    case Item.TopLeft:
                    case Item.BottomLeft:
                        return config.originX ?? 0;
                    case Item.Right:
                    case Item.TopRight:
                    case Item.BottomRight:
                        return item.width + (config.originX ?? 0);
                    case Item.Center:
                    default: break;
                    }
                    return item.width / 2 + (config.originX ?? 0);
                }
                y: {
                    switch (config.origin) {
                    case Item.Top:
                    case Item.TopLeft:
                    case Item.TopRight:
                        return config.originY ?? 0;
                    case Item.Bottom:
                    case Item.BottomLeft:
                    case Item.BottomRight:
                        return item.height + (config.originY ?? 0);
                    case Item.Center:
                    default: break;
                    }
                    return item.height / 2 + (config.originY ?? 0);
                }
            }
        }
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

        interactive: widget.editing
        gridSize: widget.craftSettings.grid ?? 10
        gridSnap: widget.craftSettings.snap ?? true
        model: NVG.Settings.makeList(widget.settings, "items")
        delegate: CraftDelegate {
            id: thiz

            readonly property NVG.DataSource dataSource: dataSource
            //编辑可见性界面
            readonly property bool itemVisible: {
                switch (modelData.visibility) {
                case "normal": return !widget.NVG.View.hovered;
                case "hovered": return widget.NVG.View.hovered;
                case "data": return Boolean(dataOutput.result);
                case "data&hovered": return Boolean(dataOutput.result)&&widget.NVG.View.hovered;//新增
                case "data&normal": return Boolean(dataOutput.result)&&!widget.NVG.View.hovered;//新增
                default: break;
                }
                return true;
            }

            property bool targetVisible: true

            hoverEnabled: true//Boolean(settings.moveOnHover||settings.zoomOnHover||settings.spinOnHover||settings.glimmerOnHover)

            view: itemView
            settings: modelData
            index: model.index
            visible: widget.editing || targetVisible
//挂件默认大小
            implicitWidth: Math.max(bgSource.implicitWidth, 54)
            implicitHeight: Math.max(bgSource.implicitHeight, 54)
//控制挂件是否显示
            state: itemVisible ? "SHOW" : "HIDE"
            states: [
                State{
                    name: "SHOW"
                    PropertyChanges{ target: itemContent; opacity: 1.0 }
                    PropertyChanges{ target: thiz; targetVisible: true }
                },
                State{
                    name: "HIDE"
                    PropertyChanges{ target: itemContent; opacity: 0.0 }
                    PropertyChanges{ target: thiz; targetVisible: false }
                }
            ]
// TODO 显示时的动画效果
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
            //旋转动画
            NumberAnimation on animationSpin {
                id: animationSpin
                running: false
                duration: settings.spinHover_Duration ?? 300 // 动画持续时间，单位为毫秒
                easing.type: settings.spinHover_Easing ?? 3 // 使用缓动函数使动画更平滑
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
                    animationSpin.running.stop()
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
                    animationSpin.running.stop()
                    animationSpin.to = 0
                    animationSpin.running = true
                }
                if(settings.glimmerOnHover){
                    animationGlimmer.running = false
                    recoverOpacity.start()
                }
            }
            onPressed: {
                if (actionSource.status) NVG.SystemCall.playSound(NVG.SFX.FeedbackClick)
            }
            onClicked: {
                if (!widget.editing) {// TODO 2级界面加入此行
                    if (actionSource.configuration)
                        actionSource.trigger(thiz);
                }
            }

            NVG.DataSource {
                id: dataSource
                configuration: modelData.data
            }
//加了||"data&hovered"
            NVG.DataSourceRawOutput {
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

                ColorBackgroundSource {
                   id: bgSource
                   anchors.fill: parent

                    z: -99.5
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
