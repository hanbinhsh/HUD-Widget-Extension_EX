import QtQuick 2.12
import QtQuick.Shapes 1.2

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    readonly property bool dataEnabled: settings.mode ?? false

    readonly property int circleRadius: settings.radius ?? 16
    readonly property int circleStrokeSize: settings.strokeSize ?? 2
    readonly property real circleAngle: settings.angle ?? 360
    readonly property real circleOffset: 270 + (settings.offset ?? 0)
    readonly property real circleHole: settings.hole ?? 0.5
    readonly property real circleStrokeAngle: 360 * circleStrokeSize / (Math.PI * 2 * circleRadius)

    readonly property color circleStrokeColor: settings.strokeColor ?? "#88FFFFFF"
    readonly property color circleFillColor: settings.fillColor ?? "#99666666"

    title: qsTranslate("utils", "Circle Graph")
    implicitWidth: Math.max(circleRadius * 2, 16)
    implicitHeight: implicitWidth
    dataConfiguration: dataEnabled ? settings.data : undefined

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SwitchPreference {
            id: pMode
            name: "mode"
            label: qsTr("Enable Data Source")
        }

        P.DataPreference {
            name: "data"
            label: qsTr("Data")
            enabled: pMode.value
        }

        P.SwitchPreference {
            name: "animation"
            label: qsTr("Animate Data Changes")
            enabled: pMode.value
        }

        P.SliderPreference {
            name: "radius"
            label: qsTr("Circle Radius")
            displayValue: value + " px"
            defaultValue: 16
            from: 4
            to: 255
            stepSize: 1
            live: true
        }

        P.SliderPreference {
            name: "angle"
            label: qsTr("Sector Angle")
            displayValue: value + " °"
            defaultValue: 360
            from: 5
            to: 360
            stepSize: 5
            live: true
        }

        P.SliderPreference {
            name: "offset"
            label: qsTr("Offset Angle")
            displayValue: value + " °"
            defaultValue: 0
            from: 0
            to: 360
            stepSize: 5
            live: true
        }

        P.SliderPreference {
            name: "hole"
            label: qsTr("Cutout Hole")
            displayValue: Math.round(value * 100) + " %"
            defaultValue: 0.5
            from: 0
            to: 1
            stepSize: 0.01
            live: true
        }

        NoDefaultColorPreference {
            name: "strokeColor"
            label: qsTr("Line Color")
            defaultValue: "#88FFFFFF"
        }

        NoDefaultColorPreference {
            name: "fillColor"
            label: qsTr("Fill Color")
            defaultValue: "#99666666"
        }

        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Line Size")
            defaultValue: 2
            from: 0
            to: 100
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
    }

    Shape {
        id: shape
        anchors.centerIn: parent

        width: circleRadius * 2
        height: width

        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: circleFillColor
            startX: circleRadius
            startY: shape.height

            PathAngleArc {
                id: outerArc
                centerX: circleRadius
                centerY: circleRadius
                radiusX: circleRadius - circleStrokeSize * 0.5
                radiusY: radiusX
                startAngle: circleOffset - circleAngle * 0.5
                sweepAngle: circleAngle * (dataEnabled ? output.result : 1)

                Behavior on sweepAngle {
                    enabled: dataEnabled && ctx_widget.exposed && Boolean(thiz.settings.animation)

                    NumberAnimation { easing.type: Easing.OutQuart; duration: 500 }
                }
            }

            PathAngleArc {
                centerX: circleRadius
                centerY: circleRadius
                radiusX: Math.max(circleHole * outerArc.radiusX, 0.00001)
                radiusY: radiusX
                startAngle: outerArc.startAngle + outerArc.sweepAngle
                sweepAngle: -outerArc.sweepAngle
                moveToStart: false
            }
        }

        ShapePath {
            strokeWidth: circleStrokeSize
            strokeColor: circleStrokeSize ? circleStrokeColor : fillColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: circleRadius
            startY: shape.height

            PathAngleArc {
                centerX: circleRadius
                centerY: circleRadius
                radiusX: circleRadius - circleStrokeSize * 0.5
                radiusY: radiusX
                startAngle: outerArc.startAngle + circleStrokeAngle * 0.5
                sweepAngle: Math.max(outerArc.sweepAngle - circleStrokeAngle, 0.1)
            }
        }
    }

    NVG.DataSourceProgressOutput {
        id: output
        source: dataEnabled ? thiz.dataSource : null
    }
}
