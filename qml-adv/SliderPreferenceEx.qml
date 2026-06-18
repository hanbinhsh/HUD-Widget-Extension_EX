import QtQuick 2.12
import NERvGear.Preferences 1.0 as P

// 通用滑块：烘焙各层逐项重复的 live / displayValue / stepSize 样式。
// 与原先手写的 `P.SliderPreference { live: true; displayValue: value; stepSize: 1; ... }` 等价。
// displayValue 默认显示原始值；需换算显示（如 value + " °"）时在调用处覆盖即可。
// 用法：SliderPreferenceEx { name; label; from; to; defaultValue; visible }
P.SliderPreference {
    live: true
    displayValue: value
    stepSize: 1
}
