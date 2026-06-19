import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

import "."
import ".."
import "../settings"
import "LauncherSettings"
import "../utils.js" as Utils
import "../impl" as Impl

NVG.Window {
    id: eXLDialog

    readonly property var currentItem: eXLItemView.currentTarget?.settings ?? null

    Style.theme: Style.Dark
    title: qsTr("EXL Settings")
    visible: true
    minimumWidth: 360
    maximumWidth: 360
    minimumHeight: 700
    // 让设置窗口浮在启动器视图之上。
    // 注意：eXLauncherView 本身就是 NVG.View（窗口根），其 NVG.View 附加属性（"所在的 view"）为 undefined，
    // 不能像 HUD 的 widget(T.Widget) 那样用 widget.NVG.View.window。改用 QtQuick.Window 的 Window.window
    // 附加属性直接取它所在的 QWindow；?? null 防止 undefined 赋值给 QWindow* 报错。
    transientParent: eXLauncherView.Window.window ?? null
    // 启动器视图是置顶覆盖层，被动的 transientParent 未必能压过，需主动置顶。
    // 注意：改 flags 会让窗口重建；Windows 下若不「显式」带上标题/最小/最大/关闭等装饰位，
    // 重建后这些按钮会丢失（之前 `flags |= StaysOnTop` 就是这样把顶栏弄没了）。
    // 故这里显式列全装饰位 + 置顶位，再 raise()+requestActivate()。
    Component.onCompleted: {
        eXLDialog.flags = Qt.Window | Qt.WindowTitleHint | Qt.WindowSystemMenuHint
                | Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint
                | Qt.WindowStaysOnTopHint;
        eXLDialog.raise();
        eXLDialog.requestActivate();
    }
    onClosing: saveSettings()
    function saveSettings() {
        if (NVG.Settings.isModified(eXLauncherView.eXLSettings)){
            NVG.Settings.save(eXLauncherView.eXLSettings, "com.hanbinhsh.widget.hud_edit", "eXLSettings");
        } 
    }
    Dialog {
        id: removeDialog
        anchors.centerIn: parent

        title: "Confirm"
        modal: true
        parent: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.No

        onAccepted: eXLItemView.model.remove(eXLItemView.currentTarget.index)

        Label { text: qsTr("Are you sure to remove this item?") }
    }
    Loader {
        id: editor
        active: false
        sourceComponent: CraftDialog {
            onAccepted: {
                const oldSettings = eXLDialog.currentItem;
                eXLItemView.model.set(eXLItemView.currentTarget.index, targetSettings);
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
    function duplicateItem(item) {
        const settings = Impl.Settings.duplicateMap(item, eXLItemView.model);
        settings.alignment = undefined;
        settings.horizon = undefined;
        settings.vertical = undefined;
        eXLItemView.model.append(settings);
        eXLItemView.currentTarget = eXLItemView.targetAt(eXLItemView.count - 1);
    }
    Connections {
        target: eXLItemView

        onCopyRequest: {
            if (currentItem)
                Impl.Settings.copyItem(currentItem);
        }
        onPasteRequest: {
            if (Impl.Settings.copiedItem)
                duplicateItem(Impl.Settings.copiedItem);
        }
        onDeleteRequest: {
            if (eXLItemView.count > 1)
                removeDialog.open();
        }
        onDeselectRequest: eXLItemView.currentTarget = null
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
        header: TitleBar {
            id: titleBar
            text: qsTr("EX Launcher")
            height:50
            
            //复制
            ToolButton {
                enabled: currentItem
                icon.name: "regular:\uf24d"
                onClicked: toolMenu.popup()
            }
            //垃圾桶
            ToolButton {
                enabled: eXLItemView.currentTarget
                icon.name: "regular:\uf2ed"
                onClicked: removeDialog.open()
            }
            //添加
            RoundButton {
                highlighted: true
                anchors.bottom: parent.bottom
                icon.name: "regular:\uf067"
                onClicked: {
                    const settings = NVG.Settings.createMap(eXLItemView.model);
                    settings.label = Utils.randomName();
                    eXLItemView.model.append(settings);
                    eXLItemView.currentTarget = eXLItemView.targetAt(eXLItemView.count - 1);
                }
            }
        }
        footer: TitleBar {
            id: footerBar
            height:36
            // 展开/折叠按钮
            ToolButton {
                id: toggleButton
                anchors.right: parent.right
                anchors.rightMargin: 10
                icon.name: itemPanel.visible ? "regular:\uf146" : "regular:\uf0fe" // “-” 或 “+” 图标
                onClicked: {
                    itemPanel.visible = !itemPanel.visible
                    launcherPanel.visible = !launcherPanel.visible
                    itemPanelSlecter.visible = !itemPanelSlecter.visible
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
                P.ObjectPreferenceGroup {
                    id: launcherPanel
                    visible: true
                    label: qsTr("EX Launcher Settings")
                    defaultValue: eXLauncherView.eXLSettings
                    syncProperties: true
                    enabled: true
                    width: parent.width
                    P.BackgroundPreference {
                        visible: false
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
                    P.DataPreference {
                        //visible: false
                        name: "data"
                        label: qsTr("Data")
                    }
                    Page {
                        id: pPage
                        width: parent.width
                        implicitHeight: switch(pBar.currentIndex){
                            case 0: return elemPage.height + 56;
                            case 1: return menuElemPage.height + 56;
                            default: 0;
                        }
                        header:TabBar {
                            id: pBar
                            width: parent.width
                            clip:true//超出父项直接裁剪
                            Repeater {
                                model: [qsTr("Launcher"), qsTr("Menu")]
                                TabButton {
                                    text: modelData
                                    width: Math.max(128, elemBar.width / 2)
                                }
                            }
                        }
                        StackLayout {
                            width: parent.width
                            currentIndex: pBar.currentIndex
                            Page {
                                id: elemPage
                                width: parent.width
                                implicitHeight: switch(elemBar.currentIndex){
                                    case 0: return basicEXLS.contentHeight + 56;
                                    case 1: return mouseEventEXLS.contentHeight + 56;
                                    case 2: return animationEXLS.contentHeight + 56;
                                    case 3: return aDVEXLS.contentHeight + 56;
                                    default: 0;
                                }
                                header:TabBar {
                                    id: elemBar
                                    width: parent.width
                                    clip:true//超出父项直接裁剪
                                    Repeater {
                                        model: [qsTr("Basic"),qsTr("Mouse Event"),qsTr("Animation")]
                                        TabButton {
                                            text: modelData
                                            width: Math.max(128, elemBar.width / 3)
                                        }
                                    }
                                }
                                StackLayout {
                                    width: parent.width
                                    currentIndex: elemBar.currentIndex
                                    Item{BasicEXLS{id: basicEXLS}}
                                    Item{MouseEventEXLS{id: mouseEventEXLS}}
                                    Item{AnimationEXLS{id: animationEXLS; is_default: true}}
                                }
                            }
                            // Menu
                            Page {
                                id: menuElemPage
                                width: parent.width
                                implicitHeight: switch(menuElemBar.currentIndex){
                                    // case 0: return backgroundEXLSA.contentHeight + 56;
                                    // case 1: return animationEXLSA.contentHeight + 56;
                                    default: 0;
                                }
                                header:TabBar {
                                    id: menuElemBar
                                    width: parent.width
                                    clip:true//超出父项直接裁剪
                                    Repeater {
                                        model: [qsTr("Background"), qsTr("Animation")]
                                        TabButton {
                                            text: modelData
                                            width: Math.max(128, menuElemBar.width / 2)
                                        }
                                    }
                                }
                                StackLayout {
                                    width: parent.width
                                    currentIndex: menuElemBar.currentIndex
                                }
                            }
                        }
                    }
                }

                ItemSelector {
                    id: itemPanelSlecter
                    visible: false
                    width: parent.width
                    view: eXLItemView
                    extractLabel: function (target, index) {
                        return target.settings.label || qsTr("Item") + " " + (index + 1);
                    }
                }

                P.ObjectPreferenceGroup {
                    id: itemPanel
                    visible: false
                    label: qsTr("EX Launcher Items")
                    defaultValue: currentItem
                    syncProperties: true
                    enabled: currentItem
                    width: parent.width
                    P.TextFieldPreference {
                        name: "label"
                        label: qsTr("Name")
                        display: P.TextFieldPreference.ExpandControl
                    }
                    SpinPreferenceEx {
                        name: "viewItemZ"
                        label: qsTr("Item Z")
                        defaultValue: 0
                        from: -9999
                        to: 9999
                        stepSize: 1
                    }
                    P.SwitchPreference {
                        name: "showWithLauncher"
                        label: qsTr("Show with Launcher")
                        defaultValue: true
                    }
                    P.SwitchPreference {
                        name: "hideWithLauncher"
                        label: qsTr("Hide with Launcher")
                        defaultValue: true
                    }
                    P.Separator{}
                    Page {
                        id: advancedElemPage
                        width: parent.width
                        implicitHeight: switch(advancedElemBar.currentIndex){
                            case 0: return backgroundEXLSA.contentHeight + 56;
                            case 1: return animationEXLSA.contentHeight + 56;
                            default: 0;
                        }
                        header:TabBar {
                            id: advancedElemBar
                            width: parent.width
                            clip:true//超出父项直接裁剪
                            Repeater {
                                model: [qsTr("Background"),qsTr("Animation")]
                                TabButton {
                                    text: modelData
                                    width: Math.max(128, advancedElemBar.width / 2)
                                }
                            }
                        }
                        StackLayout {
                            width: parent.width
                            currentIndex: advancedElemBar.currentIndex
                            Item{BackgroundEXLS{id: backgroundEXLSA; current_default: currentItem}}
                            Item{AnimationEXLS{id: animationEXLSA; current_default: currentItem}}
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
}