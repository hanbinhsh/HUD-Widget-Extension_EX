import QtQuick 2.12

import NERvGear.Preferences 1.0 as P

import ".."

DataChartElement {
    id: thiz

    readonly property int padSize: 2
    readonly property int padHeight: height - padSize * 2

    readonly property color gridlineColor: settings.gridlineColor ?? "#88FFFFFF"
    readonly property color strokeColor: settings.strokeColor ?? "#66FFFFFF"

    readonly property color strokeGlowColor: {
        if (strokeGlow)
            return Qt.rgba(strokeColor.r, strokeColor.g, strokeColor.b, 1);
        return Qt.rgba(0, 0, 0, 0);
    }

    readonly property color gridlineRealColor: Qt.rgba(gridlineColor.r,
                                                       gridlineColor.g,
                                                       gridlineColor.b,
                                                       gridlineColor.a * 0.5)

    readonly property color gridlineGlowColor: {
        if (gridlineGlow)
            return Qt.rgba(gridlineColor.r, gridlineColor.g, gridlineColor.b, 0.5);
        return Qt.rgba(0, 0, 0, 0);
    }

    readonly property int strokeSize: settings.strokeSize ?? 2
    readonly property bool strokeGlow: settings.strokeGlow ?? true
    readonly property bool drawGridlines: settings.gridline ?? true
    readonly property bool gridlineGlow: settings.gridlineGlow ?? true

    valueStep: 6
    drawCanvas: canvas
    title: qsTranslate("utils", "Line Chart")

    onGridlineColorChanged: fullRedraw = true
    onStrokeColorChanged: fullRedraw = true
    onStrokeSizeChanged: fullRedraw = true
    onStrokeGlowChanged: fullRedraw = true
    onGridlineGlowChanged: fullRedraw = true
    onDrawGridlinesChanged: fullRedraw = true

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
            enabled: pGridline.value
        }

        P.SwitchPreference {
            name: "gridlineGlow"
            label: qsTr("Gridlines Glow")
            defaultValue: true
            enabled: pGridline.value
        }
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

    function drawLine(ctx, value1, value2) {
        var h1 = padSize + padHeight - Math.round(value1 * padHeight);
        var h2 = padSize + padHeight - Math.round(value2 * padHeight);

        ctx.beginPath();
        ctx.lineWidth = strokeSize;
        ctx.shadowBlur = 2;
        ctx.shadowColor = strokeGlowColor;
        ctx.strokeStyle = strokeColor;
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

            var ctx = getContext("2d");
            var offset = thiz.width - x - thiz.valueStep;

            ctx.setTransform(1, 0, 0, 1, offset, 0);

            if (fullRedraw) {
                fullRedraw = false;
                drawBackground(ctx, offset);

                for (var i = values.length - 1; i > 0; --i) {
                    drawLine(ctx, values[i - 1], values[i]);
                    ctx.translate(-thiz.valueStep, 0);
                }
                drawLine(ctx, values.lastRemoved, values[0]);
            } else {
                var previous = 0;
                var current = 0;
                if (values.length > 0) {
                    current = values[values.length - 1];
                    if (values.length > 1)
                        previous = values[values.length - 2];
                }
                drawLine(ctx, previous, current);
            }
        }
    }
}
