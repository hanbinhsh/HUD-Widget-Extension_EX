import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import "utils.js" as Utils
import "settings"
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
    minimumHeight: 700
    transientParent: widget.NVG.View.window
    onClosing: titleBar.forceActiveFocus()

    function colorAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    function gradientStops(stops, fallback) {
        if (Array.isArray(stops))
            return stops;
        return [ { color: fallback, position: 0 }, { color: "transparent", position: 1 } ];
    }

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
                        //鼠标交互
                        InteractionSelectPreference {
                            name: "interaction"
                            label: qsTr("Default Item Interaction")
                            settingsBase: widget.defaultSettings
                            builtinInteractions: Utils.partInteractions
                            catalogPattern: /com.gpbeta.hud-interaction\/item(?:$|\/.+)/
                        }
                        Loader {
                            visible: sourceComponent
                            sourceComponent: defaultInteractionItem?.preference ?? null
                            PreferenceGroupIndicator {}
                        }
                    }
                    P.ObjectPreferenceGroup {
                        defaultValue: widget.defaultSettings
                        syncProperties: true
                        P.SwitchPreference {
                            id: enableOverallGradientEffect
                            name: "enableOverallGradientEffect"
                            label: qsTr("Enable Overall Gradient Effect")
                            message: qsTr("Also see https://webgradients.com/")
                            defaultValue: false
                        }
                        // P.SwitchPreference {
                        //     id: useFillGradient
                        //     name: "useFillGradient"
                        //     label: qsTr("Use Fill Gradient")
                        //     defaultValue: false
                        //     visible: enableOverallGradientEffect.value
                        // }
                        NoDefaultColorPreference {
                            name: "overallGradientColor0"
                            label: " --- " + qsTr("Start Color")
                            defaultValue: "#a18cd1"
                            visible: enableOverallGradientEffect.value//&&!useFillGradient.value
                        }
                        NoDefaultColorPreference {
                            name: "overallGradientColor1"
                            label: " --- " + qsTr("End Color")
                            defaultValue: "#fbc2eb"
                            visible: enableOverallGradientEffect.value//&&!useFillGradient.value
                        }
                        // GradientPreference {
                        //     name: "fillStops"
                        //     label: qsTr("Fill Gradient")
                        //     defaultValue: gradientStops(null, colorAlpha("#a18cd1", 0.5))
                        //     visible: enableOverallGradientEffect.value&&useFillGradient.value
                        // }
                        P.SelectPreference {
                            id: overallGradientDirection
                            name: "overallGradientDirect"
                            label: " --- " + qsTr("Gradient Direction")
                            defaultValue: 1
                            //从左到右,从下到上,从左上到右下
                            //旋转 3
                            //中心 4
                            //高级选项5 用于改变线性的start,end值
                            model: [ qsTr("Horizontal"), qsTr("Vertical"), qsTr("Oblique"), qsTr("Center"), qsTr("Conical"),qsTr("Advanced")]
                            visible: enableOverallGradientEffect.value
                        }
                        //方向为3,4时提供的垂直水平角度选项,为4时提供水平/垂直半径
                        //水平
                        P.SpinPreference {
                            name: "overallGradientHorizontal"
                            label: " --- --- " + qsTr("Horizontal")
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: (overallGradientDirection.value==4||overallGradientDirection.value==3)&&enableOverallGradientEffect.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 5
                        }
                        //垂直
                        P.SpinPreference {
                            name: "overallGradientVertical"
                            label: " --- --- " + qsTr("Vertical")
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: (overallGradientDirection.value==4||overallGradientDirection.value==3)&&enableOverallGradientEffect.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 5
                        }
                        //角度
                        P.SpinPreference {
                            name: "overallGradientAngle"
                            label: " --- --- " + qsTr("Angle")
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: (overallGradientDirection.value==4||overallGradientDirection.value==3)&&enableOverallGradientEffect.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 5
                        }
                        //水平半径 3
                        P.SpinPreference {
                            name: "overallGradientHorizontalRadius"
                            label: " --- --- " + qsTr("Horizontal Radius")
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: overallGradientDirection.value==3&&enableOverallGradientEffect.value
                            defaultValue: 50
                            from: -10000
                            to: 10000
                            stepSize: 5
                        }
                        //垂直半径 3
                        P.SpinPreference {
                            name: "overallGradientVerticalRadius"
                            label: " --- --- " + qsTr("Vertical Radius")
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: overallGradientDirection.value==3&&enableOverallGradientEffect.value
                            defaultValue: 50
                            from: -10000
                            to: 10000
                            stepSize: 5
                        }
                        Row{
                            spacing: 8
                            visible: enableOverallGradientEffect.value&&overallGradientDirection.value == 5
                            Column {
                                Label {
                                    text: qsTr("Start X & Y")
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                P.ObjectPreferenceGroup {
                                    syncProperties: true
                                    defaultValue: widget.defaultSettings
                                    //s.y x轴起始值
                                    P.SpinPreference {
                                        name: "overallGradientStartX"
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        defaultValue: 0
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //s.y y轴起始值
                                    P.SpinPreference {
                                        name: "overallGradientStartY"
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        defaultValue: 0
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                }
                            }
                            Column {
                                Label {
                                    text: qsTr("End X & Y")
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                P.ObjectPreferenceGroup {
                                    syncProperties: true
                                    defaultValue: widget.defaultSettings
                                    //e.x x轴结束值
                                    P.SpinPreference {
                                        name: "overallGradientEndX"
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        defaultValue: 100
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //e.y y轴结束值
                                    P.SpinPreference {
                                        name: "overallGradientEndY"
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        defaultValue: 100
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                }
                            }
                        }
                        //缓存
                        P.SwitchPreference {
                            name: "overallGradientCached"
                            label: " --- " + qsTr("Cached")
                            visible: enableOverallGradientEffect.value
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
                        rightPadding: 15
                    }
                }
                P.ObjectPreferenceGroup {
                    Layout.fillWidth: true
                    width: parent.width
                    //特效设置
                    label: qsTr("Effect Settings")
                    enabled: currentItem
                    syncProperties: true
                    Page {
                        id: elemPage
                        width: parent.width
                        implicitHeight: switch(elemBar.currentIndex){
                            case 0: return layoutNormalSetting.contentHeight + 56;
                            case 1: return layoutVisibleSetting.contentHeight + 56;
                            case 2: return layoutTransformSetting.contentHeight + 56;
                            case 3: return layoutActionSetting.contentHeight + 56;
                            case 4: return displayMaskSetting.contentHeight + 56;
                            return 0;
                        }
                        header:TabBar {
                            id: elemBar
                            width: parent.width
                            clip:true//超出父项直接裁剪
                            Repeater {
                                model: [qsTr("Normal"),qsTr("Visible"),qsTr("Transform"),qsTr("Action"),qsTr("Display Mask")]
                                TabButton {
                                    text: modelData
                                    width: Math.max(128, elemBar.width / 3)
                                }
                            }
                        }
                        StackLayout {
                            //anchors.centerIn: parent
                            width: parent.width
                            currentIndex: elemBar.currentIndex
                            //效果设置
                            Item{
                                NormalPreferenceGroup{
                                    item: currentItem
                                    id: layoutNormalSetting
                                }
                            }
                            Item{
                                VisiblePreferenceGroup{
                                    item: currentItem
                                    id: layoutVisibleSetting
                                }
                            }
                            Item{
                                TransformPreferenceGroup{
                                    item: currentItem
                                    id: layoutTransformSetting
                                }
                            }
                            Item{
                                ActionPreferenceGroup{
                                    item: currentItem
                                    id: layoutActionSetting
                                }
                            }
                            Item{
                                ShowMaskPreferenceGroup{
                                    item: currentItem
                                    id: displayMaskSetting
                                }
                            }
                        }
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