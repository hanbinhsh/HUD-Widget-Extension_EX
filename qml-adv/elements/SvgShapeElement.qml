import QtQuick 2.12
import QtQuick.Shapes 1.2

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

HUDElementTemplate {
    id:  thiz

    readonly property string defaultShapePath: "M30,10 v44 h4 v-44 z\nM10,30 h44 v4 h-44"

    title: qsTr("SVG Shape")
    implicitWidth: 64
    implicitHeight: 64

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.TextAreaPreference {
            name: "path"
            label: qsTr("Path")
            defaultValue: defaultShapePath
        }

        P.ColorPreference {
            name: "strokeColor"
            label: qsTr("Line Color")
            defaultValue: "transparent"
        }

        P.ColorPreference {
            name: "fillColor"
            label: qsTr("Fill Color")
            defaultValue: "#E91E63"
        }

        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Line Size")
            defaultValue: 1
            from: 0
            to: 100
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
    }

    Shape {
        anchors.fill: parent

//        layer.enabled: true
//        layer.samples: 4
        ShapePath {
            joinStyle: ShapePath.RoundJoin
            strokeWidth: thiz.settings.strokeSize ?? 1
            strokeColor: thiz.settings.strokeColor ?? "transparent"
            fillColor: thiz.settings.fillColor ?? "#E91E63"
            PathSvg { path: thiz.settings.path ?? defaultShapePath }
        }
    }
}
