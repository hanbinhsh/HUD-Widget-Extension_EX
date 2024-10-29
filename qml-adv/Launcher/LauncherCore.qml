pragma Singleton
import QtQuick 2.12
import "."

QtObject {
    //Component.onCompleted: {}
    property var launcherView: EXLauncherView{}
    property var vis: launcherView.isVisible

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
