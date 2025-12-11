import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

//必须资源
Flickable {
    property var item: null
    id: showMaskPreferenceGroup
    anchors.fill: parent
    contentWidth: width
    contentHeight: displayMaskSetting.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: displayMaskSetting
        width: parent.width
        P.ObjectPreferenceGroup {
            syncProperties: true
            enabled: item
            width: parent.width
            defaultValue: item
            data: PreferenceGroupIndicator { anchors.topMargin: usedisplayMask.height; visible: usedisplayMask.value }
            //必须资源
            //显示时的遮罩
            P.SwitchPreference {
                id: usedisplayMask
                name: "usedisplayMask"
                label: qsTr("Show Mask")
            }
            P.SwitchPreference {
                name: "maskVisibleAfterAnimation"
                label: qsTr("Display Mask After Animation")
                defaultValue: true
                visible: usedisplayMask.value
            }
            P.ImagePreference {
                name: "displayMaskSource"
                label: qsTr("Mask Image")
                visible: usedisplayMask.value
            }
            P.SelectPreference {
                name: "displayMaskFill"
                label: qsTr("Fill Mode")
                model: [ qsTr("Stretch"), qsTr("Fit"), qsTr("Crop"), qsTr("Tile"), qsTr("Tile Vertically"), qsTr("Tile Horizontally"), qsTr("Pad") ]
                defaultValue: 1
                visible: usedisplayMask.value
            }
            P.SpinPreference {
                name: "maskOpacity"
                label: qsTr("Mask Opacity")
                editable: true
                defaultValue: 100
                from: 0
                to: 100
                stepSize: 5
                display: P.TextFieldPreference.ExpandLabel
                visible: usedisplayMask.value
            }
            P.SpinPreference {
                name: "maskRotation"
                label: qsTr("Mask Rotation")
                editable: true
                defaultValue: 0
                from: -360
                to: 360
                stepSize: 1
                display: P.TextFieldPreference.ExpandLabel
                visible: usedisplayMask.value
            }
            Row{
                spacing: 8
                visible: usedisplayMask.value
                Column {
                    Label {
                        text: qsTr("X & Y")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        enabled: item
                        defaultValue: item
                        P.SpinPreference {
                            name: "displayMaskTranslateX"
                            editable: true
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 1
                            display: P.TextFieldPreference.ExpandLabel
                        }
                        P.SpinPreference {
                            name: "displayMaskTranslateY"
                            editable: true
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 1
                            display: P.TextFieldPreference.ExpandLabel
                        }
                    }
                }
                Column {
                    Label {
                        text: qsTr("Height & Width")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        enabled: item
                        defaultValue: item
                        P.SpinPreference {
                            name: "displayMaskTranslateScaleHeight"
                            editable: true
                            defaultValue: 54
                            from: 0
                            to: 10000
                            stepSize: 1
                            display: P.TextFieldPreference.ExpandLabel
                        }
                        P.SpinPreference {
                            name: "displayMaskTranslateScaleWidth"
                            editable: true
                            defaultValue: 54
                            from: 0
                            to: 10000
                            stepSize: 1
                            display: P.TextFieldPreference.ExpandLabel
                        }
                    }
                }
            }
            P.SpinPreference {
                name: "displayMaskTime"
                label: qsTr("Display Mask Time")
                editable: true
                defaultValue: 250
                from: 0
                to: 10000
                stepSize: 50
                display: P.TextFieldPreference.ExpandLabel
                visible: usedisplayMask.value
            }
            P.SpinPreference {
                name: "hideMaskTime"
                label: qsTr("Hide Mask Time")
                editable: true
                defaultValue: 250
                from: 0
                to: 10000
                stepSize: 50
                display: P.TextFieldPreference.ExpandLabel
                visible: usedisplayMask.value
            }
        }
    }
}