import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

HUDInteractionTemplate {
    id: thiz

    readonly property var animationSpeedModel: [
        { duration:    0, label: qsTr("Off") },
        { duration:  250, label: qsTr("Fast") },
        { duration:  500, label: qsTr("Normal") },
        { duration: 1000, label: qsTr("Slow") }
    ]

    readonly property var unboundData: ({
        defaultScale: {},
        defaultRotate: {}
    })

    readonly property NVG.SettingsMap normalSettings:  NVG.Settings.makeMap(settings, "normal")
    readonly property NVG.SettingsMap hoveredSettings: NVG.Settings.makeMap(settings, "hovered")
    readonly property NVG.SettingsMap pressedSettings: NVG.Settings.makeMap(settings, "pressed")

    readonly property NVG.SettingsMap currentSettings: {
        switch (state) {
        case "PRESSED": return pressedSettings;
        case "HOVERED": return hoveredSettings;
        case "NORMAL":
        default: break;
        }
        return normalSettings;
    }

    property real animationDuration: 0

    onCurrentSettingsChanged: { // triggered before any bindings
        animationDuration = currentSettings.duration ?? 500;
    }

    preference: P.PreferenceGroup {
        P.ObjectDialogPreference {
            label: qsTr("Normal Transform...")
            defaultValue: thiz.normalSettings
            live: true

            TransformTranslatePreference { name: "translate" }
            TransformScalePreference { name: "scale" }
            TransformRotatePreference { name: "rotate"; useSliders: false }

            P.SliderPreference {
                name: "opacity"
                label: qsTr("Opacity")
                displayValue: Math.round(value * 100) + " %"
                defaultValue: 1
                from: 0
                to: 1
                stepSize: 0.01
                live: true
            }

            GeometryInputPreference {
                name: "z"
                label: qsTr("Z Order")
                hint: "0"
                validator: IntValidator { bottom: -100; top: 100 }
            }

            P.SelectPreference {
                name: "duration"
                label: qsTr("Animation Speed")
                textRole: "label"
                valueRole: "duration"
                defaultValue: 2
                model: animationSpeedModel
            }
        }

        P.ObjectDialogPreference {
            label: qsTr("Hovered Transform...")
            defaultValue: thiz.hoveredSettings
            live: true

            TransformTranslatePreference { name: "translate" }
            TransformScalePreference { name: "scale" }
            TransformRotatePreference { name: "rotate"; useSliders: false }

            P.SliderPreference {
                name: "opacity"
                label: qsTr("Opacity")
                displayValue: Math.round(value * 100) + " %"
                defaultValue: 1
                from: 0
                to: 1
                stepSize: 0.01
                live: true
            }

            GeometryInputPreference {
                name: "z"
                label: qsTr("Z Order")
                hint: "0"
                validator: IntValidator { bottom: -100; top: 100 }
            }

            P.SelectPreference {
                name: "duration"
                label: qsTr("Animation Speed")
                textRole: "label"
                valueRole: "duration"
                defaultValue: 2
                model: animationSpeedModel
            }
        }

        P.ObjectDialogPreference {
            label: qsTr("Pressed Transform...")
            defaultValue: thiz.pressedSettings
            live: true

            TransformTranslatePreference { name: "translate" }
            TransformScalePreference { name: "scale" }
            TransformRotatePreference { name: "rotate"; useSliders: false }

            P.SliderPreference {
                name: "opacity"
                label: qsTr("Opacity")
                displayValue: Math.round(value * 100) + " %"
                defaultValue: 1
                from: 0
                to: 1
                stepSize: 0.01
                live: true
            }

            GeometryInputPreference {
                name: "z"
                label: qsTr("Z Order")
                hint: "0"
                validator: IntValidator { bottom: -100; top: 100 }
            }

            P.SelectPreference {
                name: "duration"
                label: qsTr("Animation Speed")
                textRole: "label"
                valueRole: "duration"
                defaultValue: 2
                model: animationSpeedModel
            }
        }
    }

    opacity: currentSettings.opacity ?? 1
    extraZ: currentSettings.z
    transform: [ tTranslate, tScale, tRotation ]

    Behavior on opacity {
        enabled: animationDuration
        NumberAnimation { duration: animationDuration }
    }

    Translate {
        id: tTranslate
        property var config: currentSettings.translate ?? {}

        x: config.x ?? 0
        y: config.y ?? 0

        Behavior on x {
            enabled: animationDuration
            NumberAnimation {
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        }

        Behavior on y {
            enabled: animationDuration
            NumberAnimation {
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        }
    }

    ConfigurableScale {
        id: tScale
        item: thiz
        config: {
            const cfg = currentSettings.scale;
            if (cfg) {
                unboundData.defaultScale = {
                    origin: cfg.origin,
                    originX: cfg.originX,
                    originY: cfg.originY
                };
                return cfg;
            }
            return unboundData.defaultScale;
        }

        Behavior on xScale {
            enabled: animationDuration
            NumberAnimation {
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        }

        Behavior on yScale {
            enabled: animationDuration
            NumberAnimation {
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        }
    }

    ConfigurableRotation {
        id: tRotation
        item: thiz
        config: {
            const cfg = currentSettings.rotate;
            if (cfg) {
                unboundData.defaultRotate = {
                    axisX: cfg.axisX,
                    axisY: cfg.axisY,
                    axisZ: cfg.axisZ,
                    origin: cfg.origin,
                    originX: cfg.originX,
                    originY: cfg.originY
                };
                return cfg;
            }
            return unboundData.defaultRotate;
        }

        Behavior on angle {
            enabled: animationDuration
            NumberAnimation {
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        }
    }
}

