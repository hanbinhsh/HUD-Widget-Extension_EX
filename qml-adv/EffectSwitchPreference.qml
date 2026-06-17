import QtQuick 2.12
import NERvGear.Preferences 1.0 as P

// 特效布尔开关（透明边框 / 缓存 / 快速算法等）的通用包装。
// 按所属分组的启用状态自动显隐。
// 用法：EffectSwitchPreference { owner: glowGroup; name: "glowCache"; label: qsTr("Cached") }
P.SwitchPreference {
    // 所属 EffectPreferenceGroup，用于联动显隐；为空时恒显示
    property var owner: null

    visible: owner ? owner.switchValue : true
}
