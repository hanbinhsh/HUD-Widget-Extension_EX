import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import "impl" as Impl
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

    function duplicateItem(item) {
        const settings = Impl.Settings.duplicateMap(item, itemView.model);
        settings.alignment = undefined;
        settings.horizon = undefined;
        settings.vertical = undefined;
        itemView.model.append(settings);
        itemView.currentTarget = itemView.targetAt(itemView.count - 1);
    }

    Connections {
        target: itemView

        onCopyRequest: {
            if (currentItem)
                Impl.Settings.copyItem(currentItem);
        }
        onPasteRequest: {
            if (Impl.Settings.copiedItem)
                duplicateItem(Impl.Settings.copiedItem);
        }
        onDeleteRequest: {
            if (itemView.count > 1)
                removeDialog.open();
        }
        onDeselectRequest: itemView.currentTarget = null
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
    Dialog {
        id: cutDialog
        anchors.centerIn: parent
        title: "Save Success"
        modal: true
        parent: Overlay.overlay
        standardButtons: Dialog.Yes
        Label { text: qsTr("Saved the item shot to the root path of Sao") }
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
            //截图按钮
            ToolButton {
                icon.name: "regular:\uf0c4"
                enabled: currentItem
                onClicked: {
                    itemView.currentTarget.grabToImage(function(result) {
                        result.saveToFile("../Item.png");
                    });
                    cutDialog.open()
                }
            }
            //编辑按钮
            ToolButton {
                icon.name: "regular:\uf044"
                enabled: currentItem
                onClicked: {
                    editor.active = true;
                    editor.item.targetItem = itemView.currentTarget;
                    editor.item.targetData = itemView.currentTarget.defaultData;
                    editor.item.targetText = itemView.currentTarget.defaultText;
                    const settings = Impl.Settings.duplicateMap(currentItem, itemView.model);
                    editor.item.targetSettings = settings;
                    editor.item.craftSettings = NVG.Settings.makeMap(settings, "craft");
                    editor.item.show();
                }
            }
            //复制
            ToolButton {
                enabled: currentItem
                icon.name: "regular:\uf24d"
                onClicked: toolMenu.popup()
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
        footer: TitleBar {
            id: footerBar
            //text: dialog.title
            height:36
            //显示按钮
            ToolButton {
                icon.name: (itemView.currentTarget?.widgetVisibilityAction ?? false) ? "regular:\uf06e" : "regular:\uf070"
                enabled: currentItem
                onClicked: itemView.currentTarget.visible = !itemView.currentTarget.toggleItem()
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
                    // 颜色动画
                    ColorPreferenceGroupW{
                        item: widget.defaultSettings
                    }
                    // 点击涟漪效果控制面板
                    RipplePreferenceGroupW{
                        item: widget.defaultSettings
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
                        
                        // 动态高度计算
                        implicitHeight: {
                            // 基础内边距/标题栏高度修正
                            let baseH = 56; 
                            
                            // 如果选中了 Others (index 4)，需要加上第二行 TabBar 的高度
                            if (elemBar.currentIndex === 4) {
                                baseH += othersBar.height;
                                // 根据第二行 Tab 的索引计算高度
                                switch(othersBar.currentIndex) {
                                    case 0: return layoutColorSetting.contentHeight + baseH;
                                    case 1: return displayMaskSetting.contentHeight + baseH;
                                    case 2: return layoutADVSetting.contentHeight + baseH;
                                }
                            } else {
                                // 第一行 Tab 的高度计算
                                switch(elemBar.currentIndex){
                                    case 0: return layoutNormalSetting.contentHeight + baseH;
                                    case 1: return layoutVisibleSetting.contentHeight + baseH;
                                    case 2: return layoutTransformSetting.contentHeight + baseH;
                                    case 3: return layoutActionSetting.contentHeight + baseH;
                                }
                            }
                            return 0;
                        }

                        // 头部：改为 Column 以容纳两行 TabBar
                        header: Column {
                            width: parent.width
                            
                            // 第一行：主要分类
                            TabBar {
                                id: elemBar
                                width: parent.width
                                clip: true
                                Repeater {
                                    // 将 Color, Display Mask, ADV 合并为 Others
                                    model: [qsTr("Normal"), qsTr("Visible"), qsTr("Transform"), qsTr("Action"), qsTr("Others")]
                                    TabButton {
                                        text: modelData
                                        // 5个按钮平均分配宽度，或者保持最小宽度
                                        width: Math.max(100, elemBar.width / 5) 
                                    }
                                }
                            }

                            // 第二行：其他设置 (仅当选中 Others 时显示)
                            TabBar {
                                id: othersBar
                                width: parent.width
                                visible: elemBar.currentIndex === 4
                                clip: true
                                Repeater {
                                    model: [qsTr("Color"), qsTr("Display Mask"), qsTr("ADV")]
                                    TabButton {
                                        text: modelData
                                        width: Math.max(100, othersBar.width / 3)
                                    }
                                }
                            }
                        }

                        // 主内容区域
                        StackLayout {
                            width: parent.width
                            currentIndex: elemBar.currentIndex

                            // Index 0: Normal
                            Item {
                                NormalPreferenceGroup {
                                    item: currentItem
                                    id: layoutNormalSetting
                                }
                            }
                            // Index 1: Visible
                            Item {
                                VisiblePreferenceGroup {
                                    item: currentItem
                                    id: layoutVisibleSetting
                                }
                            }
                            // Index 2: Transform
                            Item {
                                TransformPreferenceGroup {
                                    item: currentItem
                                    id: layoutTransformSetting
                                }
                            }
                            // Index 3: Action
                            Item {
                                ActionPreferenceGroup {
                                    item: currentItem
                                    id: layoutActionSetting
                                }
                            }
                            
                            // Index 4: Others (Nested StackLayout)
                            Item {
                                width: elemPage.width
                                // 这是一个容器，内部再放一个 StackLayout
                                StackLayout {
                                    width: elemPage.width
                                    anchors.fill: parent // 关键：内层 StackLayout 填满外层 Item
                                    currentIndex: othersBar.currentIndex
                                    
                                    // Others -> Index 0: Color
                                    Item {
                                        ColorPreferenceGroup {
                                            item: currentItem
                                            id: layoutColorSetting
                                        }
                                    }
                                    // Others -> Index 1: Mask
                                    Item {
                                        ShowMaskPreferenceGroup {
                                            item: currentItem
                                            id: displayMaskSetting
                                        }
                                    }
                                    // Others -> Index 2: ADV
                                    Item {
                                        ADVPreferenceGroup {
                                            item: currentItem
                                            id: layoutADVSetting
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Menu {
            id: toolMenu

            MenuItem {
                text: qsTr("Clone Item")
                enabled: currentItem
                onTriggered: duplicateItem(currentItem)
            }

            MenuItem {
                text: qsTr("Copy Item")
                enabled: currentItem
                onTriggered: Impl.Settings.copyItem(currentItem)
            }

            MenuItem {
                text: qsTr("Paste Item")
                enabled: Impl.Settings.copiedItem
                onTriggered: duplicateItem(Impl.Settings.copiedItem)
            }
        }
    } 
    Loader {
        id: editor
        active: false
        sourceComponent: CraftDialog {
            onAccepted: {
                const oldSettings = dialog.currentItem;
                itemView.model.set(itemView.currentTarget.index, targetSettings);
                targetSettings = null;
                try { // NOTE: old settings not always destructable
                    oldSettings.destroy();
                } catch (err) {}
            }

            onClosed: {
                if (targetSettings) {
                    const oldSettings = targetSettings;
                    targetSettings = null; // clear before destroy
                    oldSettings.destroy();
                }
            }
        }
    }
}