import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Private 1.0 as NVG
import NERvGear.Preferences 1.0 as P
import NERvGear.Controls 1.0

NVG.Window {
    id: dialog

    readonly property var currentElement: elementView.currentTarget?.settings ?? null
    readonly property QtObject craftSettings: itemSettings ? NVG.Settings.makeMap(itemSettings, "craft") : null

    readonly property bool darkMode: craftSettings?.dark ?? true
    readonly property bool resizableWidth: !(itemSettings?.alignment & Qt.AlignLeft) ||
                                           !(itemSettings?.alignment & Qt.AlignRight)
    readonly property bool resizableHeight: !(itemSettings?.alignment & Qt.AlignTop) ||
                                            !(itemSettings?.alignment & Qt.AlignBottom)

    property CraftDelegate targetItem
    property QtObject itemSettings
    property var builtinElements: []

    property bool forceClose

    signal accepted
    signal closed
//编辑界面内顶上的物品编辑文字
    title: qsTr("Item Editor")
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
        const settings = duplicateSettingsMap(element, elementView.model);
        settings.alignment = undefined;
        settings.horizon = undefined;
        settings.vertical = undefined;
        elementView.model.append(settings);
        elementView.currentTarget = elementView.targetAt(elementView.count - 1);
    }

    onClosing: {
        if (forceClose)
            return;

        if (itemSettings && NVG.Settings.isModified(itemSettings)) {
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
            NVG.Settings.setModified(itemSettings, false);
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

    Page {
        anchors.fill: parent
//编辑界面上面的横条
        header: TitleBar {
            text: dialog.title
            standardButtons: Dialog.Save

            onAccepted: {
                if (resizableWidth && targetItem.width !== elementView.width)
                    itemSettings.width = elementView.width;

                if (resizableHeight && targetItem.height !== elementView.height)
                    itemSettings.height = elementView.height;

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

                onClicked: elementView.currentTarget = null

                ColorBackgroundSource {
                    id: bgSource
                    anchors.fill: elementView
                    z: -99.5
                    visible: craftSettings?.background ?? true
                    //编辑元素元素大小内的颜色
                    color: itemSettings?.color ?? ctx_widget.defaultBackgroundColor
                    configuration: itemSettings?.background ?? ctx_widget.defaultBackground
                    defaultBackground: pDefaultBackground.defaultBackground
                }

                CraftView {
                    id: elementView
                    anchors.centerIn: parent

                    interactive: true
                    gridGuide: craftSettings?.guide ?? true
                    gridSize: craftSettings?.grid ?? 10
                    gridSnap: craftSettings?.snap ?? true
                    model: itemSettings ? NVG.Settings.makeList(itemSettings, "elements") : null
                    delegate: CraftElement {
                        view: elementView
                        itemSettings: dialog.itemSettings
                        itemData: targetItem.dataSource
                        itemBackground: bgSource
                        settings: modelData
                        index: model.index
                    }

                    onDeselectRequest: elementView.currentTarget = null
                    onDeleteRequest: elementView.model.remove(elementView.currentTarget.index)
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
                enabled: elementView.currentTarget
                icon.name: "regular:\uf24d"
                onClicked: duplicateElement(currentElement)
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
                model: builtinElements
                delegate: MenuItem {
                    text: modelData.label
                    icon.name: modelData.icon
                    onClicked: addElement(modelData.source)
                }
            }
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
                        label: qsTr("Item Settings")
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
                            defaultValue: itemSettings
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
                            rightPadding: 84
                            //编辑界面内挂件名称右边的下拉菜单图标
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
                    }

                    P.ObjectPreferenceGroup {
                        Layout.fillWidth: true
                        width: parent.width
                        //特效设置
                        label: qsTr("Effect Settings")
                        enabled: currentElement
                        syncProperties: true
                        visible: expandButton.highlighted
                        Page {
                            id: elemPage
                            width: parent.width
                            implicitHeight: switch(elemBar.currentIndex)
                            {
                                    case 0: return layoutEffects.height + 56;
                                    case 1: return layoutTransform.height + 56;
                                    case 2: return layoutActionSetting.height + 56;
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
                                                // //水平偏移
                                                // P.SpinPreference {
                                                //     name: "horizon"
                                                //     label: " - " + qsTr("Horizontal Offset")
                                                //     defaultValue: 0
                                                //     from: -999
                                                //     to: 999
                                                //     stepSize: 1
                                                //     editable: true
                                                //     visible: pEffect.value
                                                //     display: P.TextFieldPreference.ExpandLabel
                                                // }
                                                // //垂直偏移
                                                // P.SpinPreference {
                                                //     name: "vertical"
                                                //     label: " - " + qsTr("Vertical Offset")
                                                //     defaultValue: 0
                                                //     from: -999
                                                //     to: 999
                                                //     stepSize: 1
                                                //     editable: true
                                                //     visible: pEffect.value
                                                //     display: P.TextFieldPreference.ExpandLabel
                                                // }
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
                                //变换
                                Item{
                                    //必须资源
                                    Flickable {
                                        anchors.fill: parent
                                        contentWidth: width
                                        contentHeight: layoutTransform.height
                                        topMargin: 16
                                        bottomMargin: 16
                                        Column {
                                            id: layoutTransform
                                            width: parent.width
                                            P.ObjectPreferenceGroup {
                                                syncProperties: true
                                                enabled: currentElement
                                                defaultValue: currentElement
                                                width: parent.width
                                                //必须资源
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
                                                    visible: enableOpacityAnimation.value&&opacitySettings.value
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
                                                    visible: rotationSettings.value
                                                }
                                                //旋转原点X
                                                P.SpinPreference {
                                                    name: "advancedRotationOriginX"
                                                    label: " - - " + qsTr("Origin X")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAdvancedRotation.value&&rotationSettings.value
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
                                                    visible: enableAdvancedRotation.value&&rotationSettings.value
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
                                                    visible: enableAdvancedRotation.value&&rotationSettings.value
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
                                                    visible: enableAdvancedRotation.value&&rotationSettings.value
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
                                                    visible: enableAdvancedRotation.value&&rotationSettings.value
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
                                                    visible: enableAdvancedRotation.value&&!enableAdvancedRotationAnimation.value&&rotationSettings.value
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
                                                    visible: enableAdvancedRotation.value&&rotationSettings.value
                                                }
                                                //速度
                                                P.SpinPreference {
                                                    name: "advancedRotationSpeed"
                                                    label: " - - - " + qsTr("Speed")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAdvancedRotationAnimation.value&&enableAdvancedRotation.value&&rotationSettings.value
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
                                                    visible: enableAdvancedRotationAnimation.value&&enableAdvancedRotation.value&&rotationSettings.value
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
                                                }
                                                //缩放原点X
                                                P.SpinPreference {
                                                    name: "scaleOriginX"
                                                    label: " - " + qsTr("Origin X")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: scaleSetting.value
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
                                                    visible: scaleSetting.value
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
                                                    visible: scaleSetting.value
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
                                                    visible: scaleSetting.value
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
                                                }
                                                //X偏移量
                                                P.SpinPreference {
                                                    name: "translateX"
                                                    label: " - " + qsTr("X")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: translateSetting.value
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
                                                    visible: translateSetting.value
                                                    defaultValue: 0
                                                    from: -10000
                                                    to: 10000
                                                    stepSize: 10
                                                }
                                            }
                                        }
                                    }
                                }
                                //动作设置
                                Item{
                                    //必须资源
                                    Flickable {
                                        anchors.fill: parent
                                        contentWidth: width
                                        contentHeight: layoutActionSetting.height
                                        topMargin: 16
                                        bottomMargin: 16
                                        Column {
                                            id: layoutActionSetting
                                            width: parent.width
                                            P.ObjectPreferenceGroup {
                                                syncProperties: true
                                                enabled: currentElement
                                                defaultValue: currentElement
                                                width: parent.width
                                                //必须资源
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
                                            //悬停移动
                                                P.SwitchPreference {
                                                    id: moveOnHover
                                                    name: "moveOnHover"
                                                    label: qsTr("Move On Hover")
                                                    visible: enableAction.value
                                                }
                                                //距离
                                                P.SpinPreference {
                                                    name: "moveHover_Distance"
                                                    label: " - " + qsTr("Distance")
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
                                                    label: " - " + qsTr("Direction")
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
                                                    label: " - " + qsTr("Duration")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAction.value&&moveOnHover.value
                                                    defaultValue: 300
                                                    from: 0
                                                    to: 10000
                                                    stepSize: 10
                                                }
                                            //悬停缩放
                                                P.SwitchPreference {
                                                    id: zoomOnHover
                                                    name: "zoomOnHover"
                                                    label: qsTr("Zoom On Hover")
                                                    visible: enableAction.value
                                                }
                                                //大小
                                                P.SpinPreference {
                                                    name: "zoomHover_XSize"
                                                    label: " - " + qsTr("X Scale")
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
                                                    label: " - " + qsTr("Y Scale")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAction.value&&zoomOnHover.value
                                                    defaultValue: 100
                                                    from: -100000
                                                    to: 100000
                                                    stepSize: 10
                                                }
                                                //中心
                                                P.SpinPreference {
                                                    name: "zoomHover_OriginX"
                                                    label: " - " + qsTr("Origin X")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAction.value&&zoomOnHover.value
                                                    defaultValue: 0
                                                    from: -10000
                                                    to: 10000
                                                    stepSize: 10
                                                }
                                                P.SpinPreference {
                                                    name: "zoomHover_OriginY"
                                                    label: " - " + qsTr("Origin Y")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAction.value&&zoomOnHover.value
                                                    defaultValue: 0
                                                    from: -10000
                                                    to: 10000
                                                    stepSize: 10
                                                }
                                                //持续时间
                                                P.SpinPreference {
                                                    name: "zoomHover_Duration"
                                                    label: " - " + qsTr("Duration")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAction.value&&zoomOnHover.value
                                                    defaultValue: 300
                                                    from: 0
                                                    to: 10000
                                                    stepSize: 10
                                                }
                                            //悬停旋转
                                                P.SwitchPreference {
                                                    id: spinOnHover
                                                    name: "spinOnHover"
                                                    label: qsTr("Spin On Hover")
                                                    visible: enableAction.value
                                                }
                                                //角度
                                                P.SpinPreference {
                                                    name: "spinHover_Direction"
                                                    label: " - " + qsTr("Direction")
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
                                                    label: " - " + qsTr("Duration")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAction.value&&spinOnHover.value
                                                    defaultValue: 300
                                                    from: 0
                                                    to: 10000
                                                    stepSize: 10
                                                }
                                            // TODO 3D旋转
                                            //悬停闪烁
                                                P.SwitchPreference {
                                                    id: glimmerOnHover
                                                    name: "glimmerOnHover"
                                                    label: qsTr("Glimmer On Hover")
                                                    visible: enableAction.value
                                                }
                                                //时间
                                                P.SpinPreference {
                                                    name: "glimmerHover_Duration"
                                                    label: " - " + qsTr("Duration")
                                                    editable: true
                                                    display: P.TextFieldPreference.ExpandLabel
                                                    visible: enableAction.value&&glimmerOnHover.value
                                                    defaultValue: 300
                                                    from: 0
                                                    to: 10000
                                                    stepSize: 10
                                                }
                                            }
                                        }
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