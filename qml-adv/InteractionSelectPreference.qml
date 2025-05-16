import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0

SelectPreference {
    id: thiz

    property bool hasDefault
    property var catalogPattern
    property var builtinInteractions: []
    property NVG.SettingsMap settingsBase

    // private
    property int storedValue: value
    readonly property var settingsCaches: []

    function clearSettingsCaches() {
        settingsCaches.forEach(function (settings) {
            if (settings && settings.destroy)
                settings.destroy();
        });
        settingsCaches.length = 0;
    }

    label: qsTr("Interactive Effect")
    textRole: "label"
    defaultValue: 0

    model: {
        const items = [ { label: qsTr("None"), source: "none" }, ...builtinInteractions ];
        if (hasDefault)
            items.unshift({ label: qsTr("<Default>"), source: "" });
        const resources = NVG.Resources.filter(/.*/, catalogPattern);
        resources.forEach(function (resource) {
            resource.files().forEach(function (file) {
                items.push({ label: file.title || file.name, source: file.url.toString() });
            });
        });
        return items;
    }

    load: function (newValue) {
        if (newValue === undefined) {
            value = defaultValue;
            return;
        }
        value = model.findIndex(item=>item.source === newValue);
        storedValue = value;
    }

    save: function () {
        if (value <= 0)
            return;
        return model[value].source;
    }

    onPreferenceEdited: { // store/load cached settings
        if (storedValue === value)
            return;

        const reaction = settingsBase.reaction;

        if (hasDefault) {
            settingsBase.reaction = value ? settingsCaches[value] : undefined;
            if (storedValue > 0)
                settingsCaches[storedValue] = reaction;
        } else {
            settingsBase.reaction = settingsCaches[value];
            if (storedValue >= 0)
                settingsCaches[storedValue] = reaction;
        }
        settingsCaches[value] = undefined;

        storedValue = value;
    }

    onSettingsBaseChanged: clearSettingsCaches()
    Component.onDestruction: clearSettingsCaches()
}
