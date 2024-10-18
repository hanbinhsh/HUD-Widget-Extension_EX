import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.2
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG
import NERvGear.Templates 1.0 as T

NVG.View {
    id: exLauncherView
    property bool isVisible: false  // 用于接收外部的 visible 状态
    opacity: 0.0  // 初始 opacity 为 0
    z: 0

    width: Screen.width
    height: Screen.height

    y: 0
    x: 0

    color: "#777777"

    // 通过 Behavior 动态修改 opacity 的值，进行动画
    Behavior on opacity {
        NumberAnimation {
            duration: 300  // 动画持续时间，300毫秒
            easing.type: Easing.InOutQuad  // 缓动效果
        }
    }

    // 当 isVisible 改变时触发动画
    onIsVisibleChanged: {
        if (isVisible) {
            exLauncherView.visible = true  // 仅当需要显示时将 visible 设为 true
            exLauncherView.opacity = 1.0   // 动画淡入
        } else {
            exLauncherView.opacity = 0.0   // 动画淡出
        }
    }

    // 使用一个定时器，当 opacity 完全变为 0 时，自动将 visible 设为 false
    SequentialAnimation {
        id: hideAnimation
        running: false
        NumberAnimation { target: exLauncherView; property: "opacity"; to: 0; duration: 300 }
        ScriptAction {
            script: {
                exLauncherView.visible = false  // 当动画完成时隐藏组件
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (mouse.button === Qt.LeftButton) {
                isVisible = false  // 左键单击隐藏视图
                hideAnimation.start()  // 开始隐藏动画
            }
        }
    }
}

