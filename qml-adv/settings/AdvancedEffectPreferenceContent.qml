import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

// 「高级特效」编辑内容（主开关 + 完整特效面板），不含滚动外壳，适合直接放进 Column 流式布局
// （如 EditDialog 的 Widget Settings）。需要滚动外壳的标签页场景见 AdvancedEffectPreferenceGroup。
// 参数 item = 拥有该特效的设置表（widget.defaultSettings / currentItem / currentElement）。
// 首次启用时按 NVG.Settings.createMap 在 item 上建 advancedEffect 子表。
Column {
    property var item: null

    id: content
    width: parent ? parent.width : 0

    P.ObjectPreferenceGroup {
        syncProperties: true
        enabled: content.item
        width: parent.width
        defaultValue: content.item ? (content.item.advancedEffect ?? null) : null
        //主开关：启用高级特效
        P.SwitchPreference {
            id: pAdvEffect
            name: "enabled"
            label: qsTr("Enable Advanced Effects")
            onPreferenceEdited: {
                if (content.item && !content.item.advancedEffect) {
                    const map = NVG.Settings.createMap(content.item);
                    map.enabled = value;
                    content.item.advancedEffect = map;
                }
            }
        }
    }
    //完整特效面板（颜色/特效/混合遮罩/渐变）
    EffectPreferencePanel {
        width: parent.width
        visible: pAdvEffect.value
        settingsTarget: content.item ? (content.item.advancedEffect ?? null) : null
        groupEnabled: content.item
    }
}
