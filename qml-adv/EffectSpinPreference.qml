import QtQuick 2.12

// 特效数值参数（半径/采样数/偏差/偏移/长度/角度等）的包装。
// 在通用 SpinPreferenceEx（烘焙 editable / display / stepSize）基础上，
// 增加按所属分组的启用状态自动显隐。
// 用法：EffectSpinPreference { owner: glowGroup; name: "glowRadius"; label: qsTr("Radius"); from: 0; to: 500; defaultValue: 5 }
SpinPreferenceEx {
    // 所属 EffectPreferenceGroup，用于联动显隐；为空时恒显示
    property var owner: null

    visible: owner ? owner.switchValue : true
}
