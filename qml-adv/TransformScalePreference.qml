import QtQuick 2.12

import NERvGear.Preferences 1.0

import "utils.js" as Utils

PreferenceGroup {
    id: thiz

    property var xScale
    property var yScale
    property var originX
    property var originY

    load: function (newValue) {
        pEnabled.load(Boolean(newValue));
        pOrigin.load(newValue?.origin);
        xScale = newValue?.xScale;
        yScale = newValue?.yScale;
        originX = newValue?.originX;
        originY = newValue?.originY;
    }
    save: function () {
        if (pEnabled.value) {
            return {
                xScale: xScale,
                yScale: yScale,
                originX: originX,
                originY: originY,
                origin: pOrigin.save()
            };
        }
    }

    data: PreferenceGroupIndicator { anchors.topMargin: pEnabled.height; visible: pEnabled.value }

    SwitchPreference {
        id: pEnabled
        name: "enabled"
        label: qsTr("Enable Scale")
    }

    Transform2DimensionControl {
        visible: pEnabled.value
        text: qsTr("Scale Dimension")

        xGeometryInput {
            valueText: xScale ?? ""
            placeholderText: "1.0"
            validator: DoubleValidator { bottom: -65535; top: 65535 }
            onUpdateValue: { xScale = value; thiz.triggerPreferenceEdited(); }
        }

        yGeometryInput {
            valueText: yScale ?? ""
            placeholderText: "1.0"
            validator: DoubleValidator { bottom: -65535; top: 65535 }
            onUpdateValue: { yScale = value; thiz.triggerPreferenceEdited(); }
        }
    }

    SelectPreference {
        id: pOrigin
        name: "origin"
        label: qsTr("Scale Origin")
        model: Utils.TransformOriginNames
        defaultValue: 4
        visible: pEnabled.value
    }

    Transform2DimensionControl {
        visible: pEnabled.value
        text: qsTr("Scale Origin Offset")

        xGeometryInput {
            valueText: originX ?? ""
            placeholderText: "0"
            onUpdateValue: { originX = value; thiz.triggerPreferenceEdited(); }
        }

        yGeometryInput {
            valueText: originY ?? ""
            placeholderText: "0"
            onUpdateValue: { originY = value; thiz.triggerPreferenceEdited(); }
        }
    }
}
