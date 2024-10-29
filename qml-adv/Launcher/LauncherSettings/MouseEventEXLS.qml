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
    contentHeight: mouseEventEXLS.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: mouseEventEXLS
        width: parent.width
        P.ObjectPreferenceGroup {
            defaultValue: current_default
            syncProperties: true
            width: parent.width
            //必须资源
            P.SelectPreference {
                name: "leftClickEvent"
                label: qsTr("Left Click")
                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                defaultValue: 3
            }
            P.SelectPreference {
                name: "rightClickEvent"
                label: qsTr("Right Click")
                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                defaultValue: 0
            }
            P.SelectPreference {
                name: "middleClickEvent"
                label: qsTr("Middle Click")
                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                defaultValue: 1
            }
            P.Separator{}
            P.SelectPreference {
                name: "leftClickEvent2"
                label: qsTr("Left Click") + " Ⅱ"
                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                defaultValue: 3
            }
            P.SelectPreference {
                name: "rightClickEvent2"
                label: qsTr("Right Click") + " Ⅱ"
                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                defaultValue: 3
            }
            P.SelectPreference {
                name: "middleClickEvent2"
                label: qsTr("Middle Click") + " Ⅱ"
                model: [ qsTr("Hide"), qsTr("Setting"), qsTr("Action"), qsTr("None") ]
                defaultValue: 3
            }
            P.Separator{}
            P.ActionPreference {
                name: "action_L"
                label: qsTr("Left Action")
            }
            P.ActionPreference {
                name: "action_R"
                label: qsTr("Right Action")
            }
            P.ActionPreference {
                name: "action_M"
                label: qsTr("Middle Action")
            }
        }
    }
}