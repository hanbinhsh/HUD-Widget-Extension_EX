import QtQuick 2.12
import QtQuick.Controls 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    readonly property color ptrColor: settings.ptrColor ?? "transparent"
    readonly property real ptrRange: thiz.settings.ptrRange ?? 360
    readonly property color scaleColor: settings.scaleColor ?? "transparent"
    readonly property real scaleRange: thiz.settings.scaleRange ?? 360
    readonly property real scaleRadius: Math.max(width, height) / 2


    title: qsTranslate("utils", "Pointer Meter")
    implicitWidth: Math.max(ptrImage.implicitWidth, ptrImage.implicitHeight)
    implicitHeight: implicitWidth
    dataConfiguration: settings.data

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.DataPreference {
            name: "data"
            label: qsTr("Data")
        }

        P.SwitchPreference {
            name: "animation"
            label: qsTr("Animate Data Changes")
        }

        P.ImagePreference {
            name: "ptrImage"
            label: qsTr("Pointer Image")
        }

        Transform2DimensionControl {
            text: qsTr("Image Origin")

            xGeometryInput {
                valueText: thiz.settings.ptrOriginX ?? ""
                placeholderText: ptrImage.implicitWidth / 2
                onUpdateValue: thiz.settings.ptrOriginX = value
            }

            yGeometryInput {
                valueText: thiz.settings.ptrOriginY ?? ""
                placeholderText: ptrImage.implicitHeight / 2
                onUpdateValue: thiz.settings.ptrOriginY = value
            }
        }

        P.SliderPreference {
            name: "ptrOffset"
            label: qsTr("Pointer Offset")
            displayValue: value + " °"
            defaultValue: 0
            from: -180
            to: 180
            stepSize: 5
            live: true
        }

        P.SliderPreference {
            name: "ptrRange"
            label: qsTr("Pointer Range")
            displayValue: value + " °"
            defaultValue: 360
            from: 5
            to: 360
            stepSize: 5
            live: true
        }

        NoDefaultColorPreference {
            name: "ptrColor"
            label: qsTr("Pointer Color")
            defaultValue: "transparent"
        }

        P.SwitchPreference {
            id: pScale
            name: "scale"
            label: qsTr("Draw Scales")
            defaultValue: true
        }

        P.SliderPreference {
            name: "scaleOffset"
            label: qsTr("Scales Offset")
            displayValue: value + " °"
            defaultValue: 0
            from: -180
            to: 180
            stepSize: 5
            live: true
            enabled: pScale.value
        }

        P.SliderPreference {
            name: "scaleRange"
            label: qsTr("Scales Range")
            displayValue: value + " °"
            defaultValue: 360
            from: 5
            to: 360
            stepSize: 5
            live: true
            enabled: pScale.value
        }

        NoDefaultColorPreference {
            name: "scaleColor"
            label: qsTr("Scales Color")
            defaultValue: "transparent"
            enabled: pScale.value
        }
    }

    Loader {
        anchors.fill: parent
        active: thiz.settings.scale ?? true
        sourceComponent: Item {
            Image {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: height / 2 - scaleRadius
                source: "../../Images/bar-scale-l.png"
                transform: Rotation {
                    origin.x: 2
                    origin.y: scaleRadius
                    angle: (thiz.settings.scaleOffset ?? 0)
                }
            }

            Image {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: height / 2 - scaleRadius
                source: "../../Images/bar-scale-s.png"
                transform: Rotation {
                    origin.x: 2
                    origin.y: scaleRadius
                    angle: (thiz.settings.scaleOffset ?? 0) + scaleRange * 0.25
                }
            }

            Image {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: height / 2 - scaleRadius
                source: "../../Images/bar-scale-m.png"
                transform: Rotation {
                    origin.x: 2
                    origin.y: scaleRadius
                    angle: (thiz.settings.scaleOffset ?? 0) + scaleRange * 0.5
                }
            }

            Image {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: height / 2 - scaleRadius
                source: "../../Images/bar-scale-s.png"
                transform: Rotation {
                    origin.x: 2
                    origin.y: scaleRadius
                    angle: (thiz.settings.scaleOffset ?? 0) + scaleRange * 0.75
                }
            }

            Image {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: height / 2 - scaleRadius
                visible: scaleRange !== 360
                source: "../../Images/bar-scale-l.png"
                transform: Rotation {
                    origin.x: 2
                    origin.y: scaleRadius
                    angle: (thiz.settings.scaleOffset ?? 0) + scaleRange
                }
            }

            layer.enabled: scaleColor.a
            layer.effect: ColorOverlayEffect { color: scaleColor }
        }
    }

    Image {
        id: ptrImage

        x: parent.width / 2 - ptrRotation.origin.x
        y: parent.height / 2 - ptrRotation.origin.y
        cache: false
        source: Qt.resolvedUrl(thiz.settings.ptrImage ?? "../../Images/pointer.png")

        transform: Rotation {
            id: ptrRotation
            origin.x: thiz.settings.ptrOriginX ?? (ptrImage.implicitWidth / 2)
            origin.y: thiz.settings.ptrOriginY ?? (ptrImage.implicitHeight / 2)
            angle: (thiz.settings.ptrOffset ?? 0) + ptrRange * output.result

            Behavior on angle {
                enabled: ctx_widget.exposed && Boolean(thiz.settings.animation)
                NumberAnimation { easing.type: Easing.OutQuad; duration: 250 }
            }
        }

        layer.smooth: true
        layer.enabled: ptrColor.a
        layer.effect: ColorOverlayEffect { color: ptrColor }
    }

    NVG.DataSourceProgressOutput {
        id: output
        source: thiz.dataSource
    }
}
