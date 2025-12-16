import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."
import "../Launcher/"

HUDElementTemplate {
    id: sliderDelegate

    title: qsTr("Control Slider")
    
    // 默认尺寸
    implicitWidth: 160
    implicitHeight: 30

    // --- 核心配置 ---
    readonly property string targetKey: settings.targetKey ?? ""
    readonly property real minValue: settings.minValue ?? 0
    readonly property real maxValue: settings.maxValue ?? 100
    readonly property real stepSize: settings.stepSize ?? 1
    
    // 颜色风格
    readonly property color trackColor: settings.trackColor ?? "#40FFFFFF"
    readonly property color progressColor: settings.progressColor ?? "#00AAFF"
    readonly property color handleColor: settings.handleColor ?? "#FFFFFF"

    property var _items_ex: {
        var itemView = LauncherCore.getEXLItemView();
        var labels = [];
        if (itemView) {
            for (var i = 0; i < itemView.count; i++) {
                labels.push(itemView.targetAt(i).settings.label || qsTr("Item") + " " + (i + 1));
            }
        }
        return labels;
    }

    property var _items_hud: {
        var itemView = widget.getHUDItemView();
        var labels = [];
        if (itemView) {
            for (var i = 0; i < itemView.count; i++) {
                labels.push(itemView.get(i).label || qsTr("Item") + " " + (i + 1));
            }
        }
        return labels;
    }

    property int itemIndex_child: settings.itemIndex_child ?? 0
    property int itemIndex_hud: settings.itemIndex_hud ?? 0
    property var _items_child: {
        var hudModel = widget.getHUDItemView();
        if (!hudModel || itemIndex_hud < 0 || itemIndex_hud >= hudModel.count) return [];
        var parentItemData = hudModel.get(itemIndex_hud);
        if (!parentItemData) return [];
        var childList = parentItemData.elements; 

        var labels = [];
        if (childList) {
            for (var i = 0; i < childList.count; i++) {
                var child = childList.get(i);
                labels.push(child.label || qsTr("Item") + " " + (i + 1));
            }
        }
        return labels;
    }

    // --- 设置面板 ---
    preference: P.ObjectPreferenceGroup {
        defaultValue: sliderDelegate.settings
        syncProperties: true

        P.SelectPreference {
            id: selectItem
            label: qsTr("Control Target")
            name: "controlTarget"
            model: [qsTr("HUD Element"), qsTr("EXL Element")]
            defaultValue: 0
        }
        P.SelectPreference {
            name: "itemIndex"
            label: qsTr("EX Launcher Item")
            defaultValue: 0
            model: _items_ex
            visible: selectItem.value==1
        }
        P.SelectPreference {
            name: "itemIndex_hud"
            label: qsTr("HUD Item")
            defaultValue: 0
            model: _items_hud
            visible: selectItem.value==0
        }
        P.SelectPreference {
            name: "itemIndex_child"
            label: qsTr("Child Item")
            defaultValue: 0
            model: _items_child
            visible: _items_child.length
        }

        // [核心] 设置要控制的目标属性名 (Key)
        // 例如输入 "circleRadius"，其他组件就可以读取 settings.circleRadius
        P.TextFieldPreference {
            name: "targetKey"
            label: qsTr("Target Key") 
            hint: "e.g. myOpacity"
            display: P.TextFieldPreference.ExpandControl
        }

        P.Separator {}

        // 数值范围
        P.SpinPreference {
            name: "minValue"
            label: qsTr("Min Value")
            defaultValue: 0
            from: -9999
            to: 9999
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        P.SpinPreference {
            name: "maxValue"
            label: qsTr("Max Value")
            defaultValue: 100
            from: -9999
            to: 9999
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        P.SpinPreference {
            name: "stepSize"
            label: qsTr("Step Size")
            defaultValue: 1
            from: 1
            to: 10000
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        
        P.SpinPreference {
            name: "defaultValue"
            label: qsTr("Default Value")
            defaultValue: 50
            from: -9999
            to: 9999
            display: P.TextFieldPreference.ExpandLabel
        }

        P.Separator {}

        // 样式
        NoDefaultColorPreference {
            name: "progressColor"
            label: qsTr("Active Color")
            defaultValue: "#00AAFF"
        }
        NoDefaultColorPreference {
            name: "trackColor"
            label: qsTr("Track Color")
            defaultValue: "#40FFFFFF"
        }
    }

    // --- 逻辑实现 ---

    // 初始化默认值
    Component.onCompleted: {
        if (targetKey && widget.settings[targetKey] === undefined) {
            // 如果全局设置里还没有这个key，写入默认值
            widget.settings[targetKey] = settings.defaultValue ?? minValue;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        
        // 使用 QtQuick.Controls 2 的 Slider 并自定义样式
        Slider {
            id: control
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            
            from: minValue
            to: maxValue
            stepSize: sliderDelegate.stepSize
            
            // [核心绑定]
            // 1. 值绑定到全局设置对应的 Key
            value: (targetKey && widget.settings[targetKey] !== undefined) 
                   ? widget.settings[targetKey] 
                   : (settings.defaultValue ?? minValue)

            // 2. 当拖动时，写入全局设置
            onMoved: {
                if (targetKey) {
                    // 利用 SAO 的 SettingsMap 机制，这会触发全局信号
                    widget.settings[targetKey] = value;
                }
            }

            // --- 自定义样式 (SAO 风格) ---
            background: Rectangle {
                x: control.leftPadding
                y: control.topPadding + control.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 4
                width: control.availableWidth
                height: implicitHeight
                radius: 2
                color: trackColor

                Rectangle {
                    width: control.visualPosition * parent.width
                    height: parent.height
                    color: progressColor
                    radius: 2
                }
            }

            handle: Rectangle {
                x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
                y: control.topPadding + control.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: control.pressed ? "#f0f0f0" : handleColor
                border.color: progressColor
                border.width: 2
                
                // 发光效果
                layer.enabled: true
                layer.effect: RectangularGlow {
                    glowRadius: 5
                    spread: 0.2
                    color: Qt.rgba(progressColor.r, progressColor.g, progressColor.b, 0.5)
                    cornerRadius: 8
                }
            }
            
            // 悬停显示数值 ToolTip
            ToolTip.visible: hovered || pressed
            ToolTip.text: value.toFixed(stepSize < 1 ? 2 : 0)
        }
    }
}