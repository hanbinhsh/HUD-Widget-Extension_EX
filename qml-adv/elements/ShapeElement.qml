import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

HUDElementTemplate {
    id:  thiz

    readonly property color colorFN: settings.fillStyle  ?? "white"
    readonly property color colorFH: settings.fillStyleH ?? colorFN
    readonly property color colorFP: settings.fillStyleP ?? colorFH
    readonly property color colorON: settings.strokeStyle  ?? "black"
    readonly property color colorOH: settings.strokeStyleH ?? colorON
    readonly property color colorOP: settings.strokeStyleP ?? colorOH

    readonly property var fillDataOutput: lazyDataOutput(settings.fillData, "fdo_NB")
    readonly property var strokeDataOutput: lazyDataOutput(settings.strokeData, "sdo_NB")

    function lazyDataOutput(config, prop) {
        if (config) { // create data source and output
            if (!this[prop]) {
                Object.defineProperty(this, prop, {
                                          value: cDataRawOutput.createObject(thiz),
                                          configurable: true
                                      });
            }
            this[prop].source.configuration = config;
        } else { // clean up data source and output
            if (this[prop]) {
                this[prop].destroy();
                delete this[prop];
            }
        }
        return this[prop];
    }

    title: qsTranslate("utils", "Rectangle")
    implicitWidth: 32
    implicitHeight: 32

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

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

        NoDefaultColorPreference {
            name: "fillStyle"
            label: qsTr("Fill Color")
            defaultValue: "white"
            enabled: !pFillData.value
        }

        NoDefaultColorPreference {
            name: "fillStyleH"
            label: "- " + qsTr("Hovered Color")
            defaultValue: "transparent"
            enabled: !pFillData.value
        }

        NoDefaultColorPreference {
            name: "fillStyleP"
            label: "- " + qsTr("Pressed Color")
            defaultValue: "transparent"
            enabled: !pFillData.value
        }

        P.DataPreference {
            id: pFillData
            name: "fillData"
            label: qsTr("Fill Color Data")
        }

        P.SpinPreference {
            name: "lineWidth"
            label: qsTr("Line Size")
            defaultValue: 0
            from: 0
            to: 32
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        NoDefaultColorPreference {
            name: "strokeStyle"
            label: qsTr("Line Color")
            defaultValue: "black"
            enabled: !pStrokeData.value
        }

        NoDefaultColorPreference {
            name: "strokeStyleH"
            label: "- " + qsTr("Hovered Color")
            defaultValue: "transparent"
            enabled: !pStrokeData.value
        }

        NoDefaultColorPreference {
            name: "strokeStyleP"
            label: "- " + qsTr("Pressed Color")
            defaultValue: "transparent"
            enabled: !pStrokeData.value
        }

        P.DataPreference {
            id: pStrokeData
            name: "strokeData"
            label: qsTr("Line Color Data")
        }
    }

    Rectangle {
        anchors.fill: parent
        // adaptive radius unit
        radius: thiz.settings.radius <= 50 ? thiz.settings.radius :
                    Math.min(width, height) * 0.005 * (thiz.settings.radius - 50)
        color: {
            if (fillDataOutput)
                return fillDataOutput.result;

            return itemPressed ? colorFP : itemHovered ? colorFH : colorFN;
        }
        border {
            width: thiz.settings.lineWidth ?? 0
            color: {
                if (strokeDataOutput)
                    return strokeDataOutput.result;
                return itemPressed ? colorOP : itemHovered ? colorOH : colorON;
            }
        }
    }
}
