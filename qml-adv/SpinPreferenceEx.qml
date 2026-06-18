import QtQuick 2.12
import NERvGear.Preferences 1.0 as P

// 通用数值框：烘焙各层逐项重复的 editable / display / stepSize 样式。
// 与原先手写的 `P.SpinPreference { editable: true; display: P.TextFieldPreference.ExpandLabel; ... }` 等价。
// 用法：SpinPreferenceEx { name; label; from; to; defaultValue; stepSize; visible }
P.SpinPreference {
    editable: true
    display: P.TextFieldPreference.ExpandLabel
    stepSize: 1
}
