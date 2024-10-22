import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."

//变换
//必须资源
Flickable {
    property var item: null
    id: transformPreferenceGroup
    anchors.fill: parent
    contentWidth: width
    contentHeight: layoutTransformSetting.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: layoutTransformSetting
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
            }
            //透明度
            P.SliderPreference {
                name: "opacity"
                label: " --- " + qsTr("Opacity")
                displayValue: Math.round(value * 100) + " %"
                defaultValue: 1
                from: 0
                to: 1
                stepSize: 0.01
                live: true
                visible: opacitySettings.value&&!enableOpacityAnimation.value
            }
            //透明度动画
            P.SwitchPreference {
                id: enableOpacityAnimation
                name: "enableOpacityAnimation"
                label: " --- " + qsTr("Opacity Animation")
                visible: opacitySettings.value
            }
            //速度
            P.SpinPreference {
                name: "opacityAnimationSpeed"
                label: " --- --- " + qsTr("Speed")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableOpacityAnimation.value&&opacitySettings.value
                defaultValue: 500
                from: 0
                to: 10000
                stepSize: 100
            }
            P.Separator{}
            //旋转设置
            //旋转设置开关
            P.SwitchPreference {
                id: rotationSettings
                name: "rotationSettings"
                label: qsTr("Rotation Setting")
            }
            //旋转
            P.SliderPreference {
                name: "rotation"
                label: " --- " + qsTr("Rotation")
                displayValue: value + " °"
                defaultValue: 0
                from: -360
                to: 360
                stepSize: 1
                live: true
                visible: !rotationDisplay.value&&rotationSettings.value
            }
            //旋转动画开关
            P.SwitchPreference {
                id: rotationDisplay
                name: "rotationDisplay"
                label: " --- " + qsTr("Auto Rotation")
                visible: rotationSettings.value
            }
            //转速
            P.SliderPreference {
                id:rotationSpeed
                name: "rotationSpeed"
                label: " --- --- " + qsTr("Spin Speed")
                defaultValue: 5
                from: -500
                to: 500
                stepSize: 1
                displayValue: value + " RPM"
                live: true
                visible: rotationDisplay.value&&rotationSettings.value
            }
            //旋转FPS
            P.SliderPreference {
                id:rotationFPS
                name: "rotationFPS"
                label: " --- --- " + qsTr("FPS")
                defaultValue: 20
                from: 1
                to: 240
                stepSize: 1
                displayValue: value + " FPS"
                live: true
                visible: rotationDisplay.value&&rotationSettings.value
            }
            //高级旋转
            P.SwitchPreference {
                id: enableAdvancedRotation
                name: "enableAdvancedRotation"
                label: " --- " + qsTr("Advanced Rotation")
                visible: rotationSettings.value
            }
            Row{
                spacing: 8
                visible: enableAdvancedRotation.value&&rotationSettings.value
                Column {
                    Label {
                        text: qsTr("X & Y Origin & Angle")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        enabled: item
                        defaultValue: item
                        //旋转原点X
                        P.SpinPreference {
                            name: "advancedRotationOriginX"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: enableAdvancedRotation.value&&rotationSettings.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 1
                        }
                        //旋转原点Y
                        P.SpinPreference {
                            name: "advancedRotationOriginY"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: enableAdvancedRotation.value&&rotationSettings.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 1
                        }
                        //角度
                        P.SpinPreference {
                            name: "advancedRotationAngle"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: enableAdvancedRotation.value&&!enableAdvancedRotationAnimation.value&&rotationSettings.value
                            defaultValue: 0
                            from: -360
                            to: 360
                            stepSize: 1
                        }
                    }
                }
                Column {
                    Label {
                        text: qsTr("Axis X & Y & Z")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        enabled: item
                        defaultValue: item
                        //axis x,y,z
                        P.SpinPreference {
                            name: "advancedRotationAxisX"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: enableAdvancedRotation.value&&rotationSettings.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 1
                        }
                        P.SpinPreference {
                            name: "advancedRotationAxisY"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: enableAdvancedRotation.value&&rotationSettings.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 1
                        }
                        P.SpinPreference {
                            name: "advancedRotationAxisZ"
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: enableAdvancedRotation.value&&rotationSettings.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 1
                        }
                    }
                }
            }
            //角度变化动画
            P.SwitchPreference {
                id: enableAdvancedRotationAnimation
                name: "enableAdvancedRotationAnimation"
                label: " --- --- " + qsTr("3D Rotation Animation")
                visible: enableAdvancedRotation.value&&rotationSettings.value
            }
            //速度
            P.SpinPreference {
                name: "advancedRotationSpeed"
                label: " --- --- --- " + qsTr("Speed")
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
                label: " --- --- --- " + qsTr("FPS")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: enableAdvancedRotationAnimation.value&&enableAdvancedRotation.value&&rotationSettings.value
                defaultValue: 20
                from: 1
                to: 240
                stepSize: 10
            }
            P.Separator{}
            //缩放
            P.SwitchPreference {
                id: scaleSetting
                name: "scaleSetting"
                label: qsTr("Scale")
            }
            Row{
                spacing: 8
                visible: scaleSetting.value
                Column {
                    Label {
                        text: qsTr("X & Y Origin")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        enabled: item
                        defaultValue: item
                        //缩放原点X
                        P.SpinPreference {
                            name: "scaleOriginX"
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
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: scaleSetting.value
                            defaultValue: 0
                            from: -10000
                            to: 10000
                            stepSize: 10
                        }
                    }
                }
                Column {
                    Label {
                        text: qsTr("X & Y Scale")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    P.ObjectPreferenceGroup {
                        syncProperties: true
                        enabled: item
                        defaultValue: item
                        //x比例 /1000
                        P.SpinPreference {
                            name: "scaleX"
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
                            editable: true
                            display: P.TextFieldPreference.ExpandLabel
                            visible: scaleSetting.value
                            defaultValue: 1000
                            from: -100000
                            to: 100000
                            stepSize: 50
                        }
                    }
                }
            }
            P.Separator{}
            //平移
            P.SwitchPreference {
                id: translateSetting
                name: "translateSetting"
                label: qsTr("Translate")
            }
            //X偏移量
            P.SpinPreference {
                name: "translateX"
                label: " --- " + qsTr("X")
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
                label: " --- " + qsTr("Y")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: translateSetting.value
                defaultValue: 0
                from: -10000
                to: 10000
                stepSize: 10
            }
            P.Separator{}
            //周期动画
            P.SwitchPreference {
                id: cycleAnimation
                name: "cycleAnimation"
                label: qsTr("Cycle Animation")
            }
        //周期平移
            P.SwitchPreference {
                id: cycleMove
                name: "cycleMove"
                label: " --- " + qsTr("Cycle Moving")
                visible:cycleAnimation.value
            }
            //距离
            P.SpinPreference {
                name: "moveCycle_Distance"
                label: " --- --- " + qsTr("Distance")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: cycleAnimation.value&&cycleMove.value
                defaultValue: 10
                from: -1000
                to: 1000
                stepSize: 10
            }
            //方向
            P.SpinPreference {
                name: "moveCycle_Direction"
                label: " --- --- " + qsTr("Direction")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: cycleAnimation.value&&cycleMove.value
                defaultValue: 0
                from: -180
                to: 180
                stepSize: 5
            }
            //持续时间
            P.SpinPreference {
                name: "moveCycle_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: cycleAnimation.value&&cycleMove.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //延时
            P.SpinPreference {
                name: "moveCycle_Delay"
                label: " --- --- " + qsTr("Delay")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: cycleAnimation.value&&cycleMove.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //等待时间
            P.SpinPreference {
                name: "moveCycle_Waiting"
                label: " --- --- " + qsTr("Waiting")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: cycleAnimation.value&&cycleMove.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "moveCycle_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: cycleAnimation.value&&cycleMove.value
            }
            P.Separator{}
        //数据控制的动画
            P.SwitchPreference {
                id: dataAnimation
                name: "dataAnimation"
                label: qsTr("Data Animation")
            }
            // 数据移动动画
            P.SwitchPreference {
                id: dataAnimation_move
                name: "dataAnimation_move"
                label: " --- " + qsTr("Data Move Animation")
                visible: dataAnimation.value
            }
            //距离
            P.SpinPreference {
                name: "moveData_Distance"
                label: " --- --- " + qsTr("Distance")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: dataAnimation.value&&dataAnimation_move.value&&!moveData_Distance_data.value
                defaultValue: 10
                from: -1000
                to: 1000
                stepSize: 10
            }
            P.SwitchPreference {
                id: moveData_Distance_data
                name: "moveData_Distance_data"
                label: " --- --- " + qsTr("Distance Use Data")
                visible: dataAnimation.value&&dataAnimation_move.value
            }
            P.DataPreference {
                name: "distanceData"
                label: " --- --- " + qsTr("Distance Data")
                visible: dataAnimation.value&&dataAnimation_move.value&&moveData_Distance_data.value
            }
            //方向
            P.SpinPreference {
                name: "moveData_Direction"
                label: " --- --- " + qsTr("Direction")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: dataAnimation.value&&dataAnimation_move.value&&!moveData_Direction_data.value
                defaultValue: 0
                from: -180
                to: 180
                stepSize: 5
            }
            P.SwitchPreference {
                id: moveData_Direction_data
                name: "moveData_Direction_data"
                label: " --- --- " + qsTr("Direction Use Data")
                visible: dataAnimation.value&&dataAnimation_move.value
            }
            P.DataPreference {
                name: "directionData"
                label: " --- --- " + qsTr("Direction Data")
                visible: dataAnimation.value&&dataAnimation_move.value&&moveData_Direction_data.value
            }
            //检测时间
            P.SpinPreference {
                name: "moveData_Trigger"
                label: " --- --- " + qsTr("Trigger Cycle")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: dataAnimation.value&&dataAnimation_move.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //持续时间
            P.SpinPreference {
                name: "moveData_Duration"
                label: " --- --- " + qsTr("Duration")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: dataAnimation.value&&dataAnimation_move.value
                defaultValue: 300
                from: 0
                to: 10000
                stepSize: 10
            }
            //曲线
            P.SelectPreference {
                name: "moveData_Easing"
                label: " --- --- " + qsTr("Easing")
                model: easingModel
                defaultValue: 3
                visible: dataAnimation.value&&dataAnimation_move.value
            }
        }
    }
}