import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import "../.."
import "../../Utils"

// Warning 这里如果在内层控件（除rippleEffectEnabled）使用 message 会导致显示 implicitHeight循环绑定 报错（警告） 不知道为什么

P.ObjectPreferenceGroup {
    id: control
    
    property var itemIn: null
    property var defaultFillStops: [{ position: 0.0, color: "#a18cd1" },{ position: 0.5, color: "#fbc2eb" }]
    syncProperties: true
    width: parent.width

    Binding {
        target: control
        property: "defaultValue"
        value: itemIn
        when: itemIn !== null && itemIn !== undefined
    }
    Binding {
        target: control
        property: "enabled"
        value: itemIn !== null && itemIn !== undefined && itemIn !== false
    }

    data: PreferenceGroupIndicator { toggle: rippleEffectEnabled }
    // --- 基础开关 ---
    P.SwitchPreference {
        id: rippleEffectEnabled
        name: "rippleEffectEnabled"
        label: qsTr("Enable Ripple Effect")
        defaultValue: false
    }
    P.SwitchPreference {
        name: "globalRippleMaskToContent"
        label: qsTr("Mask to Content")
        defaultValue: false
        visible: rippleEffectEnabled.value
    }
    
    // --- [新增] 颜色设置 ---
    P.ObjectPreferenceGroup {
        data: PreferenceGroupIndicator { toggle: rippleColorMode; level: 2 }
        defaultValue: widget.defaultSettings
        syncProperties: true
        P.SelectPreference {
            id: rippleColorMode
            name: "rippleColorMode"
            label: qsTr("Color Mode")
            model: [qsTr("Fixed Color"), qsTr("Random Color")]
            defaultValue: 0
            visible: rippleEffectEnabled.value
        }
        NoDefaultColorPreference {
            name: "rippleColor"
            label: qsTr("Fixed Color")
            defaultValue: "#40FFFFFF"
            // 只有在选择固定颜色时才显示
            visible: rippleEffectEnabled.value && rippleColorMode.value === 0
        }
    }
    SpinPreferenceEx { 
        name: "maxRadius"
        label: qsTr("Max Size (px)")
        from: 0
        to: 10000
        defaultValue: 200
        visible: rippleEffectEnabled.value
    }
    P.ObjectPreferenceGroup {
        data: PreferenceGroupIndicator { toggle: rippleShape; level: 2 }
        defaultValue: widget.defaultSettings
        syncProperties: true
        P.SelectPreference { 
            id: rippleShape
            name: "rippleShape"
            label: qsTr("Shape")
            model: [qsTr("Circle"), qsTr("Polygon")]
            defaultValue: 0
            visible: rippleEffectEnabled.value
        }
        
        // 多边形专用参数
        SpinPreferenceEx {
            name: "ripplePolygonSides"
            label: qsTr("Sides")
            from: 3
            to: 12
            defaultValue: 5
            editable: false // 原本未设 editable（默认不可手输），基类默认 true，这里覆盖以保持原行为
            visible: rippleEffectEnabled.value && rippleShape.value === 1
        }
        SliderPreferenceEx { 
            name: "rippleRotation"
            label: qsTr("Rotation")
            from: 0
            to: 360
            defaultValue: 0
            visible: rippleEffectEnabled.value && rippleShape.value === 1 && !randomizeRippleRotation.value
            displayValue: value + " °"
            stepSize: 1
        }
        P.SwitchPreference {
            id: randomizeRippleRotation
            name: "randomizeRippleRotation"
            label: qsTr("Randomize Rotation")
            defaultValue: false
            visible: rippleEffectEnabled.value && rippleShape.value === 1
        }
        SpinPreferenceEx { 
            name: "rippleRotationSpeed"
            label: qsTr("Anim Angle (°)") // 动画期间旋转的角度
            from: -3600
            to: 3600
            defaultValue: 0
            visible: rippleEffectEnabled.value && rippleShape.value === 1
            stepSize: 5
        }
    }
    // --- 样式 (实心/圆环) ---
    P.ObjectPreferenceGroup {
        data: PreferenceGroupIndicator { toggle: rippleStyle; level: 2 }
        defaultValue: widget.defaultSettings
        syncProperties: true
        P.SelectPreference { 
            id: rippleStyle
            name: "rippleStyle"
            label: qsTr("Fill Style")
            model: [qsTr("Fill (Solid)"), qsTr("Ring (Shockwave)")]
            defaultValue: 0
            visible: rippleEffectEnabled.value
        }
        SpinPreferenceEx { 
            name: "strokeWidth"
            label: qsTr("Ring Width")
            from: 0
            to: 1000
            defaultValue: 2
            visible: rippleStyle.value === 1 && rippleEffectEnabled.value
        }
    }
    P.ObjectPreferenceGroup {
        data: PreferenceGroupIndicator { toggle: rippleBurstMode; level: 2 }
        defaultValue: widget.defaultSettings
        syncProperties: true
        // --- 多重触发 (Burst Mode) ---
        P.SwitchPreference {
            id: rippleBurstMode
            name: "rippleBurstMode"
            label: qsTr("Burst Mode") // 连发/多重触发
            defaultValue: false
            visible: rippleEffectEnabled.value
        }
        // 次数
        SpinPreferenceEx {
            name: "rippleBurstCount"
            label: qsTr("Count")
            from: 1
            to: 30
            defaultValue: 3
            visible: rippleEffectEnabled.value && rippleBurstMode.value
        }
        // 间隔
        SpinPreferenceEx {
            name: "rippleBurstInterval"
            label: qsTr("Interval (ms)")
            from: 0
            to: 1000
            stepSize: 50
            defaultValue: 150
            visible: rippleEffectEnabled.value && rippleBurstMode.value
        }
    }
    // --- 动画 ---
    SpinPreferenceEx { 
        name: "duration"
        label: qsTr("Duration (ms)")
        defaultValue: 600
        from: 0
        to: 10000
        stepSize: 100
        visible: rippleEffectEnabled.value
    }
    P.SwitchPreference {
        name: "rippleShrinkMode"
        label: qsTr("Shrink") // 收缩动画
        defaultValue: false
        visible: rippleEffectEnabled.value
    }
    EasingConfigurator{
        item: widget.defaultSettings
        namePrefix: "ripple_"
        level: 2
        visible: rippleEffectEnabled.value
    }
}