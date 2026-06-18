import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

import "../.."

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
                        SpinPreferenceEx {
                            name: "viewBGX"
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                        SpinPreferenceEx {
                            name: "viewBGY"
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
                        SpinPreferenceEx {
                            name: "viewBGW"
                            defaultValue: Screen.width
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                        SpinPreferenceEx {
                            name: "viewBGH"
                            defaultValue: Screen.height
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                    }
                }
            }
            SpinPreferenceEx {
                name: "viewBGZ"
                label: qsTr("Image Z")
                defaultValue: 0
                from: -9999
                to: 9999
                stepSize: 1
            }
            SpinPreferenceEx {
                name: "viewBGImageOpacity"
                label: qsTr("Image Opacity")
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
            P.ObjectPreferenceGroup {
                defaultValue: current_default
                syncProperties: true
                width: parent.width
                data: PreferenceGroupIndicator { toggle: colorOverlay; color: "#4a4a4a" }
                P.SwitchPreference {
                    id: colorOverlay
                    name: "colorOverlay"
                    label: qsTr("Color Overlay")
                }
                P.ColorPreference {
                    name: "overlayColor"
                    label: qsTr("Color")
                    defaultValue: "transparent"
                    visible: colorOverlay.value
                }
                SpinPreferenceEx {
                    name: "overlayColorZ"
                    label: qsTr("Overlay Z")
                    defaultValue: 0
                    from: -9999
                    to: 9999
                    stepSize: 1
                    visible: colorOverlay.value
                }
                SpinPreferenceEx {
                    name: "overlayColorOpacity"
                    label: qsTr("Overlay Opacity")
                    defaultValue: 100
                    from: 0
                    to: 100
                    stepSize: 5
                    visible: colorOverlay.value
                }
            }
            P.Separator{}
            P.ObjectPreferenceGroup {
                defaultValue: current_default
                syncProperties: true
                width: parent.width
                data: PreferenceGroupIndicator { toggle: enableEXLADV; color: "#4a4a4a" }
                P.SwitchPreference {
                    id: enableEXLADV
                    name: "enableEXLADV"
                    label: qsTr("Enable ADV")
                }
                P.ColorPreference {
                    name: "eXLADVColor"
                    label: qsTr("Color")
                    defaultValue: "white"
                    visible: enableEXLADV.value
                }
                SpinPreferenceEx {
                    name: "eXLADVZ"
                    label: qsTr("Z")
                    visible: enableEXLADV.value
                    defaultValue: -1
                    from: -999
                    to: 999
                    stepSize: 1
                }
                SpinPreferenceEx {
                    name: "eXLADVDecrease"
                    label: qsTr("Decrease")
                    visible: enableEXLADV.value
                    defaultValue: 1000
                    from: 100
                    to: 100000
                    stepSize: 100
                }
            }
        }
    }
}