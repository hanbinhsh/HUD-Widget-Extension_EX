import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import "../"

// 统一缓动效果配置组件
P.ObjectPreferenceGroup {
    id: root

    // --- 公共属性 ---
    // 设置项的前缀，例如 "moveData_", 最终属性名为 "moveData_EasingType"
    property string namePrefix: "" 
    // 数据源对象 (通常是 item 或 settings)
    property var item: null
    property var level: 1 // 作用层级，默认 1 表示第一层

    syncProperties: true
    width: parent.width

    Binding {
        target: root
        property: "defaultValue"
        value: item
        when: item !== null && item !== undefined
    }
    Binding {
        target: root
        property: "enabled"
        value: item !== null && item !== undefined && item !== false
    }

    data: PreferenceGroupIndicator { 
        anchors.topMargin: pEasingType.height
        visible: pEasingType.value
        color: level == 1 ? "#4a4a4a" : (level == 2 ? "#662196f3" : "#66f48fb1")
        anchors.leftMargin: (level - 1) * 4
    }

    // 缓动类型模型
    readonly property var easingModel: [
        qsTr("Linear"), // 0
        qsTr("InQuad"), qsTr("OutQuad"), qsTr("InOutQuad"), qsTr("OutInQuad"), // 1-4
        qsTr("InCubic"), qsTr("OutCubic"), qsTr("InOutCubic"), qsTr("OutInCubic"), // 5-8
        qsTr("InQuart"), qsTr("OutQuart"), qsTr("InOutQuart"), qsTr("OutInQuart"), // 9-12
        qsTr("InQuint"), qsTr("OutQuint"), qsTr("InOutQuint"), qsTr("OutInQuint"), // 13-16
        qsTr("InSine"), qsTr("OutSine"), qsTr("InOutSine"), qsTr("OutInSine"), // 17-20
        qsTr("InExpo"), qsTr("OutExpo"), qsTr("InOutExpo"), qsTr("OutInExpo"), // 21-24
        qsTr("InCirc"), qsTr("OutCirc"), qsTr("InOutCirc"), qsTr("OutInCirc"), // 25-28
        qsTr("InElastic"), qsTr("OutElastic"), qsTr("InOutElastic"), qsTr("OutInElastic"), // 29-32
        qsTr("InBack"), qsTr("OutBack"), qsTr("InOutBack"), qsTr("OutInBack"), // 33-36
        qsTr("InBounce"), qsTr("OutBounce"), qsTr("InOutBounce"), qsTr("OutInBounce"), // 37-40
        qsTr("BezierSpline") // 41
    ]

    // --- 逻辑判断 ---
    readonly property int et: pEasingType.value
    // Type 28-32 (Elastic) & 36-40 (Bounce)
    readonly property bool hasAmplitude: (et >= 28 && et <= 32) || (et >= 37 && et <= 40)
    // Type 28-32 (Elastic)
    readonly property bool hasPeriod: (et >= 28 && et <= 32)
    // Type 33-36 (Back)
    readonly property bool hasOvershoot: (et >= 33 && et <= 36)
    // Type 41 (Bezier)
    readonly property bool isBezier: (et === 41)

    // --- 1. 缓动类型选择 ---
    P.SelectPreference {
        id: pEasingType
        name: root.namePrefix + "easingType"
        label: qsTr("Easing Type")
        defaultValue: 1 // InQuad
        model: root.easingModel
    }

    // --- 2. 动态参数 (Amplitude) ---
    // 适用于 Bounce 和 Elastic
    P.SpinPreference {
        name: root.namePrefix + "easingAmplitude"
        label: qsTr("Amplitude")
        defaultValue: 100 // 建议默认值设大一点如果逻辑里除了100，或者是 1
        from: -99999
        to: 99999
        stepSize: 1
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: root.hasAmplitude
    }

    // --- 3. 动态参数 (Overshoot) ---
    // 适用于 Back
    P.SpinPreference {
        name: root.namePrefix + "easingOvershoot"
        label: qsTr("Overshoot")
        defaultValue: 170 // 对应 1.70158
        from: -99999
        to: 99999
        stepSize: 1
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: root.hasOvershoot
    }

    // --- 4. 动态参数 (Period) ---
    // 适用于 Elastic
    P.SpinPreference {
        name: root.namePrefix + "easingPeriod"
        label: qsTr("Period")
        defaultValue: 30 // 对应 0.3
        from: -99999
        to: 99999
        stepSize: 1
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: root.hasPeriod
    }

    // --- 5. 贝塞尔曲线参数 (Bezier) ---
    // 仅在选择 BezierSpline 时显示
    // 注意：这里存储的值是整数百分比 (例如 25 代表 0.25)
    // 在使用时需要除以 100.0
    
    // 控制点 1 X
    P.SpinPreference {
        name: root.namePrefix + "bezierX1"
        label: qsTr("Control P1 X (%)")
        defaultValue: 25 // 0.25
        from: -500 // 允许稍微超出范围以实现特殊效果
        to: 500
        stepSize: 1
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: root.isBezier
    }

    // 控制点 1 Y
    P.SpinPreference {
        name: root.namePrefix + "bezierY1"
        label: qsTr("Control P1 Y (%)")
        defaultValue: 10 // 0.1
        from: -500
        to: 500
        stepSize: 1
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: root.isBezier
    }

    // 控制点 2 X
    P.SpinPreference {
        name: root.namePrefix + "bezierX2"
        label: qsTr("Control P2 X (%)")
        defaultValue: 25 // 0.25
        from: -500
        to: 500
        stepSize: 1
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: root.isBezier
    }

    // 控制点 2 Y
    P.SpinPreference {
        name: root.namePrefix + "bezierY2"
        label: qsTr("Control P2 Y (%)")
        defaultValue: 100 // 1.0
        from: -500
        to: 500
        stepSize: 1
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: root.isBezier
    }
}