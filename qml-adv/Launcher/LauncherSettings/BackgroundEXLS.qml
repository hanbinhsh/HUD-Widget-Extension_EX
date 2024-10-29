import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

Flickable {
    property var current_default: eXLauncherView.eXLSettings
    anchors.fill: parent
    contentWidth: width
    contentHeight: backgroundEXLS.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: backgroundEXLS
        width: parent.width
        P.ObjectPreferenceGroup {
            defaultValue: current_default
            syncProperties: true
            width: parent.width
            //必须资源
            P.ImagePreference {
                name: "viewBGImage"
                label: qsTr("Image")
            }
            P.SelectPreference {
                name: "viewBGImageFill"
                label: qsTr("Fill Mode")
                model: [ qsTr("Stretch"), qsTr("Fit"), qsTr("Crop"), qsTr("Tile"), qsTr("Tile Vertically"), qsTr("Tile Horizontally"), qsTr("Pad") ]
                defaultValue: 1
            }
            Row{
                spacing: 8
                Column {
                    Label {
                        text: qsTr("X Y")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        defaultValue: current_default
                        P.SpinPreference {
                            name: "viewBGX"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                        P.SpinPreference {
                            name: "viewBGY"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                    }
                }
                Column {
                    Label {
                        text: qsTr("W H")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        defaultValue: current_default
                        P.SpinPreference {
                            name: "viewBGW"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: Screen.width
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                        P.SpinPreference {
                            name: "viewBGH"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: Screen.height
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                    }
                }
            }
            P.SpinPreference {
                name: "viewBGZ"
                label: qsTr("Image Z")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 0
                from: -9999
                to: 9999
                stepSize: 1
            }
            P.SpinPreference {
                name: "viewBGImageOpacity"
                label: qsTr("Image Opacity")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 100
                from: 0
                to: 100
                stepSize: 5
            }
            P.SwitchPreference {
                name: "hideOriginal"
                label: qsTr("Hide Original")
            }
            P.Separator{}
            P.SwitchPreference {
                id: colorOverlay
                name: "colorOverlay"
                label: qsTr("Color Overlay")
            }
            P.ColorPreference {
                name: "overlayColor"
                label: " --- " + qsTr("Color")
                defaultValue: "transparent"
                visible: colorOverlay.value
            }
            P.SpinPreference {
                name: "overlayColorZ"
                label: " --- " + qsTr("Overlay Z")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 0
                from: -9999
                to: 9999
                stepSize: 1
                visible: colorOverlay.value
            }
            P.SpinPreference {
                name: "overlayColorOpacity"
                label: " --- " + qsTr("Overlay Opacity")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 100
                from: 0
                to: 100
                stepSize: 5
                visible: colorOverlay.value
            }
            P.Separator{}
            P.SwitchPreference {
                id: enableEXLADV
                name: "enableEXLADV"
                label: qsTr("Enable ADV")
            }
            P.ColorPreference {
                name: "eXLADVColor"
                label: " --- " + qsTr("Color")
                defaultValue: "white"
                visible: enableEXLADV.value
            }
            P.SpinPreference {
                name: "eXLADVZ"
                label: " --- " + qsTr("Z")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableEXLADV.value
                defaultValue: -1
                from: -999
                to: 999
                stepSize: 1
            }
            P.SpinPreference {
                name: "eXLADVDecrease"
                label: " --- " + qsTr("Decrease")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableEXLADV.value
                defaultValue: 1000
                from: 100
                to: 100000
                stepSize: 100
            }
        }
    }
}