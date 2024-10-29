import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0
import NERvGear.Templates 1.0 as T
import "."
import QtQuick 2.12
import QtQuick.Controls 2.12

T.Action {
    id: thiz
    property var itemIdx: configuration?.itemIndex || 0
    readonly property var _actions: [
        { command: "show", label: qsTr("Show EX Launcher"), execute: widget.showEXL },
        { command: "hide", label: qsTr("Hide EX Launcher"), execute: widget.hideEXL },
        { command: "toggle", label: qsTr("Toggle EX Launcher"), execute: widget.toggleEXL },
        { command: "itemShow", label: qsTr("Show Item"), execute: function() { widget.showEXLItem(itemIdx) }},
        { command: "itemHide", label: qsTr("Hide Item"), execute: function() { widget.hideEXLItem(itemIdx) }},
        { command: "itemToggle", label: qsTr("Toggle Item"), execute: function() { widget.toggleEXLItem(itemIdx) }},
    ]

    property var _items: {
        var itemView = LauncherCore.getEXLItemView();
        var labels = [];
        if (itemView) {
            for (var i = 0; i < itemView.count; i++) {
                labels.push(itemView.targetAt(i).settings.label || qsTr("Item") + " " + (i + 1));
            }
        }
        return labels;
    }

    title: qsTr("EX Launcher Action")

    execute: function () {
        return new Promise(function (resolve, reject) {
            let action;
            let command;
            if (configuration) {
                command = configuration.command;
                action = _actions.find(item => item.command === command);
            }
            if (action) {
                action.execute();
                return resolve();
            } else { console.warn("invalid command:", command) }
            reject();
        });
    }

    preference: PreferenceGroup {
        SelectCommandPreference {
            id: selectItem
            model: _actions
        }

        SelectPreference {
            name: "itemIndex"
            label: qsTr("EX Launcher Item")
            defaultValue: 0
            model: _items
            visible: selectItem.value>2
        }
    }
}
