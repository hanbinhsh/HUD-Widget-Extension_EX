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

    // 除数
    readonly property real divider: settings.divider ?? 1

    // 样式选择: 0=Slider, 1=Knob, 2=Switch
    readonly property int sliderStyle: settings.sliderStyle ?? 0

    // 滑块/旋钮外观
    readonly property int handleType: settings.handleType ?? 0 // 0=Glow, 1=Solid
    readonly property real handleSize: settings.handleSize ?? 16
    readonly property int handleVisibility: settings.handleVisibility ?? 2 // 0=Hover, 1=None, 2=Always
    readonly property color handleColor: settings.handleColor ?? "#FFFFFF"
    
    // 轨道/刻度
    readonly property color trackColor: settings.trackColor ?? "#40FFFFFF"
    readonly property color progressColor: settings.progressColor ?? "#00AAFF"
    readonly property int trackThickness: settings.trackThickness ?? 4
    
    readonly property bool showTicks: settings.showTicks ?? false
    readonly property int tickCount: settings.tickCount ?? 5
    readonly property color tickColor: settings.tickColor ?? "#88FFFFFF"
    readonly property int tickSize: settings.tickSize ?? 4

    // 旋钮特有
    readonly property real knobSize: settings.knobSize ?? 60
    readonly property bool knobShowIndicator: settings.knobShowIndicator ?? true
    readonly property real knobTrackRadius: settings.knobTrackRadius ?? 24
    readonly property color knobBorderColor: settings.knobBorderColor ?? "#00AAFF"

    // --- 内部逻辑变量 ---
    readonly property int controlTarget: settings.controlTarget ?? 0
    readonly property int itemIndex_ex: settings.itemIndex_ex ?? 0
    readonly property int itemIndex_hud: settings.itemIndex_hud ?? 0
    readonly property bool controlParent: settings.controlParent ?? false
    readonly property int itemIndex_child: settings.itemIndex_child ?? 0
    readonly property int selectedPropertyIndex: settings.selectedPropertyIndex ?? 0

    // --- 动态属性刷新逻辑 ---
    property var _target_properties: getTargetProperties();
    property var _items_child: getHUDChildItems();
    property var _items_hud: getHUDItems();
    property var _items_ex: getEXLItems();

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
            console.log("Slider: Target switched, reset to", settings.targetKey);
        } else {
            settings.selectedPropertyIndex = 0;
            settings.targetKey = "";
        }
        _isSwitchingTarget = false;
    }

    function getSettingItems() {
        _target_properties = getTargetProperties();
        _items_child = getHUDChildItems();
        _items_hud = getHUDItems();
        _items_ex = getEXLItems();
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
                    console.log("Slider: Syncing index to", i, "for key", currentKey);
                    settings.selectedPropertyIndex = i;
                }
                _isUpdatingIndex = false;
                return;
            }
        }
        
        // 如果找不到（比如目标改变了），重置为第一项
        console.warn("Slider: targetKey '" + currentKey + "' not found, resetting");
        if (_target_properties.length > 0) {
            settings.selectedPropertyIndex = 0;
            settings.targetKey = _target_properties[0].toString();
        }
        
        _isUpdatingIndex = false;
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
                console.log("Slider: User selected property", newKey);
                settings.targetKey = newKey;
            }
        }
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
            visible: _target_properties.length > 0
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
        }
        P.SpinPreference {
            name: "maxValue"
            label: qsTr("Max Value")
            defaultValue: 100
            from: -99999
            to: 99999
            editable: true
            display: P.TextFieldPreference.ExpandLabel
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
        
        P.Separator {}

        // 滑块特有
        P.ObjectPreferenceGroup {
            visible: pStyle.value === 0
            defaultValue: sliderDelegate.settings
            syncProperties: true
            P.SelectPreference {
                name: "handleType"
                label: qsTr("Handle Style")
                model: [qsTr("Glow Ring"), qsTr("Solid Circle")]
                defaultValue: 0
            }
            P.SelectPreference {
                name: "handleVisibility"
                label: qsTr("Handle Visibility")
                model: [qsTr("Hover Only"), qsTr("None"), qsTr("Always")]
                defaultValue: 2
            }
            NoDefaultColorPreference {
                name: "handleColor";
                label: qsTr("Handle Color");
                defaultValue: "#FFFFFF"
            }
            P.SpinPreference {
                name: "trackThickness";
                label: qsTr("Track Height");
                defaultValue: 4;
                from: 1;
                to: 50
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
            defaultValue: sliderDelegate.settings
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
            // Handle 样式
            P.SelectPreference {
                name: "handleType"
                label: qsTr("Handle Style")
                model: [qsTr("Glow Ring"), qsTr("Solid Circle")]
                defaultValue: 0
            }
            P.SelectPreference {
                name: "handleVisibility"
                label: qsTr("Handle Visibility")
                model: [qsTr("Hover Only"), qsTr("None"), qsTr("Always")]
                defaultValue: 2
            }
            NoDefaultColorPreference {
                name: "handleColor"
                label: qsTr("Handle Color")
                defaultValue: "#FFFFFF"
            }
        }
    }

    // --- 逻辑实现 ---

    function getRawTargetMap() {
        if (sliderDelegate.controlTarget === 0) { // HUD Element
            var hudModel = widget.getHUDItemView();
            if (hudModel && itemIndex_hud >= 0 && itemIndex_hud < hudModel.count) {
                var parentData = hudModel.get(itemIndex_hud);
                if (sliderDelegate.controlParent) {
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
        }
        // 如果需要支持 EXL，在这里添加逻辑
        return null; 
    }

    function setDeepValue(root, path, value) {
        if (!root || !path) return;
        var parts = path.split('.');
        var current = root;
        
        // 遍历到倒数第二个节点
        for (var i = 0; i < parts.length - 1; i++) {
            var key = parts[i];
            if (current[key] === undefined) {
                // 如果路径不存在，通常不应该创建，直接返回
                console.warn("Slider: Path not found:", path);
                return;
            }
            current = current[key];
        }
        
        // 设置最后一个节点的值
        var lastKey = parts[parts.length - 1];
        // 应用除数逻辑：写入值 = 滑块值 / 除数
        var finalValue = value / divider;
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
        var map = getRawTargetMap(); // 获取根对象
        
        // 1. 尝试深度读取
        if (map && targetKey) {
            val = getDeepValue(map, targetKey);
        }

        // 2. 如果没找到，尝试全局
        if (val === undefined && targetKey) {
            val = getDeepValue(widget.settings, targetKey);
        }

        // 3. 默认值
        if (val === undefined) {
            val = settings.defaultValue ?? 50;
        }

        // 读取值 = 存储值 * 除数 (还原到滑块范围)
        return Number(val) * divider;
    }

    // 初始化默认值
    Component.onCompleted: {
        _isInitializing = true;
        
        Qt.callLater(function(){
            // 先获取所有项目
            getSettingItems();
            
            // 等待一帧确保设置加载完成
            Qt.callLater(function(){
                // 同步索引
                syncPropertyIndex();
                
                // 加载保存的值
                var savedVal = getStoredValue();
                if (loader.item) loader.item.value = savedVal;
                
                _isInitializing = false;
                console.log("Slider: Initialization complete, targetKey=", settings.targetKey);
            });
        });
    }

    function writeValue(val) {
        if (!targetKey) return;
        var targetMap = getRawTargetMap();
        if (targetMap) setDeepValue(targetMap, targetKey, val);
        else setDeepValue(widget.settings, targetKey, val);
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
            stepSize: sliderDelegate.stepSize
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
                border.color: handleType === 1 ? Qt.darker(handleColor, 1.2) : progressColor
                border.width: handleType === 1 ? 1 : 2
                
                // 发光效果 (仅 Type 0)
                layer.enabled: handleType === 0
                layer.effect: RectangularGlow {
                    glowRadius: 5
                    spread: 0.2
                    color: Qt.rgba(progressColor.r, progressColor.g, progressColor.b, 0.5)
                    cornerRadius: handleRect.radius
                }
            }
            
            ToolTip.visible: hovered || pressed
            ToolTip.text: (value/divider).toFixed(stepSize < 1 ? 2 : 0)
        }
    }

    // === 2. 旋钮 (Knob) ===
    Component {
        id: knobComponent
        Dial {
            id: dial
            
            // [关键修改 1] 尺寸不再依赖 parent (挂件)，而是完全由设置决定
            // 这对应了你给出的参考代码中的 Circle Graph 逻辑
            width: knobSize
            height: knobSize
            
            // [关键修改 2] 始终居中于挂件。如果挂件被拉大，旋钮保持原大小居中
            anchors.centerIn: parent
            
            // 轨道半径
            readonly property real trackRadius: settings.knobTrackRadius ?? 24
            // [新增] 属性读取
            readonly property color bgColor: settings.knobBackgroundColor ?? "#40000000"
            readonly property real borderWidth: settings.knobBorderWidth ?? 1
            
            from: minValue
            to: maxValue
            stepSize: sliderDelegate.stepSize
            value: settings.defaultValue ?? 50

            onMoved: writeValue(value)

            // 背景层 (圆盘主体)
            background: Rectangle {
                // 填满 Dial (即填满 knobSize)
                anchors.fill: parent
                radius: width / 2
                
                // [修改] 使用独立的背景色，不混用 trackColor
                color: dial.bgColor
                
                // [修改] 边框设置
                border.color: knobBorderColor
                border.width: dial.borderWidth
                
                // Canvas 仅用于绘制轨道条 (Track) 和 进度条 (Progress)
                Canvas {
                    id: knobCanvas
                    anchors.fill: parent
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = dial.trackRadius;
                        
                        // 角度定义: 135度 ~ 405度
                        var startAngle = Math.PI * 0.75;
                        var endAngle = Math.PI * 2.25;
                        
                        // 计算进度
                        var valuePos = (dial.value - dial.from) / (dial.to - dial.from);
                        valuePos = Math.max(0, Math.min(1, valuePos));
                        var currentAngle = startAngle + (valuePos * (endAngle - startAngle));
                        
                        ctx.lineCap = "round";

                        // 1. 绘制轨道 (Track) - 未激活部分
                        // [修改] 使用 trackColor 绘制线条，而不是背景填充
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, startAngle, endAngle);
                        ctx.strokeStyle = trackColor; 
                        ctx.lineWidth = trackThickness;
                        ctx.stroke();

                        // 2. 绘制进度 (Progress) - 激活部分
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, startAngle, currentAngle);
                        ctx.strokeStyle = progressColor;
                        ctx.lineWidth = trackThickness;
                        ctx.stroke();
                    }
                    
                    // 信号连接
                    Connections {
                        target: sliderDelegate
                        onTrackThicknessChanged: knobCanvas.requestPaint()
                        onProgressColorChanged: knobCanvas.requestPaint()
                        onTrackColorChanged: knobCanvas.requestPaint()
                    }
                    Connections {
                        target: settings
                        onKnobTrackRadiusChanged: knobCanvas.requestPaint()
                        // [新增] 监听新增的属性变化
                        onKnobBackgroundColorChanged: knobCanvas.requestPaint() 
                    }
                    Connections {
                        target: dial
                        onPositionChanged: knobCanvas.requestPaint()
                        onValueChanged: knobCanvas.requestPaint() 
                    }
                }
            }

            // Handle (保持之前的三角函数定位逻辑，非常稳定)
            handle: Rectangle {
                id: knobHandleRect
                visible: handleVisibility === 2 || (handleVisibility === 0 && (dial.hovered || dial.pressed))
                
                width: handleSize
                height: handleSize
                radius: width / 2
                
                color: handleType === 1 ? handleColor : (dial.pressed ? "#f0f0f0" : handleColor)
                border.color: handleType === 1 ? Qt.darker(handleColor, 1.2) : progressColor
                border.width: handleType === 1 ? 1 : 2
                
                // 定位逻辑
                readonly property real centerX: dial.width / 2
                readonly property real centerY: dial.height / 2
                readonly property real angleRad: (dial.angle - 90) * Math.PI / 180
                
                x: centerX + dial.trackRadius * Math.cos(angleRad) - width / 2
                y: centerY + dial.trackRadius * Math.sin(angleRad) - height / 2
                
                layer.enabled: handleType === 0
                layer.effect: RectangularGlow {
                    glowRadius: 5
                    spread: 0.2
                    color: Qt.rgba(progressColor.r, progressColor.g, progressColor.b, 0.5)
                    cornerRadius: knobHandleRect.radius
                }
            }
            
            ToolTip.visible: hovered || pressed
            ToolTip.text: (value/divider).toFixed(stepSize < 1 ? 2 : 0)
        }
    }

    // === 3. 开关 (Switch) ===
    Component {
        id: switchComponent
        Switch {
            id: sw
            anchors.centerIn: parent
            
            // [关键修复] 添加 value 属性以避免报错
            property real value: 0
            
            // 双向绑定
            checked: value > 0
            
            onToggled: {
                var newVal = checked ? 1 : 0;
                value = newVal;
                writeValue(newVal);
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