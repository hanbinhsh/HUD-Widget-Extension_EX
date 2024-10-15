import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

//动作设置
//必须资源
Flickable {
    property var item: null
    id: aDVPreferenceGroup
    anchors.fill: parent
    contentWidth: width
    contentHeight: layoutADVSetting.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: layoutADVSetting
        width: parent.width
        P.ObjectPreferenceGroup {
            syncProperties: true
            enabled: item
            defaultValue: item
            width: parent.width
            //必须资源
            P.SwitchPreference {
                id: enableADV
                name: "enableADV"
                label: qsTr("Enable ADV")
            }
            P.ImagePreference {
                name: "aDVImage"
                label: qsTr("Image Source")
                visible: enableADV.value
            }
            P.SelectPreference {
                name: "aDVImageFill"
                label: qsTr("Fill Mode")
                model: [ qsTr("Stretch"), qsTr("Fit"), qsTr("Crop"), qsTr("Tile"), qsTr("Tile Vertically"), qsTr("Tile Horizontally"), qsTr("Pad") ]
                defaultValue: 1
                visible: enableADV.value
            }
            P.SwitchPreference {
                id: showADVImage
                name: "showADVImage"
                label: qsTr("Show Original Image")
                visible: enableADV.value
            }
            NoDefaultColorPreference {
                name: "aDVColor"
                label: qsTr("Color")
                defaultValue: "white"
                visible: enableADV.value
            }
            P.SpinPreference {
                name: "aDVPort"
                label: qsTr("Port")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableADV.value
                defaultValue: 5050
                from: 0
                to: 99999
                stepSize: 1
            }
            P.SpinPreference {
                name: "aDVZ"
                label: qsTr("Z")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableADV.value
                defaultValue: -1
                from: -999
                to: 999
                stepSize: 1
            }
            P.SelectPreference {
                name: "aDVSample"
                label: qsTr("Sample")
                model: [ qsTr("128"), qsTr("64"), qsTr("32"), qsTr("16"), qsTr("8"), qsTr("4") ]
                defaultValue: 0
                visible: enableADV.value
            }
            // 高斯模糊
            P.SwitchPreference {
                id: useADVGaussian
                name: "useADVGaussian"
                label: qsTr("Gaussian Blur")
                visible: enableADV.value
            }
            //半径
            P.SpinPreference {
                name: "aDVGaussianBlurRadius"
                label: " --- " + qsTr("Radius")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: useADVGaussian.value&&enableADV.value
                defaultValue: 5
                from: 0
                to: 500
                stepSize: 1
            }
            //偏差值
            P.SpinPreference {
                name: "aDVGaussianBlurDeviation"
                label: " --- " + qsTr("Deviation")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: useADVGaussian.value&&enableADV.value
                defaultValue: 3
                from: 0
                to: 1000
                stepSize: 1
            }
            //样本数
            P.SpinPreference {
                name: "aDVGaussianBlurSamples"
                label: " --- " + qsTr("Samples")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: useADVGaussian.value&&enableADV.value
                defaultValue: 5
                from: 0
                to: 100
                stepSize: 1
            }
            //透明边框
            P.SwitchPreference {
                name: "aDVDropShadowTransparentBorder"
                label: " --- " + qsTr("Transparent Border")
                visible: useADVGaussian.value&&enableADV.value
            }
            //缓存
            P.SwitchPreference {
                name: "aDVGaussianBlurCached"
                label: " --- " + qsTr("Cached")
                visible: useADVGaussian.value&&enableADV.value
            }
        }
    }
}