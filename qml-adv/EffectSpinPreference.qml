import QtQuick 2.12
import NERvGear.Preferences 1.0 as P

// 特效数值参数（半径/采样数/偏差/偏移/长度/角度等）的通用包装。
// 烘焙了原本逐项重复的样式：editable / display / stepSize，
// 并按所属分组的启用状态自动显隐。
// 用法：EffectSpinPreference { owner: glowGroup; name: "glowRadius"; label: qsTr("Radius"); from: 0; to: 500; defaultValue: 5 }
P.SpinPreference {
    // 所属 EffectPreferenceGroup，用于联动显隐；为空时恒显示
    property var owner: null

    editable: true
    display: P.TextFieldPreference.ExpandLabel
    stepSize: 1
    visible: owner ? owner.switchValue : true
}
