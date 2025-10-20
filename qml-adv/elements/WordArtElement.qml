import QtQuick 2.12
import QtQuick.Templates 2.12 as T

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id:  thiz

    readonly property bool dataEnabled: settings.mode ?? false

    readonly property int textAlign: thiz.settings.align ?? 0
    readonly property int textBaseline: thiz.settings.baseline ?? 0

    readonly property int hPadding: thiz.settings.hPadding ?? 1
    readonly property int vPadding: thiz.settings.vPadding ?? 0

    readonly property int fillType: settings.fillType ?? 1
    readonly property int strokeType: settings.strokeType ?? 1
    readonly property real fillAngle: settings.fillAngle ?? 0
    readonly property real strokeAngle: settings.strokeAngle ?? 0
    readonly property real lineWidth: strokeType ? (thiz.settings.lineWidth ?? 1) : 0
    readonly property real shadowBlur: thiz.settings.shadowBlur ?? 1
    readonly property real shadowOffsetX: thiz.settings.shadowOffsetX ?? 0
    readonly property real shadowOffsetY: thiz.settings.shadowOffsetY ?? 0

    readonly property color colorFN: settings.fillColor  ?? ctx_widget.defaultTextColor
    readonly property color colorFH: settings.fillColorH ?? colorFN
    readonly property color colorFP: settings.fillColorP ?? colorFH
    readonly property color colorLN: settings.strokeColor  ?? "#666666"
    readonly property color colorLH: settings.strokeColorH ?? colorLN
    readonly property color colorLP: settings.strokeColorP ?? colorLH
    readonly property color colorSN: settings.shadowColor  ?? "#000000"
    readonly property color colorSH: settings.shadowColorH ?? colorSN
    readonly property color colorSP: settings.shadowColorP ?? colorSH

    readonly property var stopsFN: settings.fillStops  ?? gradientStops(ctx_widget.defaultTextColor, "transparent")
    readonly property var stopsFH: settings.fillStopsH ?? stopsFN
    readonly property var stopsFP: settings.fillStopsP ?? stopsFH
    readonly property var stopsLN: settings.strokeStops  ?? gradientStops("#e91e63", "#b2ebf2")
    readonly property var stopsLH: settings.strokeStopsH ?? stopsLN
    readonly property var stopsLP: settings.strokeStopsP ?? stopsLH

    readonly property color shadowColor: pressed ? colorSP : hovered ? colorSH : colorSN

    readonly property string canvasFont: {
        var styles = "";
        if (fontMetrics.font.italic)
            styles += "italic ";
        // private styles support
        if (fontMetrics.font.strikeout)
            styles += "strikeout ";
        if (fontMetrics.font.underline)
            styles += "underline ";

        return styles + '%1 %2px "%3"'.arg(fontMetrics.font.weight)
                                      .arg(fontMetrics.font.pixelSize)
                                      .arg(fontMetrics.font.family);
    }

    readonly property string textString: {
        if (settings.mode)
            return output.result;

        return settings.text || elementLabel || defaultLabel;
    }
    readonly property var textLines: textString.split('\n')
    readonly property int textWidth: {
        // capture font changing
        const letterSpacing = fontMetrics.font.letterSpacing;
        return textLines.reduce(function (max, line) {
            // BUG: fontMetrics.boundingRect() ignores letter spacing
            const w = fontMetrics.boundingRect(line).width +
                      Math.max(0, line.length - 1) * letterSpacing;
            return max > w ? max : w;
        }, 0);
    }
    readonly property int textLineHeight: fontMetrics.height * (settings.lineHeight ?? 100) / 100
    readonly property int textHeight: {
        const h = textLineHeight * textLines.length;
        return Math.max(h + fontMetrics.height - textLineHeight, 0);
    }

    property var contextData: ({})
    property var fillInfo: ({})
    property var fillStyle
    property var strokeInfo: ({})
    property var strokeStyle

    onTextAlignChanged: canvas.requestPaint()
    onTextBaselineChanged: canvas.requestPaint()
    onHPaddingChanged: canvas.requestPaint()
    onVPaddingChanged: canvas.requestPaint()
    onTextStringChanged: canvas.requestPaint()
    onTextLineHeightChanged: canvas.requestPaint()
    onLineWidthChanged: canvas.requestPaint()
    onShadowBlurChanged: canvas.requestPaint()
    onShadowOffsetXChanged: canvas.requestPaint()
    onShadowOffsetYChanged: canvas.requestPaint()
    onFillStyleChanged: canvas.requestPaint()
    onStrokeStyleChanged: canvas.requestPaint()
    onShadowColorChanged: canvas.requestPaint()

    onCanvasFontChanged: if (canvas.context) canvas.context.font = canvasFont

    onFillTypeChanged: {
        if (fillType === 2) {
            fillStyle = Qt.binding(function () {
                const ctx = canvas.context;
                if (!ctx)
                    return undefined;
                return pressed ? makeGradient(ctx, contextData, fillInfo, stopsFP, "stopsFP") :
                       hovered ? makeGradient(ctx, contextData, fillInfo, stopsFH, "stopsFH") :
                                 makeGradient(ctx, contextData, fillInfo, stopsFN, "stopsFN");
            });
            fillInfo = Qt.binding(() => gradientInfo(width, height, fillAngle));
        } else if (fillType === 0) {
            fillStyle = "transparent";
            fillInfo = { startX: 0, startY: 0, endX: 0, endY: 0 };
        } else {
            fillStyle = Qt.binding(() => pressed ? colorFP : hovered ? colorFH : colorFN);
            fillInfo = { startX: 0, startY: 0, endX: 0, endY: 0 };
        }
    }

    onStrokeTypeChanged: {
        if (strokeType === 2) {
            strokeStyle = Qt.binding(function () {
                const ctx = canvas.context;
                if (!ctx)
                    return undefined;
                return pressed ? makeGradient(ctx, contextData, strokeInfo, stopsLP, "stopsLP") :
                       hovered ? makeGradient(ctx, contextData, strokeInfo, stopsLH, "stopsLH") :
                                 makeGradient(ctx, contextData, strokeInfo, stopsLN, "stopsLN");
            });
            strokeInfo = Qt.binding(() => gradientInfo(width, height, strokeAngle));
        } else if (strokeType === 0) {
            strokeStyle = "transparent";
            strokeInfo = { startX: 0, startY: 0, endX: 0, endY: 0 };
        } else {
            strokeStyle = Qt.binding(() => pressed ? colorLP : hovered ? colorLH : colorLN);
            strokeInfo = { startX: 0, startY: 0, endX: 0, endY: 0 };
        }
    }

    Component.onCompleted: {
        // upgrade settings
        // fillStyleX -> fillColorX
        if (settings.fillStyle)  { settings.fillColor  = settings.fillStyle;  settings.fillStyle = undefined; }
        if (settings.fillStyleH) { settings.fillColorH = settings.fillStyleH; settings.fillStyleH = undefined; }
        if (settings.fillStyleP) { settings.fillColorP = settings.fillStyleP; settings.fillStyleP = undefined; }
        // strokeStyleX -> strokeColorX
        if (settings.strokeStyle)  { settings.strokeColor  = settings.strokeStyle;  settings.strokeStyle = undefined; }
        if (settings.strokeStyleH) { settings.strokeColorH = settings.strokeStyleH; settings.strokeStyleH = undefined; }
        if (settings.strokeStyleP) { settings.strokeColorP = settings.strokeStyleP; settings.strokeStyleP = undefined; }
    }

    function gradientStops(c1, c2) {
        return [ { color: c1, position: 0 }, { color: c2, position: 1 } ];
    }

    function gradientInfo(w, h, angle) {
        const w2 = w / 2;
        const h2 = h / 2;

        const rad = angle * Math.PI / 180;
        const dx = Math.sin(rad);
        const dy = Math.cos(rad);
        // find shortest path to the edges
        const t = Math.min(w2 / Math.abs(dx), h2 / Math.abs(dy));

        const x1 = w2 + dx * t;
        const y1 = h2 - dy * t;

        return { startX: x1, startY: y1, endX: w - x1, endY: h - y1 };
    }

    function makeGradient(ctx, cache, info, config, key) {
        let grad = cache[key];
        if (grad && (grad.info === info) && (grad.config === config))
            return grad;

        grad = ctx.createLinearGradient(info.startX, info.startY, info.endX, info.endY);
        grad.info = info;
        grad.config = config;
        if (Array.isArray(config))
            config.forEach((stop)=>grad.addColorStop(stop.position, stop.color));

        cache[key] = grad;

        return grad;
    }

    title: qsTranslate("utils", "Word Art")
    implicitWidth: textWidth + hPadding * 2
    implicitHeight: textString ? (textHeight + vPadding * 2) : 32
    dataConfiguration: dataEnabled ? settings.data : undefined

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SwitchPreference {
            id: pMode
            name: "mode"
            label: qsTr("Enable Data Source")
        }

        P.TextAreaPreference {
            name: "text"
            label: qsTr("Text")
            visible: !pMode.value
        }

        P.DataPreference {
            name: "data"
            label: qsTr("Data")
            visible: pMode.value
            environment: thiz.environment
        }

        P.FontPreference {
            name: "font"
            label: qsTr("Font")
            defaultValue: ctx_widget.defaultFont
        }

        P.SelectPreference {
            name: "align"
            label: qsTr("Horizontal Alignment")
            defaultValue: 0
            model: [ qsTr("Left"), qsTr("Right"), qsTr("Center") ]
        }

        P.SpinPreference {
            name: "hPadding"
            label: qsTr("Horizontal Padding")
            display: P.TextFieldPreference.ExpandLabel
            defaultValue: 1
            from: -999
            to: 999
            stepSize: 1
            editable: true
        }

        P.SelectPreference {
            name: "baseline"
            label: qsTr("Vertical Alignment")
            defaultValue: 0
            model: [ qsTr("Top"), qsTr("Bottom"), qsTr("Center") ]
        }

        P.SpinPreference {
            name: "vPadding"
            label: qsTr("Vertical Padding")
            display: P.TextFieldPreference.ExpandLabel
            defaultValue: 0
            from: -999
            to: 999
            stepSize: 1
            editable: true
        }

        P.SpinPreference {
            name: "lineHeight"
            label: qsTr("Line Height")
            display: P.TextFieldPreference.ExpandLabel
            defaultValue: 100
            from: 50
            to: 250
            stepSize: 10
        }

        P.SelectPreference {
            id: pFillType
            name: "fillType"
            label: qsTr("Fill Type")
            model: [ qsTr("None"), qsTr("Color"), qsTr("Gradient") ]
            defaultValue: 1
        }

        P.SliderPreference {
            name: "fillAngle"
            label: qsTr("Fill Angle")
            displayValue: value + " °"
            defaultValue: 0
            from: -90
            to: 90
            stepSize: 1
            live: true
            visible: pFillType.value === 2
        }

        NoDefaultColorPreference {
            name: "fillColor"
            label: qsTr("Fill Color")
            defaultValue: ctx_widget.defaultTextColor
            visible: pFillType.value === 1
        }

        NoDefaultColorPreference {
            name: "fillColorH"
            label: "- " + qsTr("Hovered")
            defaultValue: "transparent"
            visible: pFillType.value === 1
        }

        NoDefaultColorPreference {
            name: "fillColorP"
            label: "- " + qsTr("Pressed")
            defaultValue: "transparent"
            visible: pFillType.value === 1
        }

        GradientPreference {
            name: "fillStops"
            label: qsTr("Fill Gradient")
            defaultValue: gradientStops(ctx_widget.defaultTextColor, "transparent")
            visible: pFillType.value === 2
        }

        GradientPreference {
            name: "fillStopsH"
            label: "- " + qsTr("Hovered")
            visible: pFillType.value === 2
        }

        GradientPreference {
            name: "fillStopsP"
            label: "- " + qsTr("Pressed")
            visible: pFillType.value === 2
        }

        P.SelectPreference {
            id: pStrokeType
            name: "strokeType"
            label: qsTr("Line Type")
            model: [ qsTr("None"), qsTr("Color"), qsTr("Gradient") ]
            defaultValue: 1
        }

        P.SpinPreference {
            name: "lineWidth"
            label: qsTr("Line Size")
            defaultValue: 1
            from: 0
            to: 32
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: pStrokeType.value
        }

        P.SliderPreference {
            name: "strokeAngle"
            label: qsTr("Line Angle")
            displayValue: value + " °"
            defaultValue: 0
            from: -90
            to: 90
            stepSize: 1
            live: true
            visible: pStrokeType.value === 2
        }

        NoDefaultColorPreference {
            name: "strokeColor"
            label: qsTr("Line Color")
            defaultValue: "#666666"
            visible: pStrokeType.value === 1
        }

        NoDefaultColorPreference {
            name: "strokeColorH"
            label: "- " + qsTr("Hovered")
            defaultValue: "transparent"
            visible: pStrokeType.value === 1
        }

        NoDefaultColorPreference {
            name: "strokeColorP"
            label: "- " + qsTr("Pressed")
            defaultValue: "transparent"
            visible: pStrokeType.value === 1
        }

        GradientPreference {
            name: "strokeStops"
            label: qsTr("Line Gradient")
            defaultValue: gradientStops("#e91e63", "#b2ebf2")
            visible: pStrokeType.value === 2
        }

        GradientPreference {
            name: "strokeStopsH"
            label: "- " + qsTr("Hovered")
            visible: pStrokeType.value === 2
        }

        GradientPreference {
            name: "strokeStopsP"
            label: "- " + qsTr("Pressed")
            visible: pStrokeType.value === 2
        }

        P.SpinPreference {
            name: "shadowBlur"
            label: qsTr("Shadow Size")
            defaultValue: 1
            from: 0
            to: 32
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SpinPreference {
            name: "shadowOffsetX"
            label: "- " + qsTr("Horizontal Offset")
            defaultValue: 0
            from: -999
            to: 999
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SpinPreference {
            name: "shadowOffsetY"
            label: "- " + qsTr("Vertical Offset")
            defaultValue: 0
            from: -999
            to: 999
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        NoDefaultColorPreference {
            name: "shadowColor"
            label: qsTr("Shadow Color")
            defaultValue: "#000000"
        }

        NoDefaultColorPreference {
            name: "shadowColorH"
            label: "- " + qsTr("Hovered")
            defaultValue: "transparent"
        }

        NoDefaultColorPreference {
            name: "shadowColorP"
            label: "- " + qsTr("Pressed")
            defaultValue: "transparent"
        }
    }

    // BUG: QTBUG-89557
    // TextMetrics returns wrong implicitWidth if wrapping is enabled.
    // We have to calculate implicit size manually.
    FontMetrics {
        id: fontMetrics
        font: thiz.settings.font ? Qt.font(thiz.settings.font) : ctx_widget.defaultFont
        onFontChanged: canvas.requestPaint() // including letterSpacing changed
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            const ctx = getContext("2d");
            var textX = hPadding;
            var textY = vPadding;

            ctx.clearRect(0, 0, width, height);

            switch (textAlign) {
            case 2: ctx.textAlign = "center"; textX = Math.round(width / 2); break;
            case 1: ctx.textAlign = "right"; textX = width - hPadding; break;
            case 0:
            default: ctx.textAlign = "left"; break;
            }

            switch (textBaseline) {
            case 2: // vertical center
                ctx.textBaseline = "top";
                textY = Math.round((height - textHeight) / 2);
                break;
            case 1: // bottom
                ctx.textBaseline = "bottom";
                textY = height - (textLines.length - 1) * textLineHeight - vPadding;
                break;
            case 0: // top
            default: ctx.textBaseline = "top"; break;
            }

            ctx.fillStyle = fillStyle;
            ctx.strokeStyle = strokeStyle;
            ctx.lineWidth = lineWidth;
            ctx.shadowColor = shadowColor;
            ctx.shadowBlur = shadowBlur;
            ctx.shadowOffsetX = shadowOffsetX;
            ctx.shadowOffsetY = shadowOffsetY;
            ctx.letterSpacing = fontMetrics.font.letterSpacing;

            ctx.beginPath();
            textLines.forEach(function (line) {
                ctx.text(line, textX, textY);
                textY += textLineHeight;
            });

            if (lineWidth)
                ctx.draw(true);
            else
                ctx.fill();
        }

        // NOTE: parsing font string when assigning canvasFont is quite expansive,
        // we should avoid doing that inside onPaint()
        onAvailableChanged: {
            if (available) {
                const ctx = getContext("2d");
                ctx.font = canvasFont;
                ctx.globalCompositeOperation = "copy";
                ctx.lineJoin = "round"; // BUG: fix artificial text outline
            }
        }
    }

    NVG.DataSourceTextOutput {
        id: output
        source: dataEnabled ? thiz.dataSource : null
        undefinedText: ""
        nullText: ""
    }
}
