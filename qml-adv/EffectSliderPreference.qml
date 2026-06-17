import QtQuick 2.12
import NERvGear.Preferences 1.0 as P

// 特效滑块参数（亮度/对比度/色相/饱和度/伽马等）的通用包装。
// 烘焙了原本逐项重复的样式：live / displayValue / stepSize，
// 并按所属分组的启用状态自动显隐。
// displayValue 默认显示原始值；需要换算显示（如 value/100）时可在调用处覆盖。
// 用法：EffectSliderPreference { owner: bcGroup; name: "brightness"; label: qsTr("Brightness"); from: -100; to: 100; defaultValue: 0 }
P.SliderPreference {
    // 所属 EffectPreferenceGroup，用于联动显隐；为空时恒显示
    property var owner: null

    live: true
    displayValue: value
    stepSize: 1
    visible: owner ? owner.switchValue : true
}
