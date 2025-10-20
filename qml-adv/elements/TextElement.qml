import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id:  thiz

    readonly property bool dataEnabled: settings.mode ?? false

    readonly property color normalColor: settings.color ?? ctx_widget.defaultTextColor
    readonly property color hoveredColor: settings.hoveredColor ?? "transparent"
    readonly property color pressedColor: settings.pressedColor ?? "transparent"

    readonly property string displayUnit: dataSource.suffix ?? output.unit

    readonly property var displayText: {
        if (settings.output === 2) { // unit only
            return (value, unit) => unit;
        } else if (settings.output === 1 || !displayUnit) { // value only
            return (value, unit) => value;
        } // value and unit
        return (value, unit) => value + ' ' + unit;
    }

    title: qsTranslate("utils", "Numeric or Text")
    implicitHeight: textSource.implicitHeight
    Binding on implicitWidth {
        delayed: true // avoid binding loop
        value: textSource.implicitWidth
    }
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

        P.SelectPreference {
            name: "output"
            label: qsTr("Output")
            visible: pMode.value
            defaultValue: 0
            model: [ qsTr("Value and Unit"), qsTr("Value Only"), qsTr("Unit Only") ]
        }

        P.SelectPreference {
            id: pRounding
            name: "rounding"
            label: qsTr("Rounding Numbers")
            visible: pMode.value
            defaultValue: 0
            model: [ qsTr("Auto"), qsTr("Fixed") ]
        }

        P.SpinPreference {
            name: "decimal"
            label: qsTr("Decimal Digits")
            display: P.TextFieldPreference.ExpandLabel
            visible: pMode.value && pRounding.value === 1
            defaultValue: 0
            from: 0
            to: 10
            stepSize: 1
        }

        P.SelectPreference {
            name: "format"
            label: qsTr("Text Format")
            defaultValue: 0
            model: [ qsTr("Auto"), qsTr("Plain Text"), qsTr("Rich Text"), qsTr("HTML Text") ]
        }

        P.FontPreference {
            name: "font"
            label: qsTr("Font")
            defaultValue: ctx_widget.defaultFont
        }

        P.SelectPreference {
            id: pSizeMode
            name: "sizeMode"
            label: qsTr("Font Size Mode")
            defaultValue: 0
            model: [ qsTr("Fixed Size"), qsTr("Horizontal Fit"), qsTr("Vertical Fit"), qsTr("Fit") ]
        }

        P.SpinPreference {
            name: "minimumSize"
            label: qsTr("Minimum Font Size")
            display: P.TextFieldPreference.ExpandLabel
            defaultValue: 14
            from: 1
            to: 999
            stepSize: 1
            editable: true
            visible: pSizeMode.value
        }

        NoDefaultColorPreference {
            name: "color"
            label: qsTr("Color")
            defaultValue: ctx_widget.defaultTextColor
        }

        NoDefaultColorPreference {
            name: "hoveredColor"
            label: qsTr("Hovered Color")
            defaultValue: "transparent"
        }

        NoDefaultColorPreference {
            name: "pressedColor"
            label: qsTr("Pressed Color")
            defaultValue: "transparent"
        }

        P.SelectPreference {
            name: "style"
            label: qsTr("Style")
            defaultValue: 0
            model: [ qsTr("Normal"), qsTr("Outline"), qsTr("Raised"), qsTr("Sunken") ]
        }

        NoDefaultColorPreference {
            name: "styleColor"
            label: qsTr("Style Color")
            defaultValue: ctx_widget.defaultStyleColor
        }

        P.SelectPreference {
            name: "hAlign"
            label: qsTr("Horizontal Alignment")
            defaultValue: 0
            model: [ qsTr("Left"), qsTr("Right"), qsTr("Center") ]
        }

        P.SelectPreference {
            name: "vAlign"
            label: qsTr("Vertical Alignment")
            defaultValue: 0
            model: [ qsTr("Top"), qsTr("Bottom"), qsTr("Center") ]
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
    }

    Text {
        id: textSource
        anchors.fill: parent

        font: thiz.settings.font ? Qt.font(thiz.settings.font) : ctx_widget.defaultFont
        style: thiz.settings.style ?? Text.Normal
        styleColor: thiz.settings.styleColor ?? ctx_widget.defaultStyleColor
        lineHeight: (thiz.settings.lineHeight ?? 100) / 100
        fontSizeMode: thiz.settings.sizeMode ?? Text.FixedSize
        minimumPixelSize: thiz.settings.minimumSize ?? 14
        elide: Text.ElideRight
        // BUG: text area tracks MouseArea
        enabled: false

        wrapMode: { // disable text wrap to get correct multiline implicit width
            const align = craftElement.settings.alignment;
            const explicitWidth = (align & Qt.AlignLeft && align & Qt.AlignRight) ||
                                  (craftElement.settings.width !== undefined);
            return explicitWidth ? Text.Wrap : Text.NoWrap;
        }

        color: {
            if (thiz.pressed && pressedColor.a)
                return pressedColor;

            if (thiz.hovered && hoveredColor.a)
                return hoveredColor;

            return normalColor;
        }

        horizontalAlignment: {
            switch (thiz.settings.hAlign) {
                case 2: return Text.AlignHCenter;
                case 1: return Text.AlignRight;
                case 0:
                default: break;
            }
            return Text.AlignLeft;
        }

        verticalAlignment: {
            switch (thiz.settings.vAlign) {
                case 2: return Text.AlignVCenter;
                case 1: return Text.AlignBottom;
                case 0:
                default: break;
            }
            return Text.AlignTop;
        }

        text: {
            if (thiz.settings.mode)
                return displayText(output.result, displayUnit);

            return thiz.settings.text || thiz.elementLabel || thiz.defaultLabel;
        }

        textFormat: {
            switch (thiz.settings.format) {
            case 3: return Text.RichText;
            case 2: return Text.StyledText;
            case 1: return Text.PlainText;
            default: break;
            }
            return Text.AutoText;
        }
    }

    NVG.DataSourceTextOutput {
        id: output
        source: dataEnabled ? thiz.dataSource : null
        undefinedText: ""
        nullText: ""
        fixedDecimalDigits: thiz.settings.rounding ? (thiz.settings.decimal ?? 0) : -1
    }
}
