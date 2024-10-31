import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

import "."
import ".."
import "LauncherSettings"
import "../utils.js" as Utils

NVG.Window {
    id: eXLDialog

    readonly property var currentItem: eXLItemView.currentTarget?.settings ?? null

    Style.theme: Style.Dark
    title: qsTr("EXL Settings")
    visible: true
    minimumWidth: 360
    maximumWidth: 360
    minimumHeight: 700
    //transientParent: eXLauncherView.window
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
            builtinElements: Utils.elements
            builtinInteractions: Utils.partInteractions
            onAccepted: {
                const oldSettings = dialog.currentItem;
                eXLItemView.model.set(eXLItemView.currentTarget.index, itemSettings);
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
                onClicked: {
                    const settings = duplicateSettingsMap(currentItem, eXLItemView.model);
                    settings.alignment = undefined;
                    settings.horizon = undefined;
                    settings.vertical = undefined;
                    eXLItemView.model.append(settings);
                    eXLItemView.currentTarget = eXLItemView.targetAt(eXLItemView.count - 1);
                }
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
                    width: parent.width
                    view: eXLItemView
                    extractLabel: function (target, index) {
                        return target.settings.label || qsTr("Item") + " " + (index + 1);
                    }
                }

                P.ObjectPreferenceGroup {
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
                    P.SpinPreference {
                        name: "viewItemZ"
                        label: qsTr("Item Z")
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
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
    }
}