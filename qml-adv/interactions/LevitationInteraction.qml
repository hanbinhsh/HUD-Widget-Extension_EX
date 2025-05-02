import QtQuick 2.12

import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

HUDInteractionTemplate {
    id: thiz

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        GeometryInputPreference {
            name: "distance"
            label: qsTr("Lift Distance")
            hint: Math.round(thiz.height / 3) || ""
        }
    }

    transform: [ tTranslate ]

    transitions: [
        Transition {
            to: "PRESSED"
            NumberAnimation {
                target: tTranslate
                duration: 500
                easing.type: Easing.OutQuad
                properties: "x,y"
                to: 0
            }
            NumberAnimation { target: thiz; duration: 500; property: "opacity"; to: 1 }
        },
        Transition {
            to: "HOVERED"
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: thiz; duration: 1500; property: "opacity"; from: 1; to: 0.8 }
                NumberAnimation { target: thiz; duration: 2000; property: "opacity"; from: 0.8; to: 1 }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation {
                    target: tTranslate
                    duration: 3500
                    easing.type: Easing.InOutQuad
                    property: "x"
                    from: 0
                    to: 3
                }
                NumberAnimation {
                    target: tTranslate
                    duration: 2000
                    easing.type: Easing.InOutQuad
                    property: "x"
                    to: -2
                }
                NumberAnimation {
                    target: tTranslate
                    duration: 3000
                    easing.type: Easing.InOutQuad
                    property: "x"
                    to: 0
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    id: aLift
                    target: tTranslate
                    duration: 500
                    easing.type: Easing.OutQuad
                    property: "y"
                    to: -(thiz.settings.distance ?? thiz.height / 3)
                }
                SequentialAnimation {
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: tTranslate
                        duration: 1000
                        easing.type: Easing.OutSine
                        property: "y"
                        to: aLift.to + 3
                    }
                    NumberAnimation {
                        target: tTranslate
                        duration: 1000
                        easing.type: Easing.InSine
                        property: "y"
                        to: aLift.to
                    }
                    NumberAnimation {
                        target: tTranslate
                        duration: 1000
                        easing.type: Easing.OutSine
                        property: "y"
                        to: aLift.to - 5
                    }
                    NumberAnimation {
                        target: tTranslate
                        duration: 1000
                        easing.type: Easing.InSine
                        property: "y"
                        to: aLift.to
                    }
                }
            }
        },
        Transition { // last fallback match
            from: "HOVERED,PRESSED"
            NumberAnimation {
                target: tTranslate
                duration: 250
                easing.type: Easing.OutBounce
                easing.amplitude: 0.5
                properties: "x,y"
                to: 0
            }
            NumberAnimation { target: thiz; duration: 250; property: "opacity"; to: 1 }
        }
    ]

    Translate {
        id: tTranslate
    }
}

