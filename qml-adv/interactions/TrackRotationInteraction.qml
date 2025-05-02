import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import "../utils.js" as Utils

HUDInteractionTemplate {
    id: thiz

    readonly property point centerPoint: Qt.point(width / 2, height / 2)
    readonly property int globalMaxDistance: Math.max(NVG.View.screen.width, NVG.View.screen.height) / 2

    readonly property bool trackGlobal: settings.trackGlobal ?? false
    readonly property real trackAngle: settings.trackAngle ?? 15
    readonly property int trackOrigin: settings.trackOrigin ?? Item.Center
    readonly property int trackInterval: settings.trackInterval ?? 100
    readonly property int trackDuration: settings.trackDuration ?? 1000

    readonly property real rotateRangeX: {
        switch (trackOrigin) {
        case Item.Right:
        case Item.TopRight:
        case Item.BottomRight: return -trackAngle;
        default: break;
        }
        return trackAngle;
    }

    readonly property real rotateRangeY: {
        switch (trackOrigin) {
        case Item.Bottom:
        case Item.BottomLeft:
        case Item.BottomRight: return trackAngle;
        default: break;
        }
        return -trackAngle;
    }

    readonly property var rotateAmountX: {
        switch (trackOrigin) {
        case Item.Left:
        case Item.TopLeft:
        case Item.BottomLeft:
            if (trackGlobal)
                return (pos, global) => (pos - global) / globalMaxDistance;
            return (pos) => pos / width;
        case Item.Right:
        case Item.TopRight:
        case Item.BottomRight:
            if (trackGlobal)
                return (pos, global) => (global + width - pos) / globalMaxDistance;
            return (pos) => (width - pos) / width;
        case Item.Top:
        case Item.Bottom:
        case Item.Center:
        default: break;
        }
        if (trackGlobal)
            return (pos, global) => (pos - centerPoint.x - global) / globalMaxDistance;
        return (pos) => (pos - centerPoint.x) / centerPoint.x;
    }

    readonly property var rotateAmountY: {
        switch (trackOrigin) {
        case Item.Top:
        case Item.TopLeft:
        case Item.TopRight:
            if (trackGlobal)
                return (pos, global) => (pos - global) / globalMaxDistance;
            return (pos) => pos / height;
        case Item.Bottom:
        case Item.BottomLeft:
        case Item.BottomRight:
            if (trackGlobal)
                return (pos, global) => (global + width - pos) / globalMaxDistance;
            return (pos) => (height - pos) / height;
        case Item.Left:
        case Item.Right:
        case Item.Center:
        default: break;
        }
        if (trackGlobal)
            return (pos, global) => (pos - centerPoint.y - global) / globalMaxDistance;
        return (pos) => (pos - centerPoint.y) / centerPoint.y;
    }

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SwitchPreference {
            name: "trackGlobal"
            label: qsTr("Global Tracking")
            defaultValue: false
        }

        P.SliderPreference {
            name: "trackAngle"
            label: qsTr("Rotation Angle")
            displayValue: value + " °"
            defaultValue: 15
            from: -90
            to: 90
            stepSize: 5
            live: true
        }

        P.SelectPreference {
            name: "trackOrigin"
            label: qsTr("Rotation Origin")
            model: Utils.TransformOriginNames
            defaultValue: 4
        }

        P.SelectPreference {
            name: "trackInterval"
            label: qsTr("Sample Interval")
            textRole: "label"
            valueRole: "interval"
            defaultValue: 1
            model: [
                { interval:   50, label: "50ms" },
                { interval:  100, label: "100ms" },
                { interval:  250, label: "250ms" },
                { interval:  500, label: "500ms" },
                { interval: 1000, label: "1s" }
            ]
        }

        P.SelectPreference {
            name: "trackDuration"
            label: qsTr("Animation Speed")
            textRole: "label"
            valueRole: "duration"
            defaultValue: 2
            model: [
                { duration:    0, label: qsTr("Off") },
                { duration:  500, label: qsTr("Fast") },
                { duration: 1000, label: qsTr("Normal") },
                { duration: 2000, label: qsTr("Slow") }
            ]
        }
    }

    contentTransform: [ extraRotate ]

    Rotation {
        id: extraRotate

        Behavior on angle {
            enabled: trackDuration
            NumberAnimation {
                easing.type: Easing.OutCubic
                duration: trackDuration
            }
        }

        axis {
            z: 0 // fix initial behavior animation

            Behavior on x {
                enabled: trackDuration
                NumberAnimation {
                    duration: trackDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                enabled: trackDuration
                NumberAnimation {
                    duration: trackDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on z {
                enabled: trackDuration
                NumberAnimation {
                    duration: trackDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
        origin {
            x: centerPoint.x
            y: centerPoint.y
        }
    }

    Timer {
        interval: trackInterval
        repeat: true
        running: ctx_widget.exposed && (trackGlobal || ctx_widget.hovered)
        triggeredOnStart: true
        onTriggered: {
            let pitch, yaw;
            if (trackGlobal) {
                const pos = NVG.Utils.cursorPosition();
                const global = thiz.mapToGlobal(0, 0);
                const amountY = rotateAmountY(pos.y, global.y);
                const amountX = rotateAmountX(pos.x, global.x);
                pitch = rotateRangeY * Math.max(Math.min(amountY, 1.0), -1.0);
                yaw   = rotateRangeX * Math.max(Math.min(amountX, 1.0), -1.0);
            } else {
                const pos = ctx_widget.mouseHoverPosition(thiz);
                pitch = rotateRangeY * rotateAmountY(pos.y);
                yaw   = rotateRangeX * rotateAmountX(pos.x);
            }
            if (pitch || yaw) {
                const axisAngle = Utils.toAxisAngle(pitch, yaw, 0);
                extraRotate.axis.x = axisAngle.x;
                extraRotate.axis.y = axisAngle.y;
                extraRotate.axis.z = axisAngle.z;
                extraRotate.angle  = axisAngle.w;
            } else {
                extraRotate.angle = 0;
            }
        }
        onRunningChanged: extraRotate.angle = 0
    }

    Component.onCompleted: ctx_widget.trackMouseHover(thiz)
    Component.onDestruction: ctx_widget?.untrackMouseHover(thiz)
}

