import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."
import "../Launcher/"

HUDElementTemplate {
    id: controllerDelegate

    title: qsTr("Controller")
    
    // 默认尺寸
    implicitWidth: 160
    implicitHeight: 30

    // --- 核心配置 ---
    readonly property string targetKey: settings.targetKey ?? ""
    readonly property real minValue: settings.minValue ?? 0
    readonly property real maxValue: settings.maxValue ?? 100
    readonly property real stepSize: settings.stepSize ?? 1

    // 除数
    readonly property real divider: settings.divider ?? 1

    // 样式选择: 0=Slider, 1=Knob, 2=Switch
    readonly property int sliderStyle: settings.sliderStyle ?? 0

    // 滑块/旋钮外观
    readonly property int handleType: settings.handleType ?? 1 // 0=Glow, 1=Solid
    readonly property real handleSize: settings.handleSize ?? 16
    readonly property int handleVisibility: settings.handleVisibility ?? 2 // 0=Hover, 1=None, 2=Always
    readonly property color handleColor: settings.handleColor ?? "#FFFFFF"
    
    // 轨道/刻度
    readonly property color trackColor: settings.trackColor ?? "#40FFFFFF"
    readonly property color progressColor: settings.progressColor ?? "#00AAFF"
    readonly property int trackThickness: settings.trackThickness ?? 4

    // 滑动条特有
    readonly property bool showTicks: settings.showTicks ?? false
    readonly property int tickCount: settings.tickCount ?? 5
    readonly property color tickColor: settings.tickColor ?? "#88FFFFFF"
    readonly property int tickSize: settings.tickSize ?? 4

    // 旋钮特有
    readonly property real knobSize: settings.knobSize ?? 60
    readonly property bool knobShowIndicator: settings.knobShowIndicator ?? true
    readonly property real knobTrackRadius: settings.knobTrackRadius ?? 24
    readonly property color knobBorderColor: settings.knobBorderColor ?? "#00AAFF"
    readonly property color knobBackgroundColor: settings.knobBackgroundColor ?? "#40000000"
    readonly property real knobBorderWidth: settings.knobBorderWidth ?? 1

    // 开关特有
    readonly property string valueOnRaw: settings.valueOn ?? "1"
    readonly property string valueOffRaw: settings.valueOff ?? "0"

    property var valueOn: parseTypedValue(valueOnRaw)
    property var valueOff: parseTypedValue(valueOffRaw)

    // 显示Tips
    readonly property bool showTips: settings.showTips ?? true

    // --- 内部逻辑变量 ---
    readonly property int controlTarget: settings.controlTarget ?? 0
    readonly property int itemIndex_ex: settings.itemIndex_ex ?? 0
    readonly property int itemIndex_hud: settings.itemIndex_hud ?? 0
    readonly property bool controlParent: settings.controlParent ?? false
    readonly property int itemIndex_child: settings.itemIndex_child ?? 0
    readonly property int selectedPropertyIndex: settings.selectedPropertyIndex ?? 0

    // --- 动态属性刷新逻辑 ---
    property var _target_properties: []
    property var _items_child: []
    property var _items_hud: []
    property var _items_ex: []

    property bool _isInitializing: true
    property bool _isUpdatingIndex: false
    property bool _isSwitchingTarget: false

    onControlTargetChanged:   { handleTargetSwitch(); }
    onItemIndex_exChanged:    { handleTargetSwitch(); }
    onItemIndex_hudChanged:   { handleTargetSwitch(); }
    onControlParentChanged:   { handleTargetSwitch(); }
    onItemIndex_childChanged: { handleTargetSwitch(); }

    function handleTargetSwitch() {
        if (_isInitializing) return;  // 初始化阶段不处理
        _isSwitchingTarget = true;
        getSettingItems();
        // 重置为第一项
        if (_target_properties && _target_properties.length > 0) {
            settings.selectedPropertyIndex = 0;
            settings.targetKey = _target_properties[0].toString();
            // console.log("Slider: Target switched, reset to", settings.targetKey);
        } else {
            settings.selectedPropertyIndex = 0;
            settings.targetKey = "";
        }
        _isSwitchingTarget = false;
    }

    function getSettingItems() {
        _items_hud = getHUDItems();
        _items_ex = getEXLItems();
        if (controllerDelegate.controlTarget === 1) { // 1 = EXL
            _items_child = getEXLChildItems();
        } else { // 0 = HUD
            _items_child = getHUDChildItems();
        }
        _target_properties = getTargetProperties();
    }
    
    function getEXLItems() {
        var itemView = LauncherCore.getEXLItemView();
        var labels = [];
        if (itemView) {
            for (var i = 0; i < itemView.count; i++) {
                labels.push(itemView.targetAt(i).settings.label || qsTr("Item") + " " + (i + 1));
            }
        }
        return labels;
    }

    function getHUDItems() {
        if (typeof widget === "undefined" || !widget) return [];
        var itemView = widget.getHUDItemView();
        var labels = [];
        if (itemView) {
            for (var i = 0; i < itemView.count; i++) {
                labels.push(itemView.get(i).label || qsTr("Item") + " " + (i + 1));
            }
        }
        return labels;
    }

    function getHUDChildItems() {
        if (typeof widget === "undefined" || !widget) return [];
        var hudModel = widget.getHUDItemView();
        if (!hudModel || itemIndex_hud < 0 || itemIndex_hud >= hudModel.count) return [];
        var parentItemData = hudModel.get(itemIndex_hud);
        if (!parentItemData) return [];
        var childList = parentItemData.elements; 
        if (!childList) return [];

        var labels = [];
        if (childList) {
            for (var i = 0; i < childList.count; i++) {
                var child = childList.get(i);
                labels.push(child.label || qsTr("Item") + " " + (i + 1));
            }
        }
        return labels;
    }

    // [新增] 获取 EXL 挂件的子项列表
    function getEXLChildItems() {
        var itemView = LauncherCore.getEXLItemView();
        if (!itemView || !itemView.model) return [];
        
        var exlModel = itemView.model;
        if (itemIndex_ex < 0 || itemIndex_ex >= exlModel.count) return [];
        
        var parentData = exlModel.get(itemIndex_ex);
        if (!parentData || !parentData.elements) return [];
        
        var childList = parentData.elements;
        var labels = [];
        
        for (var i = 0; i < childList.count; i++) {
            var child = childList.get(i);
            labels.push(child.label || qsTr("Item") + " " + (i + 1));
        }
        return labels;
    }
    
    function getTargetProperties() {
        var targetSettings = getRawTargetMap(); // 获取根设置对象
        if (!targetSettings) {
            console.log("Slider: No target settings found.");
            return [];
        }
        return flattenKeys(targetSettings);
    }

    function flattenKeys(obj, prefix) {
        var keys = [];
        var currentKeys = [];

        // 1. 获取当前层级的键
        // NVG SettingsMap 通常有 keys() 方法，普通 JS 对象用 Object.keys()
        if (obj && typeof obj.keys === 'function') {
            currentKeys = obj.keys();
        } else if (obj && typeof obj === 'object') {
            currentKeys = Object.keys(obj);
        } else {
            return [];
        }

        // 2. 遍历键
        for (var i = 0; i < currentKeys.length; i++) {
            var key = currentKeys[i];
            var value = obj[key];
            var fullKey = prefix ? (prefix + "." + key) : key;

            // 3. 判断是否是嵌套对象 (SettingsMap 或 Object)，且不是基本类型(如颜色/字体)
            // 注意：这里需要根据实际情况排除不需要展开的类型
            var isNested = (value && typeof value === 'object' && 
                            value.toString().indexOf("QColor") === -1 && 
                            value.toString().indexOf("QFont") === -1 && 
                            !Array.isArray(value)); // 数组通常不展开

            if (isNested) {
                // 递归获取子键
                var subKeys = flattenKeys(value, fullKey);
                if (subKeys.length > 0) {
                    keys = keys.concat(subKeys);
                } else {
                    // 如果是空对象，也把它自己加进去
                    keys.push(fullKey);
                }
            } else {
                // 它是叶子节点 (属性)，加入列表
                keys.push(fullKey);
            }
        }
        // 不去重，直接返回
        return keys.sort();
    }

    function syncPropertyIndex() {
        if (_isUpdatingIndex || _isSwitchingTarget) return;
        _isUpdatingIndex = true;
        
        var currentKey = settings.targetKey;
        if (!currentKey || !_target_properties || _target_properties.length === 0) {
            _isUpdatingIndex = false;
            return;
        }
        
        // 查找 targetKey 在列表中的位置
        for (var i = 0; i < _target_properties.length; i++) {
            if (_target_properties[i] === currentKey) {
                if (settings.selectedPropertyIndex !== i) {
                    // console.log("Slider: Syncing index to", i, "for key", currentKey);
                    settings.selectedPropertyIndex = i;
                }
                _isUpdatingIndex = false;
                return;
            }
        }
        
        // 如果找不到（比如目标改变了），重置为第一项
        // console.warn("Slider: targetKey '" + currentKey + "' not found, resetting");
        if (_target_properties.length > 0) {
            settings.selectedPropertyIndex = 0;
            settings.targetKey = _target_properties[0].toString();
        }
        
        _isUpdatingIndex = false;
    }

    function parseTypedValue(val) {
        if (val === undefined || val === null) return 0;
        var str = val.toString();
        
        // 1. 尝试转为布尔值
        if (str.toLowerCase() === "true") return true;
        if (str.toLowerCase() === "false") return false;
        
        // 2. 尝试转为数字 (排除空字符串，空字符串视为字符串)
        if (str.trim() === "") return "";
        var num = Number(str);
        if (!isNaN(num)) return num;
        
        // 3. 否则保留为字符串 (去除可能的引号)
        // 如果用户输入 "hide"，返回 hide
        return str.replace(/^"|"$/g, ''); 
    }

    // 在属性列表更新时调用
    on_Target_propertiesChanged: {
        if (!_isInitializing && !_isSwitchingTarget) {
            syncPropertyIndex();
        }
    }

    onSelectedPropertyIndexChanged: {
        if (_isUpdatingIndex || _isSwitchingTarget || _isInitializing) return;
        
        var idx = settings.selectedPropertyIndex;
        if (_target_properties && idx >= 0 && idx < _target_properties.length) {
            var newKey = _target_properties[idx].toString();
            if (settings.targetKey !== newKey) {
                // console.log("Slider: User selected property", newKey);
                settings.targetKey = newKey;
            }
        }
    }

    // --- 设置面板 ---
    preference: P.ObjectPreferenceGroup {
        defaultValue: controllerDelegate.settings
        syncProperties: true

        P.SelectPreference {
            id: selectItem
            label: qsTr("Control Target")
            name: "controlTarget"
            model: [qsTr("HUD Element"), qsTr("EXL Element")] // TODO 
            defaultValue: 0
        }
        P.SelectPreference {
            name: "itemIndex_ex"
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
        P.SwitchPreference {
            id: controlParent
            name: "controlParent"
            label: qsTr("Control Parent Only") // 仅控制父级
            defaultValue: false
        }
        P.SelectPreference {
            name: "itemIndex_child"
            label: qsTr("Child Item")
            defaultValue: 0
            model: _items_child
            visible: _items_child.length > 0 && !controlParent.value
        }
        P.SelectPreference {
            name: "selectedPropertyIndex"
            label: qsTr("Property")
            model: _target_properties
            visible: _target_properties ? _target_properties.length > 0 : false
            defaultValue: 0
        }

        P.TextFieldPreference {
            id: targetKeyField
            name: "targetKey"
            label: qsTr("Target Key") 
            hint: "e.g. myOpacity"
            display: P.TextFieldPreference.ExpandControl
            visible: false // 默认隐藏，使用 SelectPreference 选择
        }

        P.Separator {}

        // 数值范围
        P.SpinPreference {
            name: "minValue"
            label: qsTr("Min Value")
            defaultValue: 0
            from: -99999
            to: 99999
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: pStyle.value !== 2
        }
        P.SpinPreference {
            name: "maxValue"
            label: qsTr("Max Value")
            defaultValue: 100
            from: -99999
            to: 99999
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: pStyle.value !== 2
        }
        P.SpinPreference {
            name: "stepSize"
            label: qsTr("Step Size")
            defaultValue: 1
            from: 1
            to: 99999
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: pStyle.value !== 2
        }
        P.SpinPreference {
            name: "defaultValue"
            label: qsTr("Default Value")
            defaultValue: 50
            from: -99999
            to: 99999
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        P.SpinPreference { 
            name: "divider"
            label: qsTr("Divider")
            defaultValue: 1
            from: 1
            to: 99999
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        P.Separator {}

        // 样式选择
        P.SelectPreference {
            id: pStyle
            name: "sliderStyle"
            label: qsTr("Widget Style")
            model: [qsTr("Slider"), qsTr("Knob"), qsTr("Switch")]
            defaultValue: 0
        }

        // --- 滑块/旋钮通用 ---
        P.SpinPreference { 
            name: "handleSize"
            label: qsTr("Handle/Switch Size")
            defaultValue: 16
            from: 4
            to: 100
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
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
        
        P.Separator {visible: pStyle.value !== 2}

        // 滑块特有
        P.ObjectPreferenceGroup {
            visible: pStyle.value === 0
            defaultValue: controllerDelegate.settings
            syncProperties: true
            P.SpinPreference {
                name: "trackThickness";
                label: qsTr("Track Height");
                defaultValue: 4;
                from: 1;
                to: 9999
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            // 刻度
            P.SwitchPreference {
                id: pShowTicks;
                name: "showTicks";
                label: qsTr("Show Ticks");
                defaultValue: false
            }
            P.SpinPreference {
                name: "tickCount";
                label: qsTr("Tick Count");
                defaultValue: 5;
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: pShowTicks.value
            }
            P.SpinPreference {
                name: "tickSize";
                label: qsTr("Tick Size");
                defaultValue: 4;
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: pShowTicks.value
            }
            NoDefaultColorPreference {
                name: "tickColor";
                label: qsTr("Tick Color");
                defaultValue: "#88FFFFFF";
                visible: pShowTicks.value
            }
        }

        // 旋钮特有
        P.ObjectPreferenceGroup {
            visible: pStyle.value === 1
            defaultValue: controllerDelegate.settings
            syncProperties: true
            P.SpinPreference {
                name: "knobSize";
                label: qsTr("Knob Size");
                defaultValue: 60;
                from: 20;
                to: 300
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            // 轨道半径
            P.SpinPreference {
                name: "knobTrackRadius"
                label: qsTr("Track Radius")
                defaultValue: 24
                from: 1
                to: 9999
                editable: true
                display: P.TextFieldPreference.ExpandLabel 
            }
            P.SpinPreference {
                name: "trackThickness"
                label: qsTr("Track Width")
                defaultValue: 4
                from: 1
                to: 9999
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            // 边框宽度
            P.SpinPreference {
                name: "knobBorderWidth"
                label: qsTr("Border Width")
                defaultValue: 1
                from: 0
                to: 9999
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            // 边框颜色
            NoDefaultColorPreference {
                name: "knobBorderColor"
                label: qsTr("Border Color")
                defaultValue: "#00AAFF"
            }
            // 背景颜色 (区分于轨道颜色)
            NoDefaultColorPreference {
                name: "knobBackgroundColor"
                label: qsTr("Background Color")
                defaultValue: "#40000000"
            }
        }

        // 开关特有
        P.ObjectPreferenceGroup {
            visible: pStyle.value === 2
            defaultValue: controllerDelegate.settings
            syncProperties: true
            
            // 使用文本框以支持 "hide", "true", "0.5" 等各种输入
            P.TextFieldPreference {
                name: "valueOn"
                label: qsTr("Value On")
                defaultValue: "1"
                hint: "1, true, hide..."
                display: P.TextFieldPreference.ExpandControl
            }
            P.TextFieldPreference {
                name: "valueOff"
                label: qsTr("Value Off")
                defaultValue: "0"
                hint: "0, false, normal..."
                display: P.TextFieldPreference.ExpandControl
            }
        }

        P.Separator {visible: pStyle.value !== 2}

        // Handle 样式
        P.SelectPreference {
            name: "handleType"
            label: qsTr("Handle Style")
            model: [qsTr("Glow Ring"), qsTr("Solid Circle")]
            defaultValue: 1
            visible: pStyle.value !== 2
        }
        P.SelectPreference {
            name: "handleVisibility"
            label: qsTr("Handle Visibility")
            model: [qsTr("Press Only"), qsTr("None"), qsTr("Always")]
            defaultValue: 2
            visible: pStyle.value !== 2
        }
        NoDefaultColorPreference {
            name: "handleColor"
            label: qsTr("Handle Color")
            defaultValue: "#FFFFFF"
            visible: pStyle.value !== 2
        }

        P.Separator {visible: pStyle.value !== 2}

        P.SwitchPreference {
            name: "showTips";
            label: qsTr("Show Tips");
            defaultValue: true
            visible: pStyle.value !== 2
        }

    }

    // --- 逻辑实现 ---

    function getRawTargetMap() {
        if (controllerDelegate.controlTarget === 0 && typeof widget !== "undefined" && widget) { // HUD Element
            var hudModel = widget.getHUDItemView();
            if (hudModel && itemIndex_hud >= 0 && itemIndex_hud < hudModel.count) {
                var parentData = hudModel.get(itemIndex_hud);
                if (controllerDelegate.controlParent) {
                    return parentData;
                }
                if (parentData) {
                    // 如果选了子项
                    if (_items_child.length > 0 && itemIndex_child >= 0) {
                        if (parentData.elements && itemIndex_child < parentData.elements.count) {
                            return parentData.elements.get(itemIndex_child);
                        }
                    } 
                    // 否则是父项
                    return parentData;
                }
            }
        } else if (controllerDelegate.controlTarget === 1){
            // EXL 逻辑分支
            var itemView = LauncherCore.getEXLItemView();
            if (itemView && itemView.model) {
                var exlModel = itemView.model;
                if (itemIndex_ex >= 0 && itemIndex_ex < exlModel.count) {
                    var parentData = exlModel.get(itemIndex_ex);
                    
                    if (settings.controlParent) return parentData;
                    
                    if (parentData) {
                        if (_items_child.length > 0 && itemIndex_child >= 0) {
                            if (parentData.elements && itemIndex_child < parentData.elements.count) {
                                return parentData.elements.get(itemIndex_child);
                            }
                        } 
                        return parentData;
                    }
                }
            }
        }
        return null; 
    }

    function setDeepValue(root, path, value) {
        // console.log("setDeepValue:", root, path, value);
        if (!root || !path) return;
        var parts = path.split('.');
        var current = root;
        for (var i = 0; i < parts.length - 1; i++) {
            var key = parts[i];
            if (current[key] === undefined) {
                console.warn("Slider: Path not found:", path);
                return;
            }
            current = current[key];
        }
        var lastKey = parts[parts.length - 1];
        // 只有当 value 是数字时才应用除数
        var finalValue = value;
        if (typeof value === 'number') {
            finalValue = value / divider;
        }
        current[lastKey] = finalValue;
    }

    function getDeepValue(root, path) {
        if (!root || !path) return undefined;
        var parts = path.split('.');
        var current = root;
        
        for (var i = 0; i < parts.length; i++) {
            if (current === undefined || current === null) return undefined;
            current = current[parts[i]];
        }
        return current;
    }
    
    function getStoredValue() {
        var val = undefined;
        var map = getRawTargetMap(); 
        
        if (map && targetKey) {
            val = getDeepValue(map, targetKey);
        }

        if (val === undefined && targetKey) {
            if (typeof widget !== "undefined" && widget && widget.settings) {
                val = getDeepValue(widget.settings, targetKey);
            }
        }

        if (val === undefined) {
            val = settings.defaultValue ?? 50;
        }

        if (!isNaN(Number(val))) {
            return Number(val) * divider;
        }
        return val;
    }

    // 初始化默认值
    Timer {
        id: initTimer
        interval: 100 // 给足时间让环境准备好
        running: true
        repeat: false
        onTriggered: {
            // 安全调用函数
            getSettingItems();
            
            // 同步索引
            syncPropertyIndex();
            
            // 加载保存的值
            var savedVal = getStoredValue();
            
            // 确保 Loader 已加载
            if (loader.item) {
                loader.item.value = savedVal;
            } else {
                // 如果 Loader还没好，监听 loaded 信号
                loader.loaded.connect(function() {
                    loader.item.value = savedVal;
                });
            }
            
            _isInitializing = false;
        }
    }

    function writeValue(val) {
        if (!targetKey) return;
        var targetMap = getRawTargetMap();
        if (targetMap) {
            setDeepValue(targetMap, targetKey, val)
        } else {
            if (typeof widget !== "undefined" && widget && widget.settings) {
                setDeepValue(widget.settings, targetKey, val);
            } else {
                console.warn("Slider: Unable to find target map to write value.");
            }
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: {
            switch(sliderStyle) {
                case 1: return knobComponent;
                case 2: return switchComponent;
                default: return sliderComponent;
            }
        }
    }

    Component {
        id: sliderComponent
        Slider {
            id: control
            anchors.fill: parent
            anchors.leftMargin: 5; anchors.rightMargin: 5
            
            from: minValue
            to: maxValue
            stepSize: controllerDelegate.stepSize
            value: settings.defaultValue ?? 50

            onMoved: writeValue(value)

            // 背景 & 刻度
            background: Item {
                width: control.availableWidth
                height: control.availableHeight
                x: control.leftPadding
                y: control.topPadding

                // 刻度线
                Row {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: showTicks
                    spacing: (width - tickCount * 1) / (tickCount - 1)
                    Repeater {
                        model: tickCount
                        Rectangle {
                            width: 1; height: tickSize * 2 + trackThickness
                            color: tickColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // 轨道
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: trackThickness
                    radius: trackThickness/2
                    color: trackColor

                    Rectangle {
                        width: control.visualPosition * parent.width
                        height: parent.height
                        color: progressColor
                        radius: parent.radius
                    }
                }
            }

            // 滑块句柄
            handle: Rectangle {
                id: handleRect
                x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
                y: control.topPadding + control.availableHeight / 2 - height / 2
                width: handleSize; height: handleSize
                radius: handleSize / 2
                
                // 可见性逻辑
                visible: handleVisibility === 2 || (handleVisibility === 0 && (control.hovered || control.pressed))
                
                // 颜色逻辑 (实心或发光)
                color: handleType === 1 ? handleColor : (control.pressed ? "#f0f0f0" : handleColor)
                border.color: handleType === 1 ? Qt.darker(handleColor, 1.2) : controllerDelegate.handleColor
                border.width: handleType === 1 ? 1 : 2
                
                // 发光效果 (仅 Type 0)
                layer.enabled: handleType === 0
                layer.effect: RectangularGlow {
                    glowRadius: 5
                    spread: 0.2
                    color: Qt.rgba(handleColor.r, handleColor.g, handleColor.b, 0.5)
                    cornerRadius: handleRect.radius
                }
            }
            
            ToolTip.visible: (hovered || pressed) && showTips
            ToolTip.text: (value/divider).toFixed(stepSize < 1 ? 2 : 0)
        }
    }

    // === 2. 旋钮 (Knob) ===
    Component {
        id: knobComponent
        Dial {
            id: dial
            
            // [尺寸] 直接绑定 controllerDelegate 的属性
            width: controllerDelegate.knobSize
            height: width
            anchors.centerIn: parent
            
            from: controllerDelegate.minValue
            to: controllerDelegate.maxValue
            stepSize: controllerDelegate.stepSize
            value: settings.defaultValue ?? 50

            onMoved: writeValue(value)

            // [背景] 使用 Canvas 统一绘制背景、边框、轨道
            background: Canvas {
                id: knobCanvas
                width: controllerDelegate.knobSize
                height: width
                
                renderStrategy: Canvas.Threaded 
                renderTarget: Canvas.Image

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    var cx = width / 2;
                    var cy = height / 2;
                    
                    // --- 1. 绘制背景圆 (Body) ---
                    // 引用 controllerDelegate.knobBorderWidth
                    var bgRadius = controllerDelegate.knobSize / 2 - controllerDelegate.knobBorderWidth / 2;
                    
                    ctx.beginPath();
                    ctx.arc(cx, cy, bgRadius, 0, 2 * Math.PI);
                    ctx.fillStyle = controllerDelegate.knobBackgroundColor; 
                    ctx.fill();
                    
                    // --- 2. 绘制边框 (Border) ---
                    if (controllerDelegate.knobBorderWidth > 0) {
                        ctx.lineWidth = controllerDelegate.knobBorderWidth;
                        ctx.strokeStyle = controllerDelegate.knobBorderColor;
                        ctx.stroke();
                    }

                    // --- 3. 绘制轨道与进度 (Tracks) ---
                    var r = controllerDelegate.knobTrackRadius;
                    
                    // 角度定义: 135度 ~ 405度
                    var startAngle = Math.PI * 0.75;
                    var endAngle = Math.PI * 2.25;
                    
                    // 计算进度角度
                    var valuePos = (dial.value - dial.from) / (dial.to - dial.from);
                    valuePos = Math.max(0, Math.min(1, valuePos));
                    var currentAngle = startAngle + (valuePos * (endAngle - startAngle));
                    
                    ctx.lineCap = "round";

                    // 3.1 轨道槽 (未激活)
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, endAngle);
                    ctx.strokeStyle = Qt.rgba(controllerDelegate.trackColor.r, controllerDelegate.trackColor.g, controllerDelegate.trackColor.b, 0.3);
                    ctx.lineWidth = controllerDelegate.trackThickness;
                    ctx.stroke();

                    // 3.2 进度条 (激活)
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, currentAngle);
                    ctx.strokeStyle = controllerDelegate.progressColor;
                    ctx.lineWidth = controllerDelegate.trackThickness;
                    ctx.stroke();
                }
                
                // [关键] 统一监听 controllerDelegate 的属性变化
                Connections {
                    target: controllerDelegate
                    
                    // 通用外观
                    onTrackColorChanged: knobCanvas.requestPaint()
                    onProgressColorChanged: knobCanvas.requestPaint()
                    onTrackThicknessChanged: knobCanvas.requestPaint()
                    
                    // 旋钮特有外观
                    onKnobSizeChanged: knobCanvas.requestPaint()
                    onKnobTrackRadiusChanged: knobCanvas.requestPaint()
                    onKnobBackgroundColorChanged: knobCanvas.requestPaint()
                    onKnobBorderColorChanged: knobCanvas.requestPaint()
                    onKnobBorderWidthChanged: knobCanvas.requestPaint()
                }

                // 监听 Dial 自身的进度变化
                Connections {
                    target: dial
                    onPositionChanged: knobCanvas.requestPaint()
                    onValueChanged: knobCanvas.requestPaint() 
                }
            }

            // [Handle]
            handle: Rectangle {
                id: knobHandleRect
                // 引用 controllerDelegate 的 handleVisibility
                visible: controllerDelegate.handleVisibility === 2 || (controllerDelegate.handleVisibility === 0 && (dial.hovered || dial.pressed))
                
                width: controllerDelegate.handleSize
                height: controllerDelegate.handleSize
                radius: width / 2
                
                color: controllerDelegate.handleType === 1 ? controllerDelegate.handleColor : (dial.pressed ? "#f0f0f0" : controllerDelegate.handleColor)
                border.color: controllerDelegate.handleType === 1 ? Qt.darker(controllerDelegate.handleColor, 1.2) : controllerDelegate.handleColor
                border.width: controllerDelegate.handleType === 1 ? 1 : 2
                
                // 定位逻辑
                readonly property real centerX: dial.width / 2
                readonly property real centerY: dial.height / 2
                readonly property real angleRad: (dial.angle - 90) * Math.PI / 180
                
                // 引用 controllerDelegate.knobTrackRadius
                x: centerX + controllerDelegate.knobTrackRadius * Math.cos(angleRad) - width / 2
                y: centerY + controllerDelegate.knobTrackRadius * Math.sin(angleRad) - height / 2
                
                layer.enabled: controllerDelegate.handleType === 0
                layer.effect: RectangularGlow {
                    glowRadius: 5
                    spread: 0.2
                    color: Qt.rgba(handleColor.r, handleColor.g, handleColor.b, 0.5)
                    cornerRadius: knobHandleRect.radius
                }
            }
            
            ToolTip.visible: (hovered || pressed) && showTips
            ToolTip.text: (value/controllerDelegate.divider).toFixed(stepSize < 1 ? 2 : 0)
        }
    }

    // === 3. 开关 (Switch) ===
    Component {
        id: switchComponent
        Switch {
            id: sw
            anchors.centerIn: parent
            
            property var value: settings.defaultValue ?? 0
            
            // 判断当前值是否等于"开"的值 (允许微小误差)
            checked: {
                var vOn = controllerDelegate.valueOn;
                var current = sw.value;
                
                // 数字比较 (允许误差)
                if (typeof vOn === 'number' && typeof current === 'number') {
                    return Math.abs(current - vOn) < 0.001;
                }
                // 字符串/布尔比较
                return current == vOn; // 使用 == 允许类型转换 (如 "true" == true)
            }
            
            onToggled: {
                var targetVal = checked ? controllerDelegate.valueOn : controllerDelegate.valueOff;
                value = targetVal;
                writeValue(targetVal);
            }

            indicator: Rectangle {
                implicitWidth: handleSize * 2
                implicitHeight: handleSize
                x: sw.leftPadding
                y: parent.height / 2 - height / 2
                radius: height / 2
                color: sw.checked ? progressColor : trackColor
                border.color: sw.checked ? progressColor : "#cccccc"

                Rectangle {
                    x: sw.checked ? parent.width - width : 0
                    width: handleSize; height: handleSize
                    radius: width / 2
                    color: sw.down ? "#cccccc" : "#ffffff"
                    border.color: sw.checked ? (sw.down ? "#17a81a" : "#21be2b") : "#999999"
                    
                    Behavior on x { NumberAnimation { duration: 100 } }
                }
            }
        }
    }
}