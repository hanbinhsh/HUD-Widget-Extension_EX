pragma Singleton
import QtQuick 2.12
import "."

QtObject {
    Component.onCompleted: {}
    // 暴露 EXLauncherView 的实例
    property var launcherView: EXLauncherView{}
    property var vis: launcherView.isVisible

    // 提供控制方法来显示和隐藏 EXLauncherView
    function toggleLauncherView() {
        if (launcherView.isVisible) {
            launcherView.isVisible = false
        } else {
            launcherView.isVisible = true
        }
    }

    function toggleLauncherSetting() {
        launcherView.toggleSetting()
    }
}
