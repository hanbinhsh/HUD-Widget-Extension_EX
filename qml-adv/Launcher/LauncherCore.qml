pragma Singleton
import QtQuick 2.12
import "."
import NERvGear 1.0 as NVG

QtObject {
    property NVG.View launcherView: EXLauncherView{}
    function getEXLItemView() {
        return launcherView.itemGenerator; // 访问 eXLItemView
    }
    property var vis: launcherView.isVisible
    // 启动器页面
    function toggleLauncherView() {
        if (launcherView.isVisible) {
            launcherView.isVisible = false
        } else {
            launcherView.isVisible = true
        }
    }
    function hideLauncherView() {launcherView.isVisible = false}
    function showLauncherView() {launcherView.isVisible = true}
    // 单个组件
    function toggleLauncherViewItem(i) {launcherView.toggleItem(i)}
    function hideLauncherViewItem(i) {launcherView.showItem(i)}
    function showLauncherViewItem(i) {launcherView.hideItem(i)}
    // 开关设置
    function toggleLauncherSetting() {launcherView.toggleSetting()}
}
