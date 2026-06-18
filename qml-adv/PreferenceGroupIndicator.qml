import QtQuick 2.12

import NERvGear.Controls 1.0

// 折叠组左侧的竖条指示。
// 烘焙了各处重复的两段样板：
//   1) 关联折叠开关：设置 `toggle` 后自动 topMargin = toggle.height、visible = toggle.value；
//   2) 嵌套层级配色/缩进：`level` 1=顶层(主题色) / 2=蓝(缩进4) / 3=粉(缩进8)。
// 用法：PreferenceGroupIndicator { toggle: enableX }            // 顶层
//       PreferenceGroupIndicator { toggle: enableX; level: 2 }   // 子级
//       PreferenceGroupIndicator { toggle: enableX; color: "#4a4a4a" } // 自定义色（覆盖 level 配色）
Rectangle {
    // 关联的折叠开关；为空时恒显示、不下移
    property var toggle: null
    // 嵌套层级，决定默认配色与左缩进
    property int level: 1

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 4
    anchors.topMargin: toggle ? toggle.height : 0
    anchors.leftMargin: level >= 3 ? 8 : (level === 2 ? 4 : 0)
    visible: toggle ? toggle.value : true
    color: level === 2 ? "#662196f3" : (level >= 3 ? "#66f48fb1" : dialog.Style.rippleColor)
}
