import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import "utils.js" as Utils
// 一级菜单
NVG.Window {
    id: dialog
    Style.theme: Style.Dark
    readonly property var currentItem: itemView.currentTarget?.settings ?? null

    readonly property Item defaultInteractionItem:
        widget.makeInteractionItem(defaultIteractionParent, widget.defaultSettings, "interactionItem_NB")

    title: widget.title
    visible: true
    minimumWidth: 360
    maximumWidth: 360
    minimumHeight: 590
    transientParent: widget.NVG.View.window

    onClosing: titleBar.forceActiveFocus()

    function duplicateSettingsMap(src, parent) {
        const dst = NVG.Settings.createMap(parent);
        src.keys().forEach(function (key) {
            const prop = src[key];
            if (prop instanceof NVG.SettingsMap) {
                dst[key] = duplicateSettingsMap(prop, dst);
            } else if (prop instanceof NVG.SettingsList) {
                dst[key] = duplicateSettingsList(prop, dst);
            } else {
                // NOTE: shallow copy should be safe
                // because we NEVER modify nested objects
                dst[key] = prop;
            }
        });
        return dst;
    }

    function duplicateSettingsList(src, parent) {
        const dst = NVG.Settings.createList(parent);
        for (let i = 0; i < src.count; ++i)
            dst.append(duplicateSettingsMap(src.get(i), dst));
        return dst;
    }

    function requestDeleteItem() {
        if (itemView.count > 1)
            removeDialog.open();
    }

    Item {
        id: defaultIteractionParent
        width: 1
        height: 1
        visible: false
    }

    Dialog {
        id: removeDialog
        anchors.centerIn: parent

        title: "Confirm"
        modal: true
        parent: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.No

        onAccepted: itemView.model.remove(itemView.currentTarget.index)

        Label { text: qsTr("Are you sure to remove this item?") }
    }

    property var easingModel : [qsTr("Linear"),//0
                                qsTr("InQuad"),qsTr("OutQuad"),qsTr("InOutQuad"),qsTr("OutInQuad"),//1-4
                                qsTr("InCubic"),qsTr("OutCubic"),qsTr("InOutCubic"),qsTr("OutInCubic"),//5-8
                                qsTr("InQuart"),qsTr("OutQuart"),qsTr("InOutQuart"),qsTr("OutInQuart"),//9-12
                                qsTr("InQuint"),qsTr("OutQuint"),qsTr("InOutQuint"),qsTr("OutInQuint"),//13-16
                                qsTr("InSine"),qsTr("OutSine"),qsTr("InOutSine"),qsTr("OutInSine"),//17-20
                                qsTr("InExpo"),qsTr("OutExpo"),qsTr("InOutExpo"),qsTr("OutInExpo"),//21-24
                                qsTr("InCirc"),qsTr("OutCirc"),qsTr("InOutCirc"),qsTr("OutInCirc"),//25-28
                                qsTr("InElastic"),qsTr("OutElastic"),qsTr("InOutElastic"),qsTr("OutInElastic"),//28-32
                                qsTr("InBack"),qsTr("OutBack"),qsTr("InOutBack"),qsTr("OutInBack"),//33-36
                                qsTr("InBounce"),qsTr("OutBounce"),qsTr("InOutBounce"),qsTr("OutInBounce"),//36-40
                                qsTr("BezierSpline")];

    Page {
        anchors.fill: parent
        //部件编辑界面上蓝色的条
        header: TitleBar {
            id: titleBar
            text: dialog.title
            height:50
            //编辑按钮
            ToolButton {
                icon.name: "regular:\uf044"
                enabled: currentItem
                onClicked: {
                    editor.active = true;
                    editor.item.targetItem = itemView.currentTarget;
                    editor.item.itemSettings = duplicateSettingsMap(currentItem, itemView.model);
                    editor.item.show();
                }
            }
            //复制
            ToolButton {
                enabled: currentItem
                icon.name: "regular:\uf24d"
                onClicked: {
                    const settings = duplicateSettingsMap(currentItem, itemView.model);
                    settings.alignment = undefined;
                    settings.horizon = undefined;
                    settings.vertical = undefined;
                    itemView.model.append(settings);
                    itemView.currentTarget = itemView.targetAt(itemView.count - 1);
                }
            }
            //垃圾桶
            ToolButton {
                enabled: itemView.count > 1 && itemView.currentTarget
                icon.name: "regular:\uf2ed"
                onClicked: removeDialog.open()
            }
            //添加
            RoundButton {
                highlighted: true
                anchors.bottom: parent.bottom
                icon.name: "regular:\uf067"
                onClicked: {
                    const settings = NVG.Settings.createMap(itemView.model);
                    settings.label = Utils.randomName();
                    itemView.model.append(settings);
                    itemView.currentTarget = itemView.targetAt(itemView.count - 1);
                }
            }
        }

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: preferencesLayout.height
            topMargin: 16
            bottomMargin: 16
            leftMargin: 16
            rightMargin: 16

            Column {
                id: preferencesLayout
                width: parent.width - 32
                //部件编辑界面的部件设置
                P.DialogPreference {
                    width: parent.width
                    live: true
                    label: qsTr("Widget Settings")
                    icon.name: "regular:\uf3f2"

                    P.ObjectPreferenceGroup {
                        defaultValue: widget.defaultSettings
                        syncProperties: true
                        // implicitWidth: 300
                        //部件设置界面的背景设置
                        P.BackgroundPreference {
                            id: pDefaultBackground
                            name: "background"
                            label: qsTr("Default Background")

                            defaultBackground {
                                normal: Utils.NormalBackground
                                hovered: Utils.HoveredBackground
                                pressed: Utils.PressedBackground
                            }

                            preferableFilter: NVG.ResourceFilter {
                                packagePattern: /com.gpbeta.widget.hud/
                            }
                        }
                        //部件设置界面的颜色设置
                        P.ColorPreference {
                            name: "base"
                            label: qsTr("Default Background Color")
                            defaultValue: "transparent"
                        }
                        //部件设置界面的层级设置
                        P.SelectPreference {
                            name: "separate"
                            label: qsTr("Default Background Hierarchy")
                            model: [ qsTr("Element"), qsTr("Item") ]
                            defaultValue: 0
                        }
                        //部件设置界面的字体设置
                        P.FontPreference {
                            name: "font"
                            label: qsTr("Default Text Font")
                            defaultValue: Qt.font(widget.initialFont)
                        }
                        //部件设置界面的文字颜色设置
                        P.ColorPreference {
                            name: "foreground"
                            label: qsTr("Default Text Color")
                            defaultValue: "#BBFFFFFF"
                        }
                        //鼠标交互// BUG 用不了
                        // InteractionSelectPreference {
                        //     name: "interaction"
                        //     label: qsTr("Default Item Interaction")
                        //     settingsBase: widget.defaultSettings
                        //     builtinInteractions: Utils.partInteractions
                        //     catalogPattern: /com.gpbeta.hud-interaction\/item(?:$|\/.+)/
                        // }
                        Loader {
                            visible: sourceComponent
                            sourceComponent: defaultInteractionItem?.preference ?? null
                            PreferenceGroupIndicator {}
                        }
                    }

                    P.ObjectPreferenceGroup {
                        defaultValue: widget.settings
                        syncProperties: true
                        //矩形区域
                        P.SwitchPreference {
                            name: "solid"
                            label: qsTr("Rectangular Interactive Area")
                            message: qsTr("Mouse interactive with transparent pixels, lower resource usage")
                            defaultValue: false
                        }
                        //旋转
                        TransformRotatePreference { name: "rotate" }
                        //交互
                        InteractionSelectPreference {
                            name: "interaction"
                            settingsBase: widget.settings
                            builtinInteractions: Utils.widgetInteractions
                            catalogPattern: /com.gpbeta.hud-interaction\/widget(?:$|\/.+)/
                        }

                        Loader {
                            visible: sourceComponent
                            sourceComponent: widget.interactionItem?.preference ?? null
                            PreferenceGroupIndicator {}
                        }
                    }

                    P.ObjectPreferenceGroup {
                        defaultValue: widget.craftSettings
                        syncProperties: true
                        //部件设置界面的网格大小设置
                        P.SliderPreference {
                            name: "grid"
                            label: qsTr("Grid Size")
                            stepSize: 1
                            from: 5                      //5
                            to: 100                      //20
                            live: true
                            defaultValue: 10
                            displayValue: value + " px"
                        }
                        //部件设置界面的网格吸附设置
                        P.CheckPreference {
                            name: "snap"
                            label: qsTr("Snap to Grid")
                            defaultValue: true
                        }
                    }
                }
                //选择编辑的部件
                CraftDelegateSelector {
                    width: parent.width
                    view: itemView
                    extractLabel: function (target, index) {
                        return target.settings.label || qsTr("Item") + " " + (index + 1);
                    }
                }
                //部件编辑界面的物品设置
                P.ObjectPreferenceGroup {
                    label: qsTr("Item Settings")
                    defaultValue: currentItem
                    syncProperties: true
                    enabled: currentItem
                    width: parent.width
                    //界面上半部分设置坐标
                    GeometryEditor { target: itemView.currentTarget }
                    //部件编辑界面的名称设置
                    P.TextFieldPreference {
                        name: "label"
                        label: qsTr("Name")
                        display: P.TextFieldPreference.ExpandControl
                        rightPadding: 84
                        //名称旁边的下拉菜单
                        ToolButton {
                            id: expandButton
                            anchors.top: parent.top
                            anchors.topMargin: 4
                            anchors.right: parent.right
                            icon.name: highlighted ? "regular:\uf102" : "regular:\uf103"
                            highlighted: false
                            onClicked: highlighted = !highlighted
                        }
                    }
                    //透明度设置
                    //透明度设置开关
                    P.SwitchPreference {
                        id: opacitySettings
                        name: "opacitySettings"
                        label: qsTr("Opacity Setting")
                        visible: expandButton.highlighted
                    }
                    //透明度
                    P.SliderPreference {
                        name: "opacity"
                        label: " - " + qsTr("Opacity")
                        displayValue: Math.round(value * 100) + " %"
                        defaultValue: 1
                        from: 0
                        to: 1
                        stepSize: 0.01
                        live: true
                        visible: expandButton.highlighted&&opacitySettings.value&&!enableOpacityAnimation.value
                    }
                    //透明度动画
                    P.SwitchPreference {
                        id: enableOpacityAnimation
                        name: "enableOpacityAnimation"
                        label: " - " + qsTr("Opacity Animation")
                        visible: expandButton.highlighted&&opacitySettings.value
                    }
                    //速度
                    P.SpinPreference {
                        name: "opacityAnimationSpeed"
                        label: " - - " + qsTr("Speed")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableOpacityAnimation.value&&opacitySettings.value&&expandButton.highlighted
                        defaultValue: 500
                        from: 0
                        to: 10000
                        stepSize: 100
                    }
                    //旋转设置
                    //旋转设置开关
                    P.SwitchPreference {
                        id: rotationSettings
                        name: "rotationSettings"
                        label: qsTr("Rotation Setting")
                        visible: expandButton.highlighted
                    }
                    //旋转
                    P.SliderPreference {
                        name: "rotation"
                        label: " - " + qsTr("Rotation")
                        displayValue: value + " °"
                        defaultValue: 0
                        from: -360
                        to: 360
                        stepSize: 1
                        live: true
                        visible: expandButton.highlighted&&!rotationDisplay.value&&rotationSettings.value
                    }
                    //旋转动画开关
                    P.SwitchPreference {
                        id: rotationDisplay
                        name: "rotationDisplay"
                        label: " - " + qsTr("Auto Rotation")
                        visible: expandButton.highlighted&&rotationSettings.value
                    }
                    //转速
                    P.SliderPreference {
                        id:rotationSpeed
                        name: "rotationSpeed"
                        label: " - " + qsTr("Spin Speed")
                        defaultValue: 5
                        from: -500
                        to: 500
                        stepSize: 1
                        displayValue: value + " RPM"
                        live: true
                        visible: expandButton.highlighted&&rotationDisplay.value&&rotationSettings.value
                    }
                    //旋转FPS
                    P.SliderPreference {
                        id:rotationFPS
                        name: "rotationFPS"
                        label: " - " + qsTr("FPS")
                        defaultValue: 20
                        from: 1
                        to: 240
                        stepSize: 1
                        displayValue: value + " FPS"
                        live: true
                        visible: expandButton.highlighted&&rotationDisplay.value&&rotationSettings.value
                    }
                    //高级旋转
                    P.SwitchPreference {
                        id: enableAdvancedRotation
                        name: "enableAdvancedRotation"
                        label: " - " + qsTr("Advanced Rotation")
                        visible: rotationSettings.value&&expandButton.highlighted
                    }
                    //旋转原点X
                    P.SpinPreference {
                        name: "advancedRotationOriginX"
                        label: " - - " + qsTr("Origin X")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAdvancedRotation.value&&rotationSettings.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    //旋转原点Y
                    P.SpinPreference {
                        name: "advancedRotationOriginY"
                        label: " - - " + qsTr("Origin Y")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAdvancedRotation.value&&rotationSettings.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    //axis x,y,z
                    P.SpinPreference {
                        name: "advancedRotationAxisX"
                        label: " - - " + qsTr("Axis X")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAdvancedRotation.value&&rotationSettings.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    P.SpinPreference {
                        name: "advancedRotationAxisY"
                        label: " - - " + qsTr("Axis Y")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAdvancedRotation.value&&rotationSettings.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    P.SpinPreference {
                        name: "advancedRotationAxisZ"
                        label: " - - " + qsTr("Axis Z")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAdvancedRotation.value&&rotationSettings.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    //角度
                    P.SpinPreference {
                        name: "advancedRotationAngle"
                        label: " - - " + qsTr("Angle")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAdvancedRotation.value&&!enableAdvancedRotationAnimation.value&&rotationSettings.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -360
                        to: 360
                        stepSize: 10
                    }
                    //角度变化动画
                    P.SwitchPreference {
                        id: enableAdvancedRotationAnimation
                        name: "enableAdvancedRotationAnimation"
                        label: " - - " + qsTr("Rotation Animation")
                        visible: enableAdvancedRotation.value&&rotationSettings.value&&expandButton.highlighted
                    }
                    //速度
                    P.SpinPreference {
                        name: "advancedRotationSpeed"
                        label: " - - - " + qsTr("Speed")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAdvancedRotationAnimation.value&&enableAdvancedRotation.value&&rotationSettings.value&&expandButton.highlighted
                        defaultValue: 20
                        from: -100
                        to: 100
                        stepSize: 5
                    }
                    //FPS
                    P.SpinPreference {
                        name: "advancedRotationFPS"
                        label: " - - - " + qsTr("FPS")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAdvancedRotationAnimation.value&&enableAdvancedRotation.value&&rotationSettings.value&&expandButton.highlighted
                        defaultValue: 20
                        from: 1
                        to: 240
                        stepSize: 10
                    }
                    //缩放
                    P.SwitchPreference {
                        id: scaleSetting
                        name: "scaleSetting"
                        label: qsTr("Scale")
                        visible:expandButton.highlighted
                    }
                    //缩放原点X
                    P.SpinPreference {
                        name: "scaleOriginX"
                        label: " - " + qsTr("Origin X")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: scaleSetting.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    //缩放原点Y
                    P.SpinPreference {
                        name: "scaleOriginY"
                        label: " - " + qsTr("Origin Y")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: scaleSetting.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    //x比例 /1000
                    P.SpinPreference {
                        name: "scaleX"
                        label: " - " + qsTr("X Scale")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: scaleSetting.value&&expandButton.highlighted
                        defaultValue: 1000
                        from: -100000
                        to: 100000
                        stepSize: 50
                    }
                    //y比例 /1000
                    P.SpinPreference {
                        name: "scaleY"
                        label: " - " + qsTr("Y Scale")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: scaleSetting.value&&expandButton.highlighted
                        defaultValue: 1000
                        from: -100000
                        to: 100000
                        stepSize: 50
                    }
                    //平移
                    P.SwitchPreference {
                        id: translateSetting
                        name: "translateSetting"
                        label: qsTr("Translate")
                        visible:expandButton.highlighted
                    }
                    //X偏移量
                    P.SpinPreference {
                        name: "translateX"
                        label: " - " + qsTr("X")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: translateSetting.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    //Y偏移量
                    P.SpinPreference {
                        name: "translateY"
                        label: " - " + qsTr("Y")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: translateSetting.value&&expandButton.highlighted
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    //部件编辑界面的可见性设置
                    P.SelectPreference {
                        name: "visibility"
                        label: qsTr("Visibility")
                        model:[ qsTr("Always"), qsTr("Normal"), qsTr("Hovered"), qsTr("Data"), qsTr("Data&Hovered"), qsTr("Data&Normal")]
                        defaultValue: 0
                        //当编辑名称右边菜单下拉时显示
                        visible: expandButton.highlighted
                        load: function (newValue) {
                            if (newValue === undefined) {
                                value = defaultValue;
                                return;
                            }
                            switch (newValue) {
                            case "normal": value = 1; break;
                            case "hovered": value = 2; break;
                            case "data": value = 3; break;
                            case "data&hovered": value = 4; break;
                            case "data&normal": value = 5; break;
                            default: value = -1; break;
                            }
                        }
                        save: function () {
                            switch (value) {
                            case 5: return "data&normal";
                            case 4: return "data&hovered";
                            case 3: return "data";
                            case 2: return "hovered";
                            case 1: return "normal";
                            case 0:
                            default: break;
                            }
                            // undefined
                        }
                    }
                    //部件编辑界面的背景设置
                    P.BackgroundPreference {
                        name: "background"
                        label: qsTr("Background")

                        defaultBackground {
                            normal:  pDefaultBackground.value?.normal ??
                                     pDefaultBackground.defaultBackground.normal
                            hovered: pDefaultBackground.value?.hovered ??
                                     pDefaultBackground.defaultBackground.hovered
                            pressed: pDefaultBackground.value?.pressed ??
                                     pDefaultBackground.defaultBackground.pressed
                        }
                        preferableFilter: pDefaultBackground.preferableFilter
                    }
                    //部件编辑界面的颜色设置
                    NoDefaultColorPreference {
                        name: "color"
                        label: qsTr("Color")
                        defaultValue: ctx_widget.defaultBackgroundColor
                    }
                    //部件编辑界面的数据设置
                    P.DataPreference {
                        name: "data"
                        label: qsTr("Data")
                    }
                    // //部件编辑界面的动作设置
                    // P.ActionPreference {
                    //     name: "action"
                    //     label: qsTr("Action")
                    // }
                    //动作
                    P.SwitchPreference {
                        id: enableAction
                        name: "enableAction"
                        label: qsTr("Enable Action")
                    }
                    P.ActionPreference {
                        name: "action"
                        label: " - " + qsTr("Action")
                        //message: value ? "" : qsTr("Defaults to toggle slideshow")
                        visible: enableAction.value
                    }
                    // TODO 悬停动作 （移动，缩放）
                //中心
                    P.SpinPreference {
                        name: "zoomMouse_OriginX"
                        label: " - - " + qsTr("Origin X")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                    P.SpinPreference {
                        name: "zoomMouse_OriginY"
                        label: " - - " + qsTr("Origin Y")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 10
                    }
                //悬停移动
                    P.SwitchPreference {
                        id: moveOnHover
                        name: "moveOnHover"
                        label: " - " + qsTr("Move On Hover")
                        visible: enableAction.value
                    }
                    //距离
                    P.SpinPreference {
                        name: "moveHover_Distance"
                        label: " - - " + qsTr("Distance")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&moveOnHover.value
                        defaultValue: 10
                        from: -1000
                        to: 1000
                        stepSize: 10
                    }
                    //方向
                    P.SpinPreference {
                        name: "moveHover_Direction"
                        label: " - - " + qsTr("Direction")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&moveOnHover.value
                        defaultValue: 0
                        from: -180
                        to: 180
                        stepSize: 5
                    }
                    //持续时间
                    P.SpinPreference {
                        name: "moveHover_Duration"
                        label: " - - " + qsTr("Duration")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&moveOnHover.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //曲线
                    P.SelectPreference {
                        name: "moveOnHover_Easing"
                        label: " - - " + qsTr("Easing")
                        model: easingModel
                        defaultValue: 3
                        visible: enableAction.value&&moveOnHover.value
                    }
                //悬停缩放
                    P.SwitchPreference {
                        id: zoomOnHover
                        name: "zoomOnHover"
                        label: " - " + qsTr("Zoom On Hover")
                        visible: enableAction.value
                    }
                    //大小
                    P.SpinPreference {
                        name: "zoomHover_XSize"
                        label: " - - " + qsTr("X Scale")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&zoomOnHover.value
                        defaultValue: 100
                        from: -100000
                        to: 100000
                        stepSize: 10
                    }
                    P.SpinPreference {
                        name: "zoomHover_YSize"
                        label: " - - " + qsTr("Y Scale")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&zoomOnHover.value
                        defaultValue: 100
                        from: -100000
                        to: 100000
                        stepSize: 10
                    }
                    //持续时间
                    P.SpinPreference {
                        name: "zoomHover_Duration"
                        label: " - - " + qsTr("Duration")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&zoomOnHover.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //曲线
                    P.SelectPreference {
                        name: "zoomHover_Easing"
                        label: " - - " + qsTr("Easing")
                        model: easingModel
                        defaultValue: 3
                        visible: enableAction.value&&zoomOnHover.value
                    }
                //悬停旋转
                    P.SwitchPreference {
                        id: spinOnHover
                        name: "spinOnHover"
                        label: " - " + qsTr("Spin On Hover")
                        visible: enableAction.value
                    }
                    //角度
                    P.SpinPreference {
                        name: "spinHover_Direction"
                        label: " - - " + qsTr("Direction")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&spinOnHover.value
                        defaultValue: 360
                        from: -3600
                        to: 3600
                        stepSize: 180
                    }
                    //时间
                    P.SpinPreference {
                        name: "spinHover_Duration"
                        label: " - - " + qsTr("Duration")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&spinOnHover.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //曲线
                    P.SelectPreference {
                        name: "spinHover_Easing"
                        label: " - - " + qsTr("Easing")
                        model: easingModel
                        defaultValue: 3
                        visible: enableAction.value&&spinOnHover.value
                    }
                // TODO 3D旋转
                // TODO 持续旋转
                //悬停闪烁
                    P.SwitchPreference {
                        id: glimmerOnHover
                        name: "glimmerOnHover"
                        label: " - " + qsTr("Glimmer On Hover")
                        visible: enableAction.value
                    }
                    //时间
                    P.SpinPreference {
                        name: "glimmerHover_Duration"
                        label: " - - " + qsTr("Duration")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&glimmerOnHover.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //最小透明度
                    P.SpinPreference {
                        name: "glimmerHover_MinOpacity"
                        label: " - - " + qsTr("Min Opacity")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&glimmerOnHover.value
                        defaultValue: 0
                        from: 0
                        to: 100
                        stepSize: 10
                    }
                    //曲线
                    P.SelectPreference {
                        name: "glimmerHover_Easing"
                        label: " - - " + qsTr("Easing")
                        model: easingModel
                        defaultValue: 3
                        visible: enableAction.value&&glimmerOnHover.value
                    }
            //// 点击
                //点击缩放
                    P.SwitchPreference {
                        id: zoomOnClick
                        name: "zoomOnClick"
                        label: " - " + qsTr("Zoom On Click")
                        visible: enableAction.value
                    }
                    //大小
                    P.SpinPreference {
                        name: "zoomClick_XSize"
                        label: " - - " + qsTr("X Scale")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&zoomOnClick.value
                        defaultValue: 100
                        from: -100000
                        to: 100000
                        stepSize: 10
                    }
                    P.SpinPreference {
                        name: "zoomClick_YSize"
                        label: " - - " + qsTr("Y Scale")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&zoomOnClick.value
                        defaultValue: 100
                        from: -100000
                        to: 100000
                        stepSize: 10
                    }
                    //持续时间
                    P.SpinPreference {
                        name: "zoomClick_Duration"
                        label: " - - " + qsTr("Duration")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&zoomOnClick.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //曲线
                    P.SelectPreference {
                        name: "zoomClick_Easing"
                        label: " - - " + qsTr("Easing")
                        model: easingModel
                        defaultValue: 3
                        visible: enableAction.value&&zoomOnClick.value
                    }
                //点击旋转
                    P.SwitchPreference {
                        id: spinOnClick
                        name: "spinOnClick"
                        label: " - " + qsTr("Spin On Click")
                        visible: enableAction.value
                    }
                    //单次旋转
                    P.SwitchPreference {
                        name: "spinOnClickInstantRecuvery"
                        label: " - - " + qsTr("Instant Recuvery")
                        visible: enableAction.value&&spinOnClick.value
                    }
                    //角度
                    P.SpinPreference {
                        name: "spinClick_Direction"
                        label: " - - " + qsTr("Direction")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&spinOnClick.value
                        defaultValue: 360
                        from: -3600
                        to: 3600
                        stepSize: 180
                    }
                    //时间
                    P.SpinPreference {
                        name: "spinClick_Duration"
                        label: " - - " + qsTr("Duration")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: enableAction.value&&spinOnClick.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //曲线
                    P.SelectPreference {
                        name: "spinClick_Easing"
                        label: " - - " + qsTr("Easing")
                        model: easingModel
                        defaultValue: 3
                        visible: enableAction.value&&spinOnClick.value
                    }
            //周期动画
                    P.SwitchPreference {
                        id: cycleAnimation
                        name: "cycleAnimation"
                        label: qsTr("Cycle Animation")
                    }
                //周期平移
                    P.SwitchPreference {
                        id: cycleMove
                        name: "cycleMove"
                        label: " - " + qsTr("Cycle Moving")
                        visible:cycleAnimation.value
                    }
                    //距离
                    P.SpinPreference {
                        name: "moveCycle_Distance"
                        label: " - - " + qsTr("Distance")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: cycleAnimation.value&&cycleMove.value
                        defaultValue: 10
                        from: -1000
                        to: 1000
                        stepSize: 10
                    }
                    //方向
                    P.SpinPreference {
                        name: "moveCycle_Direction"
                        label: " - - " + qsTr("Direction")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: cycleAnimation.value&&cycleMove.value
                        defaultValue: 0
                        from: -180
                        to: 180
                        stepSize: 5
                    }
                    //持续时间
                    P.SpinPreference {
                        name: "moveCycle_Duration"
                        label: " - - " + qsTr("Duration")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: cycleAnimation.value&&cycleMove.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //延时
                    P.SpinPreference {
                        name: "moveCycle_Delay"
                        label: " - - " + qsTr("Delay")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: cycleAnimation.value&&cycleMove.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //等待时间
                    P.SpinPreference {
                        name: "moveCycle_Waiting"
                        label: " - - " + qsTr("Waiting")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        visible: cycleAnimation.value&&cycleMove.value
                        defaultValue: 300
                        from: 0
                        to: 10000
                        stepSize: 10
                    }
                    //曲线
                    P.SelectPreference {
                        name: "moveCycle_Easing"
                        label: " - - " + qsTr("Easing")
                        model: easingModel
                        defaultValue: 3
                        visible: cycleAnimation.value&&cycleMove.value
                    }
                }
            }
        }
    }
    
    Loader {
        id: editor
        active: false
        sourceComponent: CraftDialog {
            builtinElements: Utils.elements
            builtinInteractions: Utils.partInteractions

            onAccepted: {
                const oldSettings = dialog.currentItem;
                itemView.model.set(itemView.currentTarget.index, itemSettings);
                itemSettings = null;
                try { // NOTE: old settings not always destructable
                    oldSettings.destroy();
                } catch (err) {}
            }

            onClosed: {
                if (itemSettings) {
                    const oldSettings = itemSettings;
                    itemSettings = null; // clear before destroy
                    oldSettings.destroy();
                }
            }
        }
    }
}
