import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

DataSourceElement {
    id:  thiz

    readonly property bool dataEnabled: settings.mode ?? false

    readonly property var normalImage: settings.normal ?? ""
    readonly property var hoveredImage: settings.hovered ?? normalImage
    readonly property var pressedImage: settings.pressed ?? hoveredImage

    readonly property bool spinEnabled: Boolean(thiz.settings.spin)
    readonly property real spinStep: (settings.spinRPM ?? 5) * 6 / (settings.spinFPS || 20)

    title: qsTranslate("utils", "Image")
    implicitWidth: imageSource.status ? imageSource.implicitWidth : 64
    implicitHeight: imageSource.status ? imageSource.implicitHeight : 64
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
            visible: pMode.value
        }

//        P.ItemPreference {
//            label: qsTr("Source Size")
//            background: null

//            actionItem: Row {
//                spacing: 8

//                GeometryEditorInput {
//                    minValue: 0
//                    valueText: thiz.settings.sourceWidth ?? ""
//                    onUpdateValue: thiz.settings.sourceWidth = value
//                }

//                Label {
//                    anchors.verticalCenter: parent.verticalCenter
//                    text: "x"
//                    enabled: false
//                }

//                GeometryEditorInput {
//                    minValue: 0
//                    valueText: thiz.settings.sourceHeight ?? ""
//                    onUpdateValue: thiz.settings.sourceHeight = value
//                }
//            }
//        }

        P.SelectPreference {
            name: "fill"
            label: qsTr("Fill Mode")
            model: [ qsTr("Stretch"), qsTr("Fit"), qsTr("Crop"),
                qsTr("Tile"), qsTr("Tile Vertically"), qsTr("Tile Horizontally"), qsTr("Pad") ]
            defaultValue: 1
        }

        P.SliderPreference {
            name: "radius"
            label: qsTr("Border Radius")
            displayValue: value <= 50 ? (value + " px") : (value - 50 + " %")
            defaultValue: 0
            from: 0
            to: 150
            stepSize: 1
            live: true
        }

        P.ImagePreference {
            name: "normal"
            label: qsTr("Normal")
            visible: !pMode.value
        }

        P.ImagePreference {
            name: "hovered"
            label: qsTr("Hovered")
            visible: !pMode.value
        }

        P.ImagePreference {
            name: "pressed"
            label: qsTr("Pressed")
            visible: !pMode.value
        }

        P.SwitchPreference {
            name: "antialias"
            label: qsTr("Smooth Edges")
        }

        P.SwitchPreference {
            id: pSpin
            name: "spin"
            label: qsTr("Spin Animation")
        }

        P.SliderPreference {
            name: "spinRPM"
            label: qsTr("Spin Speed")
            displayValue: value + " RPM"
            defaultValue: 5
            from: 1
            to: 100
            stepSize: 1
            live: true
            visible: pSpin.value
        }

        P.SliderPreference {
            name: "spinFPS"
            label: qsTr("Spin Frame Rate")
            displayValue: value + " FPS"
            defaultValue: 20
            from: 1
            to: 60
            stepSize: 1
            live: true
            visible: pSpin.value
        }
    }

    onSpinEnabledChanged: imageSource.rotation = 0

    Timer {
        repeat: true
        interval: 1000 / (settings.spinFPS || 20)
        running: ctx_widget.exposed && spinEnabled && imageSource.status
        onTriggered: imageSource.rotation = (imageSource.rotation + spinStep) % 360
    }

    NVG.ImageSource {
        id: imageSource
        anchors.fill: parent

        antialiasing: thiz.settings.antialias ?? false
        fillMode: thiz.settings.fill ?? Image.PreserveAspectFit
        playing: status === Image.Ready
        configuration: {
            if (dataEnabled)
                return output.result;

            if (thiz.itemPressed)
                return pressedImage;

            if (thiz.itemHovered)
                return hoveredImage;

            return normalImage;
        }

//        sourceSize: {
//            const w = thiz.settings.sourceWidth;
//            const h = thiz.settings.sourceHeight;
//            return (w || h) ? Qt.size(w, h) : undefined;
//        }

        // simple OpacityMask implementation
        layer.enabled: thiz.settings.radius ?? false
        layer.smooth: true
        layer.effect: Item {
            id: effectItem
            property var source

            ShaderEffect {
                anchors.fill: parent
                anchors.margins: imageSource.antialiasing ? -1 : 0

                readonly property rect sourceScale: {
                    if (imageSource.antialiasing)
                        return Qt.rect(1 / imageSource.width,
                                       1 / imageSource.height,
                                       2 / imageSource.width + 1,
                                       2 / imageSource.height + 1);
                    return Qt.rect(0, 0, 1, 1);
                }
                readonly property var source: effectItem.source
                readonly property var maskSource: ShaderEffectSource {
                    sourceRect: {
                        if (imageSource.antialiasing)
                            return Qt.rect(-1, -1, imageSource.width + 2, imageSource.height + 2);
                        return Qt.rect(0, 0, 0, 0);
                    }
                    sourceItem: Rectangle {
                        width: imageSource.width
                        height: imageSource.height
                        // adaptive radius unit
                        radius: thiz.settings.radius <= 50 ? thiz.settings.radius :
                                    Math.min(width, height) * 0.005 * (thiz.settings.radius - 50)
                    }
                }
                fragmentShader: "
varying highp vec2 qt_TexCoord0;
uniform highp float qt_Opacity;
uniform highp vec4 sourceScale;
uniform lowp sampler2D source;
uniform lowp sampler2D maskSource;
void main(void) {
    highp vec2 sourceCoord = qt_TexCoord0 * sourceScale.zw - sourceScale.xy;
    gl_FragColor = texture2D(source, sourceCoord) * (texture2D(maskSource, qt_TexCoord0).a) * qt_Opacity;
}
"
            }
        }
    }

    NVG.DataSourceRawOutput {
        id: output
        source: dataEnabled ? thiz.dataSource : null
    }
}
