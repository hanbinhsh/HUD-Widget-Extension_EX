import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Private 1.0 as NVG
import NERvGear.Preferences 1.0 as P
import NERvGear.Controls 1.0
import "settings"

import "impl" as Impl
import "utils.js" as Utils
// 二级菜单
NVG.Window {
    id: dialog
    readonly property var currentElement: elementView.currentTarget?.settings ?? null
    readonly property bool darkMode: craftSettings?.dark ?? true
    readonly property bool resizableWidth: !(targetSettings?.alignment & Qt.AlignLeft) ||
                                           !(targetSettings?.alignment & Qt.AlignRight)
    readonly property bool resizableHeight: !(targetSettings?.alignment & Qt.AlignTop) ||
                                            !(targetSettings?.alignment & Qt.AlignBottom)

    property QtObject targetItem
    property string targetText
    property QtObject targetData
    property QtObject targetSettings
    property QtObject craftSettings
    property bool fuseMode

    property bool forceClose
    signal accepted
    signal closed
    //编辑界面内顶上的物品编辑文字
    title: fuseMode ? qsTr("HUD Fuse") : qsTr("HUD Ultrahand")
    minimumWidth: 760
    minimumHeight: 360
    width: minimumWidth
    height: minimumHeight+140
    modality: Qt.WindowModal
    Style.theme: darkMode ? Style.Dark : Style.System
    function addElement(url) {
        const settings = NVG.Settings.createMap(elementView.model);
        settings.content = url;
        elementView.model.append(settings);
        elementView.currentTarget = elementView.targetAt(elementView.count - 1);
    }
    function duplicateElement(element) {
        const settings = Impl.Settings.duplicateMap(element, elementView.model);
        settings.alignment = undefined;
        settings.horizon = undefined;
        settings.vertical = undefined;
        elementView.model.append(settings);
        elementView.currentTarget = elementView.targetAt(elementView.count - 1);
    }
    function pasteElement(element) {
        if (fuseMode && element.content === "fusion") { // limit fusion depth
            const list = element.elements;
            if (list) {
                for (let i = 0; i < list.count; ++i) {
                    const settings = Impl.Settings.duplicateMap(list.get(i), elementView.model);
                    // keep element's layout
                    elementView.model.append(settings);
                }
                elementView.currentTarget = elementView.targetAt(elementView.count - 1);
            }
        } else {
            duplicateElement(element);
        }
    }
    onClosing: {
        if (forceClose)
            return;
        if (targetSettings && NVG.Settings.isModified(targetSettings)) {
            close.accepted = false;
            discardDialog.open();
        }
    }
    onVisibleChanged: {
        if (visible) {
            elementView.width = targetItem.width;
            elementView.height = targetItem.height;
            widthInput.placeholderText = targetItem.width;
            heightInput.placeholderText = targetItem.height;
            forceClose = false;
            NVG.Settings.setModified(targetSettings, false);
        } else {
            closed();
        }
    }
    Dialog {
        id: discardDialog
        anchors.centerIn: parent
        title: "Confirm"
        modal: true
        parent: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            forceClose = true;
            dialog.close();
        }
        Label { text: qsTr("Are you sure to discard the changes?") }
    }
    property var easingModel : [qsTr("Linear"),
                                qsTr("InQuad"),qsTr("OutQuad"),qsTr("InOutQuad"),qsTr("OutInQuad"),
                                qsTr("InCubic"),qsTr("OutCubic"),qsTr("InOutCubic"),qsTr("OutInCubic"),
                                qsTr("InQuart"),qsTr("OutQuart"),qsTr("InOutQuart"),qsTr("OutInQuart"),
                                qsTr("InQuint"),qsTr("OutQuint"),qsTr("InOutQuint"),qsTr("OutInQuint"),
                                qsTr("InSine"),qsTr("OutSine"),qsTr("InOutSine"),qsTr("OutInSine"),
                                qsTr("InExpo"),qsTr("OutExpo"),qsTr("InOutExpo"),qsTr("OutInExpo"),
                                qsTr("InCirc"),qsTr("OutCirc"),qsTr("InOutCirc"),qsTr("OutInCirc"),
                                qsTr("InElastic"),qsTr("OutElastic"),qsTr("InOutElastic"),qsTr("OutInElastic"),
                                qsTr("InBack"),qsTr("OutBack"),qsTr("InOutBack"),qsTr("OutInBack"),
                                qsTr("InBounce"),qsTr("OutBounce"),qsTr("InOutBounce"),qsTr("OutInBounce"),
                                qsTr("BezierSpline")];
    Page {
        anchors.fill: parent
        //编辑界面上面的横条
        header: TitleBar {
            text: dialog.title
            standardButtons: Dialog.Save
            onAccepted: {
                if (resizableWidth && targetItem.width !== elementView.width)
                    targetSettings.width = elementView.width;
                if (resizableHeight && targetItem.height !== elementView.height)
                    targetSettings.height = elementView.height;
                dialog.accepted();
                dialog.close();
            }
        }

        ScrollView {
            id: scrollView
            anchors.left: parent.left
            anchors.right: settingsPane.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            contentWidth: bgArea.width
            contentHeight: bgArea.height
            MouseArea {
                id: bgArea
                width: Math.max(scrollView.width, elementView.width + 32)
                height: Math.max(scrollView.height, elementView.height + 32)
                hoverEnabled: true
                onClicked: elementView.currentTarget = null
                CraftView {
                    id: elementView
                    anchors.centerIn: parent
                    interactive: true
                    gridGuide: craftSettings?.guide ?? true
                    gridSize: craftSettings?.grid ?? 10
                    gridSnap: craftSettings?.snap ?? true
                    model: targetSettings ? NVG.Settings.makeList(targetSettings, "elements") : null
                    delegate: CraftElement {
                        view: elementView
                        itemBackground: bgSource
                        settings: modelData
                        index: model.index
                        itemSettings: targetSettings
                        itemArea: bgArea
                        itemData: targetData
                        defaultData: targetData
                        defaultText: targetText
                        superArea: bgArea
                        interactionArea: interactionIndependent ? this : bgArea // override
                        interactionSource: modelData.interaction ?? ""
                        interactionSettingsBase: modelData
                        environment: Utils.elementEnvironment(this, targetItem.environment)
                        visible: true // override
                        contentEnabled: false
                    }
                    onCopyRequest: {
                        if (currentElement)
                            Impl.Settings.copyElement(currentElement);
                    }
                    onPasteRequest: {
                        if (Impl.Settings.copiedElement)
                            pasteElement(Impl.Settings.copiedElement);
                    }
                    onDeleteRequest: {
                        if (elementView.currentTarget)
                            elementView.model.remove(elementView.currentTarget.index);
                    }
                    onDeselectRequest: elementView.currentTarget = null
                    ColorBackgroundSource {
                        id: bgSource
                        anchors.fill: elementView
                        z: -99.5
                        visible: (!fuseMode && craftSettings?.background) ?? true
                        hovered: bgArea.containsMouse
                        pressed: bgArea.pressed
                        //编辑元素元素大小内的颜色
                        color: targetSettings?.color ?? ctx_widget.defaultBackgroundColor
                        configuration: targetSettings?.background ?? ctx_widget.defaultBackground
                        defaultBackground: pDefaultBackground.defaultBackground
                    }
                }
                Rectangle {
                    anchors.fill: elementView
                    color: "transparent"
                    border.width: 1
                    //编辑元素的边框颜色
                    border.color: dialog.Style.frameColor
                }
            }
        }
        //编辑元素的灯泡图标
        ToolButton {
            anchors.top: parent.top
            anchors.right: settingsPane.left
            anchors.rightMargin: 12
            icon.name: darkMode ? "light:\uf672" : "light:\uf0eb"
            onClicked: craftSettings.dark = !darkMode
        }
        Row {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 12
            height: 46
            //编辑元素的是否显示网格图标
            ToolButton {
                icon.name: "solid:\uf854"
                highlighted: elementView.gridGuide
                onClicked: craftSettings.guide = !elementView.gridGuide
            }
            //编辑元素的网格大小滑动条
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                from: 5
                to: 100  //20
                stepSize: 1
                live: true
                value: elementView.gridSize
                visible: elementView.gridGuide
                rightPadding: 64
                onValueChanged: if (craftSettings) craftSettings.grid = value
                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: elementView.gridSize + " px"
                }
            }
            //编辑元素的对齐到网格图标
            ToolButton {
                icon.name: "regular:\uf076"
                highlighted: elementView.gridSnap
                onClicked: craftSettings.snap = !elementView.gridSnap
            }
            //编辑元素的对齐到图片图标
            ToolButton {
                icon.name: "regular:\uf03e"
                highlighted: bgSource.visible
                onClicked: craftSettings.background = !bgSource.visible
            }
        }
        Row {
            anchors.right: settingsPane.left
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            //编辑元素的垃圾桶
            ToolButton {
                anchors.bottom: parent.bottom
                enabled: elementView.currentTarget
                icon.name: "regular:\uf2ed"
                onClicked: elementView.model.remove(elementView.currentTarget.index)
            }
            //编辑元素的复制
            ToolButton {
                anchors.bottom: parent.bottom
                icon.name: "regular:\uf24d"
                onClicked: toolElementMenu.popup()
            }
            //编辑元素的添加元素
            RoundButton {
                highlighted: true
                width: 56
                height: 56
                icon.name: "regular:\uf067"
                onClicked: addElementMenu.popup()
            }
        }
        //右下方的添加元素选项菜单
        Menu {
            id: addElementMenu
            Repeater {
                model: Utils.commonElements
                delegate: MenuItem {
                    text: modelData.label
                    icon.name: modelData.icon
                    onClicked: addElement(modelData.source)
                }
            }
            MenuSeparator {}
            Repeater {
                model: Utils.specialElements
                delegate: MenuItem {
                    enabled: !fuseMode
                    text: modelData.label
                    icon.name: modelData.icon
                    onClicked: addElement(modelData.source)
                }
            }
            MenuSeparator {}
            //更多元素选项
            Menu {
                id: moreElementMenu
                title: qsTr("More")
                enabled: count
                Repeater {
                    model: {
                        const files = [];
                        const resources = NVG.Resources.filter(/.*/, /com.gpbeta.hud.element(?:$|\/.+)/);
                        resources.forEach(function (resource) {
                            resource.files().forEach(function (file) {
                                files.push({ label: file.title || file.name, url: file.url });
                            });
                        });
                        return files;
                    }
                    delegate: MenuItem {
                        text: modelData.label
                        onClicked: addElement(modelData.url.toString())
                    }
                }
            }
        }
        Menu {
            id: toolElementMenu

            MenuItem {
                text: qsTr("Clone Element")
                enabled: currentElement
                onTriggered: duplicateElement(currentElement)
            }

            MenuItem {
                text: qsTr("Copy Element")
                enabled: currentElement
                onTriggered: Impl.Settings.copyElement(currentElement)
            }

            MenuItem {
                text: qsTr("Paste Element")
                enabled: Impl.Settings.copiedElement
                onTriggered: pasteElement(Impl.Settings.copiedElement)
            }
        }
        Pane {
            id: settingsPane
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 360
            topPadding: 0
            Flickable {
                anchors.fill: parent
                topMargin: 16
                contentWidth: width
                contentHeight: preferencesLayout.height
                ColumnLayout {
                    id: preferencesLayout
                    width: parent.width
                    //编辑界面内的项目设置窗口
                    P.DialogPreference {
                        Layout.fillWidth: true
                        live: true
                        label: fuseMode ? qsTr("Fusion Settings") : qsTr("Item Settings")
                        icon.name: "regular:\uf3f2"
                        //项目设置内的大小
                        P.ItemPreference {
                            label: qsTr("Size")
                            background.enabled: false
                            actionItem: Row {
                                spacing: 8
                                GeometryEditorInput {
                                    id: widthInput
                                    topPadding: 8
                                    bottomPadding: 16
                                    minValue: 16
                                    valueText: elementView.width
                                    enabled: resizableWidth
                                    onUpdateValue: elementView.width = value ?? targetItem.width
                                }
                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "x"
                                    enabled: false
                                }
                                GeometryEditorInput {
                                    id: heightInput
                                    topPadding: 8
                                    bottomPadding: 16
                                    minValue: 16
                                    valueText: elementView.height
                                    enabled: resizableHeight
                                    onUpdateValue: elementView.height = value ?? targetItem.height
                                }
                            }
                        }
                        //项目设置内的背景
                        P.ObjectPreferenceGroup {
                            defaultValue: targetSettings
                            syncProperties: true
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
                            //项目设置内的颜色
                            NoDefaultColorPreference {
                                name: "color"
                                label: qsTr("Color")
                                defaultValue: ctx_widget.defaultBackgroundColor
                            }
                        }
                    }
                    CraftDelegateSelector {
                        Layout.fillWidth: true
                        view: elementView
                        extractLabel: function (target, index) {
                            const label = target.settings.label;
                            return label || target.title;
                        }
                    }
                    P.ObjectPreferenceGroup {
                        Layout.fillWidth: true
                        //编辑界面内的元素设置
                        label: qsTr("Element Settings")
                        defaultValue: currentElement
                        enabled: currentElement
                        syncProperties: true
                        GeometryEditor { target: elementView.currentTarget }
                        //编辑界面内的挂件名称设置
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
                        enabled: currentElement
                        syncProperties: true
                        Page {
                            id: elemPage
                            width: parent.width
                            implicitHeight: switch(elemBar.currentIndex){
                                case 0: return layoutEffects.height + 56;
                                case 1: return layoutTransformSetting.contentHeight + 56;
                                case 2: return layoutActionSetting.contentHeight + 56;
                                return 0;
                            }
                            header:TabBar {
                                id: elemBar
                                width: parent.width
                                clip:true//超出父项直接裁剪
                                Repeater {//效果，变换(平移，镜像，透明度，旋转)
                                    model: [qsTr("Effects"),qsTr("Transform"),qsTr("Action")]
                                    TabButton {
                                        text: modelData
                                        width: Math.max(108, elemBar.width / 3)
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
                                        contentHeight: layoutEffects.height
                                        topMargin: 16
                                        bottomMargin: 16
                                        Column {
                                            id: layoutEffects
                                            width: parent.width
                                            P.ObjectPreferenceGroup {
                                                syncProperties: true
                                                enabled: currentElement
                                                width: parent.width
                                                defaultValue: currentElement?.effect ?? null
                                                //必须资源
                                                //图层特效
                                                P.SwitchPreference {
                                                    id: pEffect
                                                    name: "enabled"
                                                    label: qsTr("Enable Layer Effects")
                                                    onPreferenceEdited: {
                                                        if (!currentElement.effect) {
                                                            const map = NVG.Settings.createMap(currentElement);
                                                            map.enabled = value;
                                                            currentElement.effect = map;
                                                        }
                                                    }
                                                }
                                                //原始内容
                                                P.SelectPreference {
                                                    name: "original"
                                                    label: qsTr("Original Content")
                                                    model: [ qsTr("Hidden"), qsTr("Overlay"), qsTr("Combine") ]
                                                    defaultValue: 0
                                                    visible: pEffect.value
                                                }
                                                //模糊半径
                                                P.SliderPreference {
                                                    name: "blur"
                                                    label: " - " + qsTr("Blur Radius")
                                                    displayValue: value + " px"
                                                    defaultValue: 0
                                                    from: 0
                                                    to: 64
                                                    stepSize: 1
                                                    live: true
                                                    visible: pEffect.value
                                                }
                                                //扩展量
                                                P.SliderPreference {
                                                    name: "spread"
                                                    label: " - " + qsTr("Spread Amount")
                                                    displayValue: Math.round(value * 100) + " %"
                                                    defaultValue: 0
                                                    from: 0
                                                    to: 1
                                                    stepSize: 0.01
                                                    live: true
                                                    visible: pEffect.value
                                                }
                                                //水平偏移
                                                P.SpinPreference {
                                                    name: "horizon"
                                                    label: " - " + qsTr("Horizontal Offset")
                                                    defaultValue: 0
                                                    from: -999
                                                    to: 999
                                                    stepSize: 1
                                                    editable: true
                                                    visible: pEffect.value
                                                    display: P.TextFieldPreference.ExpandLabel
                                                }
                                                //垂直偏移
                                                P.SpinPreference {
                                                    name: "vertical"
                                                    label: " - " + qsTr("Vertical Offset")
                                                    defaultValue: 0
                                                    from: -999
                                                    to: 999
                                                    stepSize: 1
                                                    editable: true
                                                    visible: pEffect.value
                                                    display: P.TextFieldPreference.ExpandLabel
                                                }
                                                NoDefaultColorPreference {
                                                    name: "color"
                                                    label: qsTr("Color")
                                                    defaultValue: "transparent"
                                                    visible: pEffect.value
                                                }
                                                //悬停颜色
                                                NoDefaultColorPreference {
                                                    name: "hoveredColor"
                                                    label: qsTr("Hovered Color")
                                                    defaultValue: "transparent"
                                                    visible: pEffect.value
                                                }
                                                //按下时颜色
                                                NoDefaultColorPreference {
                                                    name: "pressedColor"
                                                    label: qsTr("Pressed Color")
                                                    defaultValue: "transparent"
                                                    visible: pEffect.value
                                                }
                                            }
                                        }
                                    }
                                }
                                Item{
                                    TransformPreferenceGroup{
                                        item: currentElement
                                        id: layoutTransformSetting
                                    }
                                }
                                Item{
                                    ActionPreferenceGroup{
                                        item: currentElement
                                        id: layoutActionSetting
                                    }
                                }
                            }
                        } 
                    }
                    Heading {
                        Layout.fillWidth: true
                        visible: elementView.currentTarget && prefLoader.sourceComponent
                        text: qsTr("%1 Settings").arg(elementView.currentTarget?.title ?? "")
                    }
                    Loader {
                        id: prefLoader
                        Layout.fillWidth: true
                        sourceComponent: elementView.currentTarget?.preference ?? null
                    }
                }
            }
            Style.elevation: 1
            //编辑元素界面右边的背景色
            Style.background: dialog.Style.dialogColor
        }
    }
}