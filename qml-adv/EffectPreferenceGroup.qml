import QtQuick 2.12
import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

// 可复用的"单个图形特效"偏好分组外壳。
// 封装了原本在每个特效分组里被反复抄写的样板：
//   defaultValue / syncProperties / width / enabled + 启用开关 + 左侧指示条。
// 用法：
//   EffectPreferenceGroup {
//       id: glowGroup
//       settingsTarget: thiz.settings
//       groupEnabled: currentItem
//       switchName: "enableGlow"; switchLabel: qsTr("Glow")
//       // 后续参数项作为默认子项追加（会接在启用开关之后）
//       EffectSpinPreference { owner: glowGroup; name: "glowRadius"; ... }
//   }
// 子项通过 `owner: <thisGroupId>` 绑定到本组的启用状态（group.switchValue）。
P.ObjectPreferenceGroup {
    id: group

    // 本组读写的设置表（通常为 thiz.settings）。
    // 必须用 SettingsMap 类型而非 var：var 在调用方绑定生效前为 undefined，
    // 会让 defaultValue 短暂变 undefined，触发 group.js 的
    // "Cannot assign [undefined] to QObject*" 警告；用 QObject 类型时默认值是 null（合法）。
    property NVG.SettingsMap settingsTarget
    // 启用开关
    property string switchName
    property string switchLabel
    property bool switchDefault: false
    // 对应原来的 `enabled: currentItem`，由外层传入
    property var groupEnabled: true
    // 暴露开关状态，供子参数项 `owner: group` -> group.switchValue 使用。
    // 注意：不能命名为 `value`——NERvGear 分组加载器会把带 `value` 的子项
    // 误判为"叶子偏好"，导致给只读 value 赋值报错且不再递归同步组内子项。
    readonly property alias switchValue: enableSwitch.value
    // 暴露开关高度，便于个别场景自定义指示条
    readonly property alias switchHeight: enableSwitch.height

    syncProperties: true
    width: parent.width
    defaultValue: settingsTarget
    enabled: groupEnabled

    // 指示条放进 data（与内容列表分离，仅作左侧装饰）
    data: PreferenceGroupIndicator { toggle: enableSwitch }

    // 启用开关作为内容列表的第一项；调用方追加的子项会接在其后
    P.SwitchPreference {
        id: enableSwitch
        name: group.switchName
        label: group.switchLabel
        defaultValue: group.switchDefault
    }
    // 统一的特效图层透明度（0~100%）。键名固定为 <switchName>Opacity，
    // 渲染侧 ImageEffectStack 对每个特效按 (settings.<switchName>Opacity ?? 100)/100 应用。
    // 默认 100% 不改变原观感；调低则让该特效与下方图层/原图混合而非完全覆盖。
    EffectSliderPreference {
        owner: group
        name: group.switchName + "Opacity"
        label: qsTr("Opacity")
        defaultValue: 100
        from: 0
        to: 100
        displayValue: value + " %"
    }
}
