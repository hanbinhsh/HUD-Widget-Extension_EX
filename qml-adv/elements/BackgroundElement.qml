import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

HUDElementTemplate {
    id:  thiz

    readonly property color normalColor: settings.color ?? ctx_widget.defaultBackgroundColor
    readonly property color hoveredColor: settings.hoveredColor ?? "transparent"
    readonly property color pressedColor: settings.pressedColor ?? "transparent"

    title: qsTranslate("utils", "Background")
    implicitWidth: backgroundSource.implicitWidth
    implicitHeight: backgroundSource.implicitHeight

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SwitchPreference {
            id: pSolid
            name: "solid"
            label: qsTr("Solid Color")
            defaultValue: false
            visible: value // deprecated, use ShapeElement
        }

        P.BackgroundPreference {
            name: "background"
            label: qsTr("Background")
            defaultValue: ctx_widget.defaultBackground
            defaultBackground: backgroundSource.defaultBackground
            visible: !pSolid.value
        }

        NoDefaultColorPreference {
            name: "color"
            label: qsTr("Color")
            defaultValue: ctx_widget.defaultBackgroundColor
            enabled: !pColorData.value
        }

        NoDefaultColorPreference {
            name: "hoveredColor"
            label: qsTr("Hovered Color")
            defaultValue: "transparent"
            enabled: !pColorData.value
        }

        NoDefaultColorPreference {
            name: "pressedColor"
            label: qsTr("Pressed Color")
            defaultValue: "transparent"
            enabled: !pColorData.value
        }

        P.DataPreference {
            id: pColorData
            name: "colorData"
            label: qsTr("Color Data")
        }
    }

    ColorBackgroundSource {
        id: backgroundSource
        anchors.fill: parent

        configuration: thiz.settings.solid ? { normal: "" } :
                           thiz.settings.background ?? ctx_widget.defaultBackground
        defaultBackground: craftElement.itemBackground.defaultBackground
        color: {
            if (dataSource.configuration)
                return output.result;

            if (thiz.itemPressed && pressedColor.a)
                return pressedColor;

            if (thiz.itemHovered && hoveredColor.a)
                return hoveredColor;

            return normalColor;
        }
        visible: !thiz.settings.solid
        hovered: thiz.itemHovered
        pressed: thiz.itemPressed
    }

    Rectangle {
        anchors.fill: parent
        visible: !backgroundSource.visible
        color: backgroundSource.color
    }

    NVG.DataSource {
        id: dataSource
        configuration: thiz.settings.colorData
    }

    NVG.DataSourceRawOutput { id: output; source: dataSource }
}
