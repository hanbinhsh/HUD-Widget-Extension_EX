import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import "../.."

Flickable {
    property var current_default: eXLauncherView.eXLSettings
    anchors.fill: parent
    contentWidth: width
    contentHeight: basicEXLS.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: basicEXLS
        width: parent.width
        P.ObjectPreferenceGroup {
            defaultValue: current_default
            syncProperties: true
            width: parent.width
            //必须资源
            Row{
                spacing: 8
                Column {
                    Label {
                        text: qsTr("X   Y")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        defaultValue: current_default
                        P.SpinPreference {
                            name: "viewX"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                        P.SpinPreference {
                            name: "viewY"
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
                        text: qsTr("W   H")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        defaultValue: current_default
                        P.SpinPreference {
                            name: "viewW"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 2048
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                        P.SpinPreference {
                            name: "viewH"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 1152
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                    }
                }
            }
            P.SpinPreference {
                name: "viewZ"
                label: qsTr("EXL Z")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 0
                from: -9999
                to: 9999
                stepSize: 1
            }
            P.SpinPreference {
                name: "viewO"
                label: qsTr("Max Opacity")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 100
                from: 0
                to: 100
                stepSize: 5
            }
            P.ColorPreference {
                name: "viewBGColor"
                label: qsTr("Background Color")
                defaultValue: "#777777"
            }
            P.ObjectPreferenceGroup {
                defaultValue: current_default
                syncProperties: true
                width: parent.width
                data: PreferenceGroupIndicator { anchors.topMargin: aDVConnection.height; visible: aDVConnection.value; color: "#4a4a4a" }
                P.SwitchPreference {
                    id: aDVConnection
                    name: "aDVConnection"
                    label: qsTr("ADV Connection")
                }
                P.SelectPreference {
                    name: "eXLADVSample"//全局
                    label: qsTr("Sample")
                    model: [ qsTr("128"), qsTr("64"), qsTr("32"), qsTr("16"), qsTr("8"), qsTr("4") ]
                    defaultValue: 0
                    visible: aDVConnection.value
                }
            }
        }
    }
}