import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import "../.."

P.ObjectPreferenceGroup {
    id: control
    
    property var itemIn: null
    property var defaultFillStops: [{ position: 0.0, color: "#a18cd1" },{ position: 0.5, color: "#fbc2eb" }]
    syncProperties: true
    width: parent.width

    Binding {
        target: control
        property: "defaultValue"
        value: itemIn
        when: itemIn !== null && itemIn !== undefined
    }
    Binding {
        target: control
        property: "enabled"
        value: itemIn !== null && itemIn !== undefined && itemIn !== false
    }

    data: PreferenceGroupIndicator { anchors.topMargin: enableOverallGradientEffect.height; visible: enableOverallGradientEffect.value }
    //必须资源
    P.SwitchPreference {
        id: enableOverallGradientEffect
        name: "enableOverallGradientEffect"
        label: qsTr("Enable Overall Gradient Effect")
        message: qsTr("Also see https://webgradients.com/")
        defaultValue: false
    }
    P.ObjectPreferenceGroup {
        syncProperties: true
        defaultValue: itemIn
        data: PreferenceGroupIndicator { anchors.topMargin: useFillGradient.height; visible: useFillGradient.value; color: "#662196f3"; anchors.leftMargin: 4 }
        P.SwitchPreference {
            id: useFillGradient
            name: "useFillGradient"
            label: qsTr("Use Advanced Color")
            defaultValue: false
            visible: enableOverallGradientEffect.value
        }
        GradientPreference {
            name: "fillStops"
            label: qsTr("Fill Gradient")
            defaultValue: defaultFillStops
            visible: enableOverallGradientEffect.value&&useFillGradient.value
        }
    }
    NoDefaultColorPreference {
        name: "overallGradientColor0"
        label: qsTr("Start Color")
        defaultValue: "#a18cd1"
        visible: enableOverallGradientEffect.value&&!useFillGradient.value
    }
    NoDefaultColorPreference {
        name: "overallGradientColor1"
        label: qsTr("End Color")
        defaultValue: "#fbc2eb"
        visible: enableOverallGradientEffect.value&&!useFillGradient.value
    }
    // 渐变方向
    P.ObjectPreferenceGroup {
        syncProperties: true
        defaultValue: itemIn
        data: PreferenceGroupIndicator { anchors.topMargin: overallGradientDirection.height; visible: overallGradientDirection.value; color: "#662196f3"; anchors.leftMargin: 4 }
        P.SelectPreference {
            id: overallGradientDirection
            name: "overallGradientDirect"
            label: qsTr("Gradient Direction")
            defaultValue: 1
            //从左到右,从下到上,从左上到右下
            //旋转 3
            //中心 4
            //高级选项5 用于改变线性的start,end值
            model: [ qsTr("Horizontal"), qsTr("Vertical"), qsTr("Oblique"), qsTr("Center"), qsTr("Conical"),qsTr("Advanced")]
            visible: enableOverallGradientEffect.value
        }
        //方向为3,4时提供的垂直水平角度选项,为4时提供水平/垂直半径
        //水平
        P.SpinPreference {
            name: "overallGradientHorizontal"
            label: qsTr("Horizontal")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: (overallGradientDirection.value==4||overallGradientDirection.value==3)&&enableOverallGradientEffect.value
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        //垂直
        P.SpinPreference {
            name: "overallGradientVertical"
            label: qsTr("Vertical")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: (overallGradientDirection.value==4||overallGradientDirection.value==3)&&enableOverallGradientEffect.value
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        //角度
        P.SpinPreference {
            name: "overallGradientAngle"
            label: qsTr("Angle")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: (overallGradientDirection.value==4||overallGradientDirection.value==3)&&enableOverallGradientEffect.value
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        //水平半径 3
        P.SpinPreference {
            name: "overallGradientHorizontalRadius"
            label: qsTr("Horizontal Radius")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: overallGradientDirection.value==3&&enableOverallGradientEffect.value
            defaultValue: 50
            from: -10000
            to: 10000
            stepSize: 5
        }
        //垂直半径 3
        P.SpinPreference {
            name: "overallGradientVerticalRadius"
            label: qsTr("Vertical Radius")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: overallGradientDirection.value==3&&enableOverallGradientEffect.value
            defaultValue: 50
            from: -10000
            to: 10000
            stepSize: 5
        }
        Row{
            spacing: 8
            visible: enableOverallGradientEffect.value&&overallGradientDirection.value == 5
            Column {
                Label {
                    text: qsTr("Start X & Y")
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                P.ObjectPreferenceGroup {
                    syncProperties: true
                    defaultValue: itemIn
                    //s.y x轴起始值
                    P.SpinPreference {
                        name: "overallGradientStartX"
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 5
                    }
                    //s.y y轴起始值
                    P.SpinPreference {
                        name: "overallGradientStartY"
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        defaultValue: 0
                        from: -10000
                        to: 10000
                        stepSize: 5
                    }
                }
            }
            Column {
                Label {
                    text: qsTr("End X & Y")
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                P.ObjectPreferenceGroup {
                    syncProperties: true
                    defaultValue: itemIn
                    //e.x x轴结束值
                    P.SpinPreference {
                        name: "overallGradientEndX"
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        defaultValue: 100
                        from: -10000
                        to: 10000
                        stepSize: 5
                    }
                    //e.y y轴结束值
                    P.SpinPreference {
                        name: "overallGradientEndY"
                        editable: true
                        display: P.TextFieldPreference.ExpandLabel
                        defaultValue: 100
                        from: -10000
                        to: 10000
                        stepSize: 5
                    }
                }
            }
        }
    }
    P.ObjectPreferenceGroup {
        syncProperties: true
        defaultValue: itemIn
        data: PreferenceGroupIndicator { anchors.topMargin: enableGradientAnim.height; visible: enableGradientAnim.value; color: "#662196f3"; anchors.leftMargin: 4 }
        P.SwitchPreference {
            id: enableGradientAnim
            name: "enableOverallGradientAnim"
            label: qsTr("Enable Gradient Animation") // 开启渐变动画
            visible: enableOverallGradientEffect.value
            defaultValue: false
        }
        P.SpinPreference {
            name: "overallGradientAnimDuration"
            label: qsTr("Duration (ms)") // 动画周期(毫秒)
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: enableOverallGradientEffect.value && enableGradientAnim.value
            defaultValue: 5000 // 默认5秒一圈
            from: 100
            to: 60000
            stepSize: 100
        }
    }
    //缓存
    P.SwitchPreference {
        name: "overallGradientCached"
        label: qsTr("Cached")
        visible: enableOverallGradientEffect.value
    }
}