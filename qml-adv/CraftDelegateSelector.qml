import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: selector

    property CraftView view
    property var extractLabel

    height: 1
    z: 10

    Menu {
        id: selectMenu

        Repeater {
            model: selector.view.count
            delegate: MenuItem {
                readonly property Item target: selector.view.targetAt(index)

                autoExclusive: true
                checkable: true
                checked: target === selector.view.currentTarget
                text: selector.extractLabel(target, index)

                onClicked: selector.view.currentTarget = target
            }
        }
    }
//编辑界面>物品设置右边的图标
    ToolButton {
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.right: parent.right
        icon.name: "regular:\uf03a"
        onClicked: selectMenu.popup()
    }
}

