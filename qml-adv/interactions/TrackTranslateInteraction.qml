import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

HUDInteractionTemplate {
    id: thiz

    readonly property point centerPoint: Qt.point(width / 2, height / 2)

    readonly property bool trackGlobal: settings.global ?? false
    readonly property real trackMin: settings.distanceMin ?? 0
    readonly property real trackMax: settings.distanceMax ?? 100
    readonly property real trackTranslate: settings.translate ?? 15
    readonly property int trackInterval: settings.interval ?? 100
    readonly property int trackDuration: settings.duration ?? 1000

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SwitchPreference {
            name: "global"
            label: qsTr("Global Tracking")
            defaultValue: false
        }

        P.SliderPreference {
            name: "translate"
            label: qsTr("Translate Dimension")
            displayValue: value + " px"
            defaultValue: 15
            from: -100
            to: 100
            stepSize: 1
            live: true
        }

        P.SpinPreference {
            name: "distanceMin"
            label: qsTr("Minimum Distance")
            display: P.TextFieldPreference.ExpandLabel
            defaultValue: 0
            from: 0
            to: 999
            stepSize: 1
            editable: true
        }

        P.SpinPreference {
            name: "distanceMax"
            label: qsTr("Maximum Distance")
            display: P.TextFieldPreference.ExpandLabel
            defaultValue: 100
            from: 0
            to: 999
            stepSize: 1
            editable: true
        }

        P.SelectPreference {
            name: "interval"
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
            name: "duration"
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

    contentTransform: [ trackTrasnlate ]

    Translate {
        id: trackTrasnlate

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
    }

    Timer {
        interval: trackInterval
        repeat: true
        running: ctx_widget.exposed && thiz.visible && (trackGlobal || ctx_widget.hovered)
        triggeredOnStart: true
        onTriggered: {
            var cursorPos, originPos;

            if (trackGlobal) {
                cursorPos = NVG.Utils.cursorPosition();
                originPos = thiz.mapToGlobal(centerPoint.x, centerPoint.y);
            } else {
                cursorPos = ctx_widget.mouseHoverPosition(thiz);
                originPos = centerPoint;
            }

            const dx = cursorPos.x - originPos.x;
            const dy = cursorPos.y - originPos.y;

            const radius = Math.atan2(dy, dx);
            var distance = Math.sqrt(dx * dx + dy * dy);

            distance -= trackMin;
            if (distance < 0)
                distance = 0;
            else if (distance > trackMax)
                distance = trackMax;

            const length = (distance / trackMax) * trackTranslate;
            trackTrasnlate.x = Math.cos(radius) * length;
            trackTrasnlate.y = Math.sin(radius) * length;
        }
        onRunningChanged: trackTrasnlate.x = trackTrasnlate.y = 0
    }

    Component.onCompleted: ctx_widget.trackMouseHover(thiz)
    Component.onDestruction: ctx_widget?.untrackMouseHover(thiz)
}

