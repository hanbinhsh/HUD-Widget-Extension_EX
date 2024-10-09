import QtQuick 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

//变换
Item{
    property var item: null
    id: transformPreferenceGroup
    height: layoutTransform.height
    //必须资源
    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: layoutTransform.height
        topMargin: 16
        bottomMargin: 16
        Column {
            id: layoutTransform
            width: parent.width
            P.ObjectPreferenceGroup {
                syncProperties: true
                enabled: item
                defaultValue: item
                width: parent.width
                //必须资源
                //透明度设置
                //透明度设置开关
                P.SwitchPreference {
                    id: opacitySettings
                    name: "opacitySettings"
                    label: qsTr("Opacity Setting")
                    visible: expandButton.highlighted
                }
                //透明度
                P.SliderPreference {
                    name: "opacity"
                    label: " - " + qsTr("Opacity")
                    displayValue: Math.round(value * 100) + " %"
                    defaultValue: 1
                    from: 0
                    to: 1
                    stepSize: 0.01
                    live: true
                    visible: expandButton.highlighted&&opacitySettings.value&&!enableOpacityAnimation.value
                }
                //透明度动画
                P.SwitchPreference {
                    id: enableOpacityAnimation
                    name: "enableOpacityAnimation"
                    label: " - " + qsTr("Opacity Animation")
                    visible: expandButton.highlighted&&opacitySettings.value
                }
                //速度
                P.SpinPreference {
                    name: "opacityAnimationSpeed"
                    label: " - - " + qsTr("Speed")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableOpacityAnimation.value&&opacitySettings.value
                    defaultValue: 500
                    from: 0
                    to: 10000
                    stepSize: 100
                }
                //旋转设置
                //旋转设置开关
                P.SwitchPreference {
                    id: rotationSettings
                    name: "rotationSettings"
                    label: qsTr("Rotation Setting")
                    visible: expandButton.highlighted
                }
                //旋转
                P.SliderPreference {
                    name: "rotation"
                    label: " - " + qsTr("Rotation")
                    displayValue: value + " °"
                    defaultValue: 0
                    from: -360
                    to: 360
                    stepSize: 1
                    live: true
                    visible: expandButton.highlighted&&!rotationDisplay.value&&rotationSettings.value
                }
                //旋转动画开关
                P.SwitchPreference {
                    id: rotationDisplay
                    name: "rotationDisplay"
                    label: " - " + qsTr("Auto Rotation")
                    visible: expandButton.highlighted&&rotationSettings.value
                }
                //转速
                P.SliderPreference {
                    id:rotationSpeed
                    name: "rotationSpeed"
                    label: " - " + qsTr("Spin Speed")
                    defaultValue: 5
                    from: -500
                    to: 500
                    stepSize: 1
                    displayValue: value + " RPM"
                    live: true
                    visible: expandButton.highlighted&&rotationDisplay.value&&rotationSettings.value
                }
                //旋转FPS
                P.SliderPreference {
                    id:rotationFPS
                    name: "rotationFPS"
                    label: " - " + qsTr("FPS")
                    defaultValue: 20
                    from: 1
                    to: 240
                    stepSize: 1
                    displayValue: value + " FPS"
                    live: true
                    visible: expandButton.highlighted&&rotationDisplay.value&&rotationSettings.value
                }
                //高级旋转
                P.SwitchPreference {
                    id: enableAdvancedRotation
                    name: "enableAdvancedRotation"
                    label: " - " + qsTr("Advanced Rotation")
                    visible: rotationSettings.value
                }
                //旋转原点X
                P.SpinPreference {
                    name: "advancedRotationOriginX"
                    label: " - - " + qsTr("Origin X")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableAdvancedRotation.value&&rotationSettings.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
                //旋转原点Y
                P.SpinPreference {
                    name: "advancedRotationOriginY"
                    label: " - - " + qsTr("Origin Y")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableAdvancedRotation.value&&rotationSettings.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
                //axis x,y,z
                P.SpinPreference {
                    name: "advancedRotationAxisX"
                    label: " - - " + qsTr("Axis X")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableAdvancedRotation.value&&rotationSettings.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
                P.SpinPreference {
                    name: "advancedRotationAxisY"
                    label: " - - " + qsTr("Axis Y")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableAdvancedRotation.value&&rotationSettings.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
                P.SpinPreference {
                    name: "advancedRotationAxisZ"
                    label: " - - " + qsTr("Axis Z")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableAdvancedRotation.value&&rotationSettings.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
                //角度
                P.SpinPreference {
                    name: "advancedRotationAngle"
                    label: " - - " + qsTr("Angle")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableAdvancedRotation.value&&!enableAdvancedRotationAnimation.value&&rotationSettings.value
                    defaultValue: 0
                    from: -360
                    to: 360
                    stepSize: 10
                }
                //角度变化动画
                P.SwitchPreference {
                    id: enableAdvancedRotationAnimation
                    name: "enableAdvancedRotationAnimation"
                    label: " - - " + qsTr("Rotation Animation")
                    visible: enableAdvancedRotation.value&&rotationSettings.value
                }
                //速度
                P.SpinPreference {
                    name: "advancedRotationSpeed"
                    label: " - - - " + qsTr("Speed")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableAdvancedRotationAnimation.value&&enableAdvancedRotation.value&&rotationSettings.value
                    defaultValue: 20
                    from: -100
                    to: 100
                    stepSize: 5
                }
                //FPS
                P.SpinPreference {
                    name: "advancedRotationFPS"
                    label: " - - - " + qsTr("FPS")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: enableAdvancedRotationAnimation.value&&enableAdvancedRotation.value&&rotationSettings.value
                    defaultValue: 20
                    from: 1
                    to: 240
                    stepSize: 10
                }
                //缩放
                P.SwitchPreference {
                    id: scaleSetting
                    name: "scaleSetting"
                    label: qsTr("Scale")
                }
                //缩放原点X
                P.SpinPreference {
                    name: "scaleOriginX"
                    label: " - " + qsTr("Origin X")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: scaleSetting.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
                //缩放原点Y
                P.SpinPreference {
                    name: "scaleOriginY"
                    label: " - " + qsTr("Origin Y")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: scaleSetting.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
                //x比例 /1000
                P.SpinPreference {
                    name: "scaleX"
                    label: " - " + qsTr("X Scale")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: scaleSetting.value
                    defaultValue: 1000
                    from: -100000
                    to: 100000
                    stepSize: 50
                }
                //y比例 /1000
                P.SpinPreference {
                    name: "scaleY"
                    label: " - " + qsTr("Y Scale")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: scaleSetting.value
                    defaultValue: 1000
                    from: -100000
                    to: 100000
                    stepSize: 50
                }
                //平移
                P.SwitchPreference {
                    id: translateSetting
                    name: "translateSetting"
                    label: qsTr("Translate")
                }
                //X偏移量
                P.SpinPreference {
                    name: "translateX"
                    label: " - " + qsTr("X")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: translateSetting.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
                //Y偏移量
                P.SpinPreference {
                    name: "translateY"
                    label: " - " + qsTr("Y")
                    editable: true
                    display: P.TextFieldPreference.ExpandLabel
                    visible: translateSetting.value
                    defaultValue: 0
                    from: -10000
                    to: 10000
                    stepSize: 10
                }
            }
        }
    }
}