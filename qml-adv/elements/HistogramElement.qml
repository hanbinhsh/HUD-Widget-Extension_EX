import QtQuick 2.12

import NERvGear.Preferences 1.0 as P

import ".."

DataChartElement {
    id: thiz

    readonly property color strokeColor: settings.strokeColor ?? "#99CCCCCC"
    readonly property int strokeSize: settings.strokeSize ?? 1

    readonly property color fillColor: settings.fillColor ?? colorAlpha(strokeColor, 0.25)
    readonly property var fillStops: gradientStops(settings.fillStops, colorAlpha(strokeColor, 0.5))

    readonly property int fillType: settings.fillType ?? 1
    readonly property var fillGradient: { // capture gradient settings
        return fillType === 2 ? { start: settings.fillStopsStart } : {}
    }
    property int fillGradientMax: height

    readonly property int barSize: settings.barSize || 2
    readonly property int barGap: settings.barGap ?? 0

    title: qsTranslate("utils", "Histogram")
    drawCanvas: canvas
    valueStep: barSize + barGap

    onStrokeColorChanged: fullRedraw = true
    onStrokeSizeChanged: fullRedraw = true
    onFillColorChanged: fullRedraw = true
    onFillStopsChanged: fullRedraw = true
    onFillTypeChanged: fullRedraw = true
    onFillGradientMaxChanged: fullRedraw = true

    onFillGradientChanged: {
        fillGradientMax = fillGradient.start ? Qt.binding(function () {
            valueCount; // capture valueCount, height
            return Math.max.apply(null, values) * height;
        }) : Qt.binding(() => height);
    }

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.DataPreference {
            name: "data"
            label: qsTr("Data")
        }

        P.SwitchPreference {
            name: "dynamic"
            label: qsTr("Dynamic Range")
            defaultValue: false
        }

        NoDefaultColorPreference {
            name: "strokeColor"
            label: qsTr("Line Color")
            defaultValue: "#99CCCCCC"
        }

        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Line Size")
            defaultValue: 1
            from: 1
            to: 5
            stepSize: 1
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SelectPreference {
            id: pFillType
            name: "fillType"
            label: qsTr("Fill Type")
            model: [ qsTr("None"), qsTr("Color"), qsTr("Gradient") ]
            defaultValue: 1
        }

        NoDefaultColorPreference {
            name: "fillColor"
            label: qsTr("Fill Color")
            defaultValue: colorAlpha(strokeColor, 0.25)
            visible: pFillType.value === 1
        }

        GradientPreference {
            name: "fillStops"
            label: qsTr("Fill Gradient")
            defaultValue: gradientStops(null, colorAlpha(thiz.strokeColor, 0.5))
            visible: pFillType.value === 2
        }

        P.SelectPreference {
            name: "fillStopsStart"
            label: qsTr("Fill Gradient Start")
            model: [ qsTr("Top"), qsTr("Maximum") ]
            defaultValue: 0
            visible: pFillType.value === 2
        }

        P.SliderPreference {
            name: "barSize"
            label: qsTr("Bar Width")
            displayValue: value + " px"
            defaultValue: 2
            from: 1
            to: 10
            stepSize: 1
            live: true
        }

        P.SliderPreference {
            name: "barGap"
            label: qsTr("Bar Gap")
            displayValue: value + " px"
            defaultValue: 0
            from: 0
            to: 10
            stepSize: 1
            live: true
        }
    }

    function colorAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function gradientStops(stops, fallback) {
        if (Array.isArray(stops))
            return stops;
        return [ { color: fallback, position: 0 }, { color: "transparent", position: 1 } ];
    }

    function drawBar(ctx, value) {
        // reserve 1px to smooth top and bottom edges when transforming
        const h = canvas.height - (Math.round(value * (canvas.height - 2)) || 1);

        if (fillType)
            ctx.fillRect(0, h, barSize, canvas.height - 1 - h);
        ctx.beginPath();
        ctx.moveTo(0, h);
        ctx.lineTo(barSize, h);
        ctx.stroke();
    }

    Canvas {
        id: canvas
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        x: -valueStep * valueCount
        width: thiz.width * 2 // cache twice size of chart

        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.FramebufferObject

        antialiasing: false

        onPaint: {
            if (valueCount === -1)
                return;

            var ctx = getContext("2d");
            var offset = thiz.width - x - valueStep;

            ctx.setTransform(1, 0, 0, 1, offset, 0);

            if (fullRedraw) {
                fullRedraw = false;

                ctx.clearRect(-offset, 0, width, height);

                ctx.strokeStyle = thiz.strokeColor;
                ctx.lineWidth = strokeSize;

                switch (fillType) {
                case 2:
                {
                    const grad = ctx.createLinearGradient(0, height - fillGradientMax,
                                                          0, height);
                    fillStops.forEach((stop)=>grad.addColorStop(stop.position, stop.color));
                    ctx.fillStyle = grad;
                    break;
                }
                case 1: ctx.fillStyle = fillColor; break;
                case 0:
                default: break;
                }

                for (var i = values.length - 1; i >= 0; --i) {
                    drawBar(ctx, values[i]);
                    ctx.translate(-valueStep, 0);
                }
            } else {
                drawBar(ctx, outputResult);
            }
        }
    }
}
