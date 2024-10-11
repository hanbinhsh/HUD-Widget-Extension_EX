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
                            case 0: return normal.height + 56;
                            case 1: return layoutVisibleSetting.contentHeight + 56;
                            case 2: return layoutTransformSetting.contentHeight + 56;
                            case 3: return layoutActionSetting.contentHeight + 56;
                            case 4: return displayMaskSetting.height + 56;
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
                                //必须资源
                                Flickable {
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: normal.height
                                    topMargin: 16
                                    bottomMargin: 16
                                    Column {
                                        id: normal
                                        width: parent.width
                                        P.ObjectPreferenceGroup {
                                            syncProperties: true
                                            enabled: currentItem
                                            width: parent.width
                                            defaultValue: currentItem
                                            //必须资源
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
                                            P.SelectPreference {
                                                name: "separate"
                                                label: qsTr("Background Hierarchy")
                                                textRole: "label"
                                                valueRole: "value"
                                                defaultValue: 0
                                                model: [
                                                    { label: qsTr("<Default>"), value: undefined },
                                                    { label: qsTr("Element"), value: 0 },
                                                    { label: qsTr("Item"), value: 1 }
                                                ]
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
                                        }
                                    }
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
                                //必须资源
                                Flickable {
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: displayMaskSetting.height
                                    topMargin: 16
                                    bottomMargin: 16
                                    Column {
                                        id: displayMaskSetting
                                        width: parent.width
                                        P.ObjectPreferenceGroup {
                                            syncProperties: true
                                            enabled: currentItem
                                            width: parent.width
                                            defaultValue: currentItem
                                            //必须资源
                                            //显示时的遮罩
                                            P.SwitchPreference {
                                                id: usedisplayMask
                                                name: "usedisplayMask"
                                                label: qsTr("Show Mask")
                                            }
                                            P.SwitchPreference {
                                                name: "maskVisibleAfterAnimation"
                                                label: qsTr("Display Mask After Animation")
                                                defaultValue: true
                                                visible: usedisplayMask.value
                                            }
                                            P.ImagePreference {
                                                name: "displayMaskSource"
                                                label: qsTr("Mask Image")
                                                visible: usedisplayMask.value
                                            }
                                            P.SelectPreference {
                                                name: "displayMaskFill"
                                                label: qsTr("Fill Mode")
                                                model: [ qsTr("Stretch"), qsTr("Fit"), qsTr("Crop"), qsTr("Tile"), qsTr("Tile Vertically"), qsTr("Tile Horizontally"), qsTr("Pad") ]
                                                defaultValue: 1
                                                visible: usedisplayMask.value
                                            }
                                            P.SpinPreference {
                                                name: "maskOpacity"
                                                label: qsTr("Mask Opacity")
                                                editable: true
                                                defaultValue: 100
                                                from: 0
                                                to: 100
                                                stepSize: 5
                                                display: P.TextFieldPreference.ExpandLabel
                                                visible: usedisplayMask.value
                                            }
                                            P.SpinPreference {
                                                name: "maskRotation"
                                                label: qsTr("Mask Rotation")
                                                editable: true
                                                defaultValue: 0
                                                from: -360
                                                to: 360
                                                stepSize: 1
                                                display: P.TextFieldPreference.ExpandLabel
                                                visible: usedisplayMask.value
                                            }
                                            Row{
                                                spacing: 8
                                                visible: usedisplayMask.value
                                                Column {
                                                    Label {
                                                        text: qsTr("X & Y")
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }
                                                    P.ObjectPreferenceGroup {
                                                        syncProperties: true
                                                        enabled: currentItem
                                                        defaultValue: currentItem
                                                        P.SpinPreference {
                                                            name: "displayMaskTranslateX"
                                                            editable: true
                                                            defaultValue: 0
                                                            from: -10000
                                                            to: 10000
                                                            stepSize: 1
                                                            display: P.TextFieldPreference.ExpandLabel
                                                        }
                                                        P.SpinPreference {
                                                            name: "displayMaskTranslateY"
                                                            editable: true
                                                            defaultValue: 0
                                                            from: -10000
                                                            to: 10000
                                                            stepSize: 1
                                                            display: P.TextFieldPreference.ExpandLabel
                                                        }
                                                    }
                                                }
                                                Column {
                                                    Label {
                                                        text: qsTr("Height & Width")
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                    }
                                                    P.ObjectPreferenceGroup {
                                                        syncProperties: true
                                                        enabled: currentItem
                                                        defaultValue: currentItem
                                                        P.SpinPreference {
                                                            name: "displayMaskTranslateScaleHeight"
                                                            editable: true
                                                            defaultValue: 54
                                                            from: 0
                                                            to: 10000
                                                            stepSize: 1
                                                            display: P.TextFieldPreference.ExpandLabel
                                                        }
                                                        P.SpinPreference {
                                                            name: "displayMaskTranslateScaleWidth"
                                                            editable: true
                                                            defaultValue: 54
                                                            from: 0
                                                            to: 10000
                                                            stepSize: 1
                                                            display: P.TextFieldPreference.ExpandLabel
                                                        }
                                                    }
                                                }
                                            }
                                            P.SpinPreference {
                                                name: "displayMaskTime"
                                                label: qsTr("Display Mask Time")
                                                editable: true
                                                defaultValue: 250
                                                from: 0
                                                to: 10000
                                                stepSize: 50
                                                display: P.TextFieldPreference.ExpandLabel
                                                visible: usedisplayMask.value
                                            }
                                            P.SpinPreference {
                                                name: "hideMaskTime"
                                                label: qsTr("Hide Mask Time")
                                                editable: true
                                                defaultValue: 250
                                                from: 0
                                                to: 10000
                                                stepSize: 50
                                                display: P.TextFieldPreference.ExpandLabel
                                                visible: usedisplayMask.value
                                            }
                                        }
                                    }
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
