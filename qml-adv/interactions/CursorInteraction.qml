import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

HUDInteractionTemplate {
    id: thiz

    readonly property var normalImage: settings.normal ?? ""
    readonly property var hoveredImage: settings.hovered ?? normalImage
    readonly property var pressedImage: settings.pressed ?? hoveredImage

    readonly property real hotspotX: settings.hotspotX ?? (cursorImage.width  / 2)
    readonly property real hotspotY: settings.hotspotY ?? (cursorImage.height / 2)

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.ImagePreference {
            name: "normal"
            label: qsTr("Cursor Image")
        }
        //        P.ImagePreference {
        //            name: "hovered"
        //            label: qsTr("Hovered")
        //        }

        //        P.ImagePreference {
        //            name: "pressed"
        //            label: qsTr("Pressed")
        //        }
        Transform2DimensionControl {
            text: qsTr("Cursor Size")

            xGeometryLabel: qsTr("Width")
            xGeometryInput {
                valueText: thiz.settings.width ?? ""
                placeholderText: Math.round(cursorImage.implicitWidth)
                onUpdateValue: thiz.settings.width = value
            }

            yGeometryLabel: qsTr("Height")
            yGeometryInput {
                valueText: thiz.settings.height ?? ""
                placeholderText: Math.round(cursorImage.implicitHeight)
                onUpdateValue: thiz.settings.height = value
            }
        }

        Transform2DimensionControl {
            text: qsTr("Cursor Hot Spot")

            xGeometryInput {
                valueText: thiz.settings.hotspotX ?? ""
                placeholderText: Math.round(cursorImage.width / 2)
                onUpdateValue: thiz.settings.hotspotX = value
            }

            yGeometryInput {
                valueText: thiz.settings.hotspotY ?? ""
                placeholderText: Math.round(cursorImage.height / 2)
                onUpdateValue: thiz.settings.hotspotY = value
            }
        }
    }

    contentParent: mouseArea

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        receiveChildHoverMoveEvents: true
        acceptedButtons: Qt.NoButton
        cursorShape: normalImage ? Qt.BlankCursor : undefined
    }

    NVG.ImageSource {
        id: cursorImage
        x: mouseArea.mouseX - hotspotX
        y: mouseArea.mouseY - hotspotY
        z: 1
        width: thiz.settings.width
        height: thiz.settings.height
        visible: mouseArea.containsMouse
        fillMode: Image.PreserveAspectFit
        playing: status === Image.Ready
        configuration: normalImage
    }
}

