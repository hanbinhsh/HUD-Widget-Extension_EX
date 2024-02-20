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

    readonly property real lineWidth: thiz.settings.lineWidth ?? 1
    readonly property real shadowBlur: thiz.settings.shadowBlur ?? 1
    readonly property real shadowOffsetX: thiz.settings.shadowOffsetX ?? 0
    readonly property real shadowOffsetY: thiz.settings.shadowOffsetY ?? 0

    readonly property color colorFN: settings.fillStyle  ?? ctx_widget.defaultTextColor
    readonly property color colorFH: settings.fillStyleH ?? colorFN
    readonly property color colorFP: settings.fillStyleP ?? colorFH
    readonly property color colorON: settings.strokeStyle  ?? "#666666"
    readonly property color colorOH: settings.strokeStyleH ?? colorON
    readonly property color colorOP: settings.strokeStyleP ?? colorOH
    readonly property color colorSN: settings.shadowColor  ?? "#000000"
    readonly property color colorSH: settings.shadowColorH ?? colorSN
    readonly property color colorSP: settings.shadowColorP ?? colorSH

    readonly property color fillColor: itemPressed ? colorFP : itemHovered ? colorFH : colorFN
    readonly property color strokeColor: itemPressed ? colorOP : itemHovered ? colorOH : colorON
    readonly property color shadowColor: itemPressed ? colorSP : itemHovered ? colorSH : colorSN

    readonly property string canvasFont: {
        var styles = "";
        if (textMetrics.font.italic)
            styles += "italic ";
        // private styles support
        if (textMetrics.font.strikeout)
            styles += "strikeout ";
        if (textMetrics.font.underline)
            styles += "underline ";

        return styles + '%1 %2px "%3"'.arg(textMetrics.font.weight)
                                      .arg(textMetrics.font.pixelSize)
                                      .arg(textMetrics.font.family);
    }

    onTextAlignChanged: canvas.requestPaint()
    onTextBaselineChanged: canvas.requestPaint()
    onLineWidthChanged: canvas.requestPaint()
    onShadowBlurChanged: canvas.requestPaint()
    onShadowOffsetXChanged: canvas.requestPaint()
    onShadowOffsetYChanged: canvas.requestPaint()
    onFillColorChanged: canvas.requestPaint()
    onStrokeColorChanged: canvas.requestPaint()
    onShadowColorChanged: canvas.requestPaint()

    onCanvasFontChanged: if (canvas.context) canvas.context.font = canvasFont

    title: qsTranslate("utils", "Word Art")
    implicitWidth: textMetrics.width + 2
    implicitHeight: textMetrics.text ? textMetrics.height : 32
    dataConfiguration: dataEnabled ? settings.data : undefined

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SwitchPreference {
            id: pMode
            name: "mode"
            label: qsTr("Enable Data Source")
        }

        P.TextFieldPreference {
            name: "text"
            label: qsTr("Text")
            visible: !pMode.value
        }

        P.DataPreference {
            name: "data"
            label: qsTr("Data")
            visible: pMode.value
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

        P.SelectPreference {
            name: "baseline"
            label: qsTr("Vertical Alignment")
            defaultValue: 0
            model: [ qsTr("Top"), qsTr("Bottom"), qsTr("Center") ]
        }

        NoDefaultColorPreference {
            name: "fillStyle"
            label: qsTr("Fill Color")
            defaultValue: ctx_widget.defaultTextColor
        }

        NoDefaultColorPreference {
            name: "fillStyleH"
            label: "- " + qsTr("Hovered Color")
            defaultValue: "transparent"
        }

        NoDefaultColorPreference {
            name: "fillStyleP"
            label: "- " + qsTr("Pressed Color")
            defaultValue: "transparent"
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
        }

        NoDefaultColorPreference {
            name: "strokeStyle"
            label: qsTr("Line Color")
            defaultValue: "#666666"
        }

        NoDefaultColorPreference {
            name: "strokeStyleH"
            label: "- " + qsTr("Hovered Color")
            defaultValue: "transparent"
        }

        NoDefaultColorPreference {
            name: "strokeStyleP"
            label: "- " + qsTr("Pressed Color")
            defaultValue: "transparent"
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
            label: "- " + qsTr("Hovered Color")
            defaultValue: "transparent"
        }

        NoDefaultColorPreference {
            name: "shadowColorP"
            label: "- " + qsTr("Pressed Color")
            defaultValue: "transparent"
        }
    }

    TextMetrics {
        id: textMetrics

        text: {
            if (thiz.settings.mode)
                return output.result;

            return thiz.settings.text || thiz.elementLabel || thiz.itemLabel;
        }
        font: thiz.settings.font ? Qt.font(thiz.settings.font) : ctx_widget.defaultFont

        onTextChanged: canvas.requestPaint()
        onFontChanged: canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            const ctx = getContext("2d");
            var textX = 0;
            var textY = 0;

            ctx.clearRect(0, 0, width, height);

            switch (textAlign) {
            case 2: ctx.textAlign = "center"; textX = Math.round(width / 2); break;
            case 1: ctx.textAlign = "right"; textX = width; break;
            case 0:
            default: ctx.textAlign = "left"; break;
            }

            switch (textBaseline) {
            case 2:
                ctx.textBaseline = "top";
                textY = Math.round((height - textMetrics.height) / 2);
                break;
            case 1: ctx.textBaseline = "bottom"; textY = height; break;
            case 0:
            default: ctx.textBaseline = "top"; break;
            }

            ctx.fillStyle = fillColor;
            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = lineWidth;
            ctx.shadowColor = shadowColor;
            ctx.shadowBlur = shadowBlur;
            ctx.shadowOffsetX = shadowOffsetX;
            ctx.shadowOffsetY = shadowOffsetY;
            ctx.letterSpacing = textMetrics.font.letterSpacing;

            ctx.beginPath();
            ctx.text(textMetrics.text, textX, textY);

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
