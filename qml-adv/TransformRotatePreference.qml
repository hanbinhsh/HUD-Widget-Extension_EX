import QtQuick 2.12

import NERvGear.Preferences 1.0

import "utils.js" as Utils

PreferenceGroup {
    id: thiz

    property bool useSliders: true

    property real pitchAngle
    property real yawAngle
    property real rollAngle

    property var originX
    property var originY

    load: function (newValue) {
        const pyr = Utils.toPitchYawRoll(newValue?.axisX ?? 0,
                                         newValue?.axisY ?? 0,
                                         newValue?.axisZ ?? 0,
                                         newValue?.angle ?? 0);

        pEnabled.load(Boolean(newValue));
        pOrigin.load(newValue?.origin);
        pPitchAngle.load(pyr.pitch);
        pYawAngle.load(pyr.yaw);
        pRollAngle.load(pyr.roll);
        pitchAngle = pyr.pitch;
        yawAngle = pyr.yaw;
        rollAngle = pyr.roll;
        originX = newValue?.originX;
        originY = newValue?.originY;
    }
    save: function () {
        if (pEnabled.value) {
            if (useSliders) {
                pitchAngle = pPitchAngle.save();
                yawAngle = pYawAngle.save();
                rollAngle = pRollAngle.save();
            }
            const axisAngle = (pitchAngle || yawAngle || rollAngle) ?
                                Utils.toAxisAngle(pitchAngle, yawAngle, rollAngle) : {};
            return {
                angle: axisAngle.w,
                axisX: axisAngle.x,
                axisY: axisAngle.y,
                axisZ: axisAngle.z,
                origin: pOrigin.save(),
                originX: originX,
                originY: originY
            };
        }
    }

    data: PreferenceGroupIndicator { anchors.topMargin: pEnabled.height; visible: pEnabled.value }

    SwitchPreference {
        id: pEnabled
        name: "enabled"
        label: qsTr("Enable 3D Rotation")
    }

    SliderPreference {
        id: pPitchAngle
        label: qsTr("Pitch Angle") + " \u2195"
        displayValue: value + " °"
        defaultValue: 0
        from: -180
        to: 180
        stepSize: 1
        live: true
        visible: pEnabled.value && useSliders
    }

    SliderPreference {
        id: pYawAngle
        label: qsTr("Yaw Angle") + " \u2194"
        displayValue: value + " °"
        defaultValue: 0
        from: -180
        to: 180
        stepSize: 1
        live: true
        visible: pEnabled.value && useSliders
    }

    SliderPreference {
        id: pRollAngle
        label: qsTr("Roll Angle") + " \u27f3"
        displayValue: value + " °"
        defaultValue: 0
        from: -180
        to: 180
        stepSize: 1
        live: true
        visible: pEnabled.value && useSliders
    }

    Transform3DimensionControl {
        visible: pEnabled.value && !useSliders

        xGeometryLabel: qsTr("Pitch Angle") + " \u2195"
        xGeometryInput {
            valueText: pitchAngle || ""
            placeholderText: "0 °"
            minValue: -3600
            maxValue: 3600
            onUpdateValue: { pitchAngle = value ?? 0; thiz.triggerPreferenceEdited(); }
        }

        yGeometryLabel: qsTr("Yaw Angle") + " \u2194"
        yGeometryInput {
            valueText: yawAngle || ""
            placeholderText: "0 °"
            minValue: -3600
            maxValue: 3600
            onUpdateValue: { yawAngle = value ?? 0; thiz.triggerPreferenceEdited(); }
        }

        zGeometryLabel: qsTr("Roll Angle") + " \u27f3"
        zGeometryInput {
            valueText: rollAngle || ""
            placeholderText: "0 °"
            minValue: -3600
            maxValue: 3600
            onUpdateValue: { rollAngle = value ?? 0; thiz.triggerPreferenceEdited(); }
        }
    }

    SelectPreference {
        id: pOrigin
        name: "origin"
        label: qsTr("Rotation Origin")
        model: Utils.TransformOriginNames
        defaultValue: 4
        visible: pEnabled.value
    }

    Transform2DimensionControl {
        visible: pEnabled.value
        text: qsTr("Rotation Origin Offset")

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
