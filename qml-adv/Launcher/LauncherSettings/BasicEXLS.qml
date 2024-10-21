import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import QtQuick.Window 2.2

Flickable {
    property string itemName: ""
    anchors.fill: parent
    contentWidth: width
    contentHeight: basicEXLS.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: basicEXLS
        width: parent.width
        P.ObjectPreferenceGroup {
            defaultValue: eXLauncherView.eXLSettings
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
                        defaultValue: eXLauncherView.eXLSettings
                        P.SpinPreference {
                            name: itemName + "viewX"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: 0
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                        P.SpinPreference {
                            name: itemName + "viewY"
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
                        defaultValue: eXLauncherView.eXLSettings
                        P.SpinPreference {
                            name: itemName + "viewW"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            defaultValue: Screen.width
                            from: -99999
                            to: 99999
                            stepSize: 5
                        }
                        P.SpinPreference {
                            name: itemName + "viewH"
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
                name: itemName + "viewZ"
                label: qsTr("EXL Z")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 0
                from: -9999
                to: 9999
                stepSize: 1
            }
            P.SpinPreference {
                name: itemName + "viewO"
                label: qsTr("Max Opacity")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 100
                from: 0
                to: 100
                stepSize: 5
            }
            P.ColorPreference {
                name: itemName + "viewBGColor"
                label: qsTr("Background Color")
                defaultValue: "#777777"
            }
        }
    }
}