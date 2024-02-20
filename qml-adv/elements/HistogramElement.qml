import QtQuick 2.12

import NERvGear.Preferences 1.0 as P

import ".."

DataChartElement {
    id: thiz

    readonly property color fillColor: settings.fillColor ?? "#99666666"
    readonly property color strokeColor: settings.strokeColor ?? "#99CCCCCC"

    title: qsTranslate("utils", "Histogram")
    drawCanvas: canvas
    valueStep: settings.barSize || 2

    onFillColorChanged: fullRedraw = true
    onStrokeColorChanged: fullRedraw = true

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

        NoDefaultColorPreference {
            name: "fillColor"
            label: qsTr("Fill Color")
            defaultValue: "#99666666"
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
    }

    function drawBar(ctx, value) {
        // reserve 1px to smooth top and bottom edges when transforming
        const h = canvas.height - (Math.round(value * (canvas.height - 2)) || 1);

        ctx.fillStyle = thiz.fillColor;
        ctx.fillRect(0, h, valueStep, canvas.height - 1 - h);
        ctx.strokeStyle = thiz.strokeColor;
        ctx.beginPath();
        ctx.moveTo(0, h);
        ctx.lineTo(valueStep, h);
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
