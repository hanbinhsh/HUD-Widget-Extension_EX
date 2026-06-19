import QtQuick 2.12

// 「高级特效」编辑组：在 AdvancedEffectPreferenceContent 外加滚动外壳（Flickable），
// 供标签页/StackLayout 场景使用（CraftDialog 元素层、EditDialog 物品层 Others→Advanced）。
// 与各 settings/*PreferenceGroup 一致，根为 Flickable，宿主用 contentHeight 计算高度。
// 参数 item = 拥有该特效的设置表（currentElement / currentItem）。
Flickable {
    property alias item: content.item

    id: root
    anchors.fill: parent
    contentWidth: width
    contentHeight: content.height
    topMargin: 16
    bottomMargin: 16

    AdvancedEffectPreferenceContent {
        id: content
        width: root.width
    }
}
