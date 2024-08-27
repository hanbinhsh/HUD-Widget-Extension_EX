import QtQuick 2.12

import NERvGear.Preferences 1.0

PreferenceGroup {
    id: thiz

    property var xTranslate
    property var yTranslate

    load: function (newValue) {
        pEnabled.load(Boolean(newValue));
        xTranslate = newValue?.x;
        yTranslate = newValue?.y;
    }
    save: function () {
        if (pEnabled.value) {
            return {
                x: xTranslate,
                y: yTranslate
            };
        }
    }

    data: PreferenceGroupIndicator { anchors.topMargin: pEnabled.height; visible: pEnabled.value }

    SwitchPreference {
        id: pEnabled
        name: "enabled"
        label: qsTr("Enable Translate")
    }

    Transform2DimensionControl {
        visible: pEnabled.value
        text: qsTr("Translate Dimension")

        xGeometryInput {
            valueText: xTranslate ?? ""
            placeholderText: "0"
            onUpdateValue: { xTranslate = value; thiz.triggerPreferenceEdited(); }
        }

        yGeometryInput {
            valueText: yTranslate ?? ""
            placeholderText: "0"
            onUpdateValue: { yTranslate = value; thiz.triggerPreferenceEdited(); }
        }
    }
}
