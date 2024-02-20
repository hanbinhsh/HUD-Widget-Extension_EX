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

            onEntered: if (!widget.editing) itemView.currentTarget = thiz
            onPressed: if (actionSource.status) NVG.SystemCall.playSound(NVG.SFX.FeedbackClick)
            onClicked: {
                if (!widget.editing) {
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
