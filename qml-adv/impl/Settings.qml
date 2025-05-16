pragma Singleton

import QtQml 2.12

import NERvGear 1.0 as NVG

QtObject {
    id: root

    property NVG.SettingsMap copiedItem
    property NVG.SettingsMap copiedElement

    function duplicateMap(src, parent) {
        const dst = NVG.Settings.createMap(parent);
        src.keys().forEach(function (key) {
            const prop = src[key];
            if (prop instanceof NVG.SettingsMap) {
                dst[key] = duplicateMap(prop, dst);
            } else if (prop instanceof NVG.SettingsList) {
                dst[key] = duplicateList(prop, dst);
            } else {
                // NOTE: shallow copy should be safe
                // because we NEVER modify nested objects
                dst[key] = prop;
            }
        });
        return dst;
    }

    function duplicateList(src, parent) {
        const dst = NVG.Settings.createList(parent);
        for (let i = 0; i < src.count; ++i)
            dst.append(duplicateMap(src.get(i), dst));
        return dst;
    }

    function copyItem(item) {
        if (copiedItem)
            copiedItem.destroy();
        copiedItem = duplicateMap(item, root);
    }

    function copyElement(element) {
        if (copiedElement)
            copiedElement.destroy();
        copiedElement = duplicateMap(element, root);
    }

}
