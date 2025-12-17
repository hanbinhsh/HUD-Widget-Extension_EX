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

    data: PreferenceGroupIndicator { anchors.topMargin: rippleEffectEnabled.height; visible: rippleEffectEnabled.value }
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
        data: PreferenceGroupIndicator { anchors.topMargin: rippleColorMode.height; visible: rippleColorMode.value; color: "#662196f3"; anchors.leftMargin: 4 }
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
    P.SpinPreference { 
        name: "maxRadius"
        label: qsTr("Max Size (px)")
        from: 0
        to: 10000
        defaultValue: 200
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: rippleEffectEnabled.value
    }
    P.ObjectPreferenceGroup {
        data: PreferenceGroupIndicator { anchors.topMargin: rippleShape.height; visible: rippleShape.value; color: "#662196f3"; anchors.leftMargin: 4 }
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
        P.SpinPreference { 
            name: "ripplePolygonSides"
            label: qsTr("Sides")
            from: 3
            to: 12
            defaultValue: 5
            visible: rippleEffectEnabled.value && rippleShape.value === 1
            display: P.TextFieldPreference.ExpandLabel
        }
        P.SliderPreference { 
            name: "rippleRotation"
            label: qsTr("Rotation")
            from: 0
            to: 360
            defaultValue: 0
            visible: rippleEffectEnabled.value && rippleShape.value === 1 && !randomizeRippleRotation.value
            displayValue: value + " °"
            live: true
            stepSize: 1
        }
        P.SwitchPreference {
            id: randomizeRippleRotation
            name: "randomizeRippleRotation"
            label: qsTr("Randomize Rotation")
            defaultValue: false
            visible: rippleEffectEnabled.value && rippleShape.value === 1
        }
        P.SpinPreference { 
            name: "rippleRotationSpeed"
            label: qsTr("Anim Angle (°)") // 动画期间旋转的角度
            from: -3600
            to: 3600
            defaultValue: 0
            editable: true
            visible: rippleEffectEnabled.value && rippleShape.value === 1
            stepSize: 5
            display: P.TextFieldPreference.ExpandLabel
        }
    }
    // --- 样式 (实心/圆环) ---
    P.ObjectPreferenceGroup {
        data: PreferenceGroupIndicator { anchors.topMargin: rippleStyle.height; visible: rippleStyle.value; color: "#662196f3"; anchors.leftMargin: 4 }
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
        P.SpinPreference { 
            name: "strokeWidth"
            label: qsTr("Ring Width")
            editable: true
            from: 0
            to: 1000
            defaultValue: 2
            visible: rippleStyle.value === 1 && rippleEffectEnabled.value
            display: P.TextFieldPreference.ExpandLabel
        }
    }
    P.ObjectPreferenceGroup {
        data: PreferenceGroupIndicator { anchors.topMargin: rippleBurstMode.height; visible: rippleBurstMode.value; color: "#662196f3"; anchors.leftMargin: 4 }
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
        P.SpinPreference {
            name: "rippleBurstCount"
            label: qsTr("Count")
            from: 1
            to: 30
            defaultValue: 3
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: rippleEffectEnabled.value && rippleBurstMode.value
        }
        // 间隔
        P.SpinPreference {
            name: "rippleBurstInterval"
            label: qsTr("Interval (ms)")
            from: 0
            to: 1000
            stepSize: 50
            defaultValue: 150
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: rippleEffectEnabled.value && rippleBurstMode.value
        }
    }
    // --- 动画 ---
    P.SpinPreference { 
        name: "duration"
        label: qsTr("Duration (ms)")
        defaultValue: 600
        from: 0
        to: 10000
        stepSize: 100
        editable: true
        display: P.TextFieldPreference.ExpandLabel
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