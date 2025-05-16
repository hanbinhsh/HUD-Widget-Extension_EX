import QtQuick 2.12
import QtQuick.Controls 2.12
import NERvGear 1.0 as NVG

import "../impl" as Impl

Item {
    id: selector

    property CraftItem view
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

    Row{
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.right: parent.right
        ToolButton {
            enabled: currentItem
            icon.name: "regular:\uf044"
            onClicked: {
                editor.active = true;
                editor.item.targetItem = eXLItemView.currentTarget;
                // editor.item.targetData = eXLItemView.currentTarget.defaultData;
                // editor.item.targetText = eXLItemView.currentTarget.defaultText;
                const settings = Impl.Settings.duplicateMap(currentItem, eXLItemView.model);
                editor.item.targetSettings = settings;
                editor.item.craftSettings = NVG.Settings.makeMap(settings, "craft");
                editor.item.show();
            }
        }
        ToolButton {
            icon.name: "regular:\uf03a"
            onClicked: selectMenu.popup()
        }
    }
    
}