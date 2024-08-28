import QtQuick 2.12

import NERvGear.Preferences 1.0 as P

import ".."

DataChartElement {
    id: thiz

    readonly property int padSize: 2
    readonly property int padHeight: height - padSize * 2

    readonly property color strokeColor: settings.strokeColor ?? "#66FFFFFF"
    readonly property color strokeGlowColor: strokeGlow ? colorAlpha(strokeColor, 1) : Qt.rgba(0, 0, 0, 0)

    readonly property color fillColor: settings.fillColor ?? colorAlpha(strokeColor, 0.5)
    readonly property var fillStops: gradientStops(settings.fillStops, colorAlpha(strokeColor, 0.5))

    readonly property color gridlineColor: settings.gridlineColor ?? "#88FFFFFF"
    readonly property color gridlineRealColor: colorAlpha(gridlineColor, 0.5)
    readonly property color gridlineGlowColor: gridlineGlow ? colorAlpha(gridlineColor, 0.5) : Qt.rgba(0, 0, 0, 0)

    readonly property int strokeSize: settings.strokeSize ?? 2
    readonly property bool strokeGlow: settings.strokeGlow ?? true
    readonly property int fillType: settings.fillType ?? 0
    readonly property var drawStep: fillType ? fillStrokeStep : strokeStep
    readonly property bool drawGridlines: settings.gridline ?? true
    readonly property bool gridlineGlow: settings.gridlineGlow ?? true

    readonly property var fillGradient: { // capture gradient settings
        return fillType === 2 ? { start: settings.fillStopsStart, end: settings.fillStopsEnd } : {}
    }
    property int fillGradientMax: padHeight
    property int fillGradientMin: 0

    valueStep: 6
    drawCanvas: canvas
    title: qsTranslate("utils", "Line Chart")

    onGridlineColorChanged: fullRedraw = true
    onStrokeColorChanged: fullRedraw = true
    onStrokeSizeChanged: fullRedraw = true
    onStrokeGlowChanged: fullRedraw = true
    onGridlineGlowChanged: fullRedraw = true
    onDrawGridlinesChanged: fullRedraw = true
    onFillColorChanged: fullRedraw = true
    onFillStopsChanged: fullRedraw = true
    onFillTypeChanged: fullRedraw = true
    onFillGradientMaxChanged: fullRedraw = true
    onFillGradientMinChanged: fullRedraw = true

    onFillGradientChanged: {
        fillGradientMax = fillGradient.start ? Qt.binding(function () {
            valueCount; // capture valueCount, padHeight
            return Math.max.apply(null, values) * padHeight;
        }) : Qt.binding(() => padHeight);
        fillGradientMin = fillGradient.end ? Qt.binding(function () {
            valueCount; // capture valueCount, padHeight
            return Math.min.apply(null, values) * padHeight;
        }) : 0;
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
            defaultValue: "#88FFFFFF"
        }

        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Line Size")
            defaultValue: 2
            from: 1
            to: 5
            stepSize: 1
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SwitchPreference {
            name: "strokeGlow"
            label: qsTr("Line Glow")
            defaultValue: true
        }

        P.SelectPreference {
            id: pFillType
            name: "fillType"
            label: qsTr("Fill Type")
            model: [ qsTr("None"), qsTr("Color"), qsTr("Gradient") ]
            defaultValue: 0
        }

        NoDefaultColorPreference {
            name: "fillColor"
            label: qsTr("Fill Color")
            defaultValue: colorAlpha(thiz.strokeColor, 0.5)
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

        P.SelectPreference {
            name: "fillStopsEnd"
            label: qsTr("Fill Gradient End")
            model: [ qsTr("Bottom"), qsTr("Minimum") ]
            defaultValue: 0
            visible: pFillType.value === 2
        }

        P.SwitchPreference {
            id: pGridline
            name: "gridline"
            label: qsTr("Draw Gridlines")
            defaultValue: true
        }

        NoDefaultColorPreference {
            name: "gridlineColor"
            label: qsTr("Gridlines Color")
            defaultValue: "#44FFFFFF"
            visible: pGridline.value
        }

        P.SwitchPreference {
            name: "gridlineGlow"
            label: qsTr("Gridlines Glow")
            defaultValue: true
            visible: pGridline.value
        }
    }

    function colorAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function gradientStops(stops, fallback) {
        if (Array.isArray(stops))
            return stops;
        return [ { color: fallback, position: 0 }, { color: "transparent", position: 1 } ];
    }

    function drawBackground(ctx, offset) {
        ctx.clearRect(-offset, 0, canvas.width, canvas.height);

        if (drawGridlines) {
            var h = 0;
            // thick lines
            ctx.beginPath();
            ctx.lineWidth = 2;
            ctx.shadowBlur = 2;
            ctx.shadowColor = gridlineGlowColor;
            ctx.strokeStyle = gridlineRealColor;
            h = padSize;
            ctx.moveTo(-offset, h);
            ctx.lineTo(canvas.width, h);
            h = canvas.height - padSize;
            ctx.moveTo(-offset, h);
            ctx.lineTo(canvas.width, h);
            ctx.stroke();
            // thin lines
            ctx.beginPath();
            ctx.lineWidth = 1;
            ctx.shadowBlur = 2;
            h = Math.round(0.5 * canvas.height);
            ctx.moveTo(-offset, h);
            ctx.lineTo(canvas.width, h);
            h = Math.round(0.25 * canvas.height);
            ctx.moveTo(-offset, h);
            ctx.lineTo(canvas.width, h);
            h = Math.round(0.75 * canvas.height);
            ctx.moveTo(-offset, h);
            ctx.lineTo(canvas.width, h);
            ctx.stroke();
        }
    }

    function strokeStep(ctx, bottom, h1, h2) {
        ctx.shadowBlur = 2;
        ctx.beginPath();
        ctx.moveTo(0, h1);
        ctx.lineTo(valueStep, h2);
        ctx.stroke();
    }

    function fillStrokeStep(ctx, bottom, h1, h2) {
        ctx.shadowBlur = 0;
        ctx.beginPath();
        ctx.moveTo(0, h1);
        ctx.lineTo(valueStep, h2);
        ctx.lineTo(valueStep, bottom);
        ctx.lineTo(0, bottom);
        ctx.closePath();
        ctx.fill();

        ctx.shadowBlur = 2;
        ctx.beginPath();
        ctx.moveTo(0, h1);
        ctx.lineTo(valueStep, h2);
        ctx.stroke();
    }

    Canvas {
        id: canvas
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        x: -thiz.valueStep * thiz.valueCount
        width: thiz.width * 2 // cache twice size of chart

        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            if (thiz.valueCount === -1)
                return;

            var h1, h2;
            const ctx = getContext("2d");
            const offset = thiz.width - x - thiz.valueStep;
            const bottom = padSize + padHeight;

            ctx.setTransform(1, 0, 0, 1, offset, 0);

            if (fullRedraw) {
                fullRedraw = false;
                drawBackground(ctx, offset);

                ctx.lineWidth = strokeSize;
                ctx.shadowColor = strokeGlowColor;
                ctx.strokeStyle = strokeColor;

                switch (fillType) {
                case 2:
                {
                    const grad = ctx.createLinearGradient(0, bottom - fillGradientMax,
                                                          0, bottom - fillGradientMin);
                    fillStops.forEach((stop)=>grad.addColorStop(stop.position, stop.color));
                    ctx.fillStyle = grad;
                    break;
                }
                case 1: ctx.fillStyle = fillColor; break;
                case 0:
                default: break;
                }

                for (let i = values.length - 1; i > 0; --i) {
                    h1 = bottom - Math.round(values[i - 1] * padHeight);
                    h2 = bottom - Math.round(values[i]     * padHeight);
                    drawStep(ctx, bottom, h1, h2);
                    ctx.translate(-thiz.valueStep, 0);
                }
                h1 = bottom - Math.round(values.lastRemoved * padHeight);
                h2 = bottom - Math.round(values[0]          * padHeight);
                drawStep(ctx, bottom, h1, h2);
            } else {
                let previous = 0;
                let current = 0;
                if (values.length > 0) {
                    current = values[values.length - 1];
                    if (values.length > 1)
                        previous = values[values.length - 2];
                }
                h1 = bottom - Math.round(previous * padHeight);
                h2 = bottom - Math.round(current  * padHeight);
                drawStep(ctx, bottom, h1, h2);
            }
        }
    }
}
