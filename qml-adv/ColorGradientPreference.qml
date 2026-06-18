import QtQuick 2.12
import QtQuick.Controls 2.12
import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

// 可复用的"颜色循环渐变(cycleColor)"偏好分组。从 ImageElementAdvanced 的 Color 标签页抽出，
// 参数化 settingsTarget + groupEnabled，键名与 ColorCycleGradient / ImageEffectStack 一致。
// 自带 colorInit（仅用于 cycleColor 模式2 各色块默认值，idxx 取初始值 1）。
P.ObjectPreferenceGroup {
    id: root

    property NVG.SettingsMap settingsTarget
    property var groupEnabled: true
    property var defaultFillStops: [{ position: 0.0, color: "#a18cd1" },{ position: 0.5, color: "#fbc2eb" }]

    // 计算各色块默认值用（与元素侧 colorInit 一致，idxx 固定为初始 1）
    readonly property real cycleStart: (settingsTarget && settingsTarget.cycleColor == 1) ? (settingsTarget.cycleColorCustomStart ?? 0) / 16 : 0
    readonly property real cycleEnd: (settingsTarget && settingsTarget.cycleColor == 1) ? (settingsTarget.cycleColorCustomEnd ?? 160) / 10 : 16
    readonly property real cycleSaturation: (settingsTarget ? (settingsTarget.cycleSaturation ?? 100) : 100) / 100
    readonly property real cycleValue: (settingsTarget ? (settingsTarget.cycleValue ?? 100) : 100) / 100
    readonly property real cycleOpacity: (settingsTarget ? (settingsTarget.cycleOpacity ?? 100) : 100) / 100
    function colorInit(index) {
        var hueIndex = (15 - (((1 + index) > 15) ? 1 - 15 + index : 1 + index));
        var hue = (hueIndex * cycleEnd / 255) + (cycleStart / 255);
        return Qt.hsva(hue, cycleSaturation, cycleValue, cycleOpacity);
    }

    syncProperties: true
    width: parent.width
    defaultValue: settingsTarget
    enabled: groupEnabled

    data: PreferenceGroupIndicator { anchors.topMargin: colorGradient.height; visible: colorGradient.value }

    //开启颜色渐变
    P.SwitchPreference {
        id: colorGradient
        name: "colorGradient"
        label: qsTr("Color Gradient")
    }
    //渐变方向
    P.ObjectPreferenceGroup {
        defaultValue: root.settingsTarget
        syncProperties: true
        enabled: root.groupEnabled
        width: parent.width
        data: PreferenceGroupIndicator { anchors.topMargin: animationDirect.height; visible: animationDirect.value; color: "#662196f3"; anchors.leftMargin: 4 }
        P.SelectPreference {
            id: animationDirect
            name: "animationDirect"
            label: qsTr("Animation Direct")
            //从左到右,从下到上,从左上到右下,全部 / 旋转4 / 中心5 / 高级6
            model: [ qsTr("Horizontal"), qsTr("Vertical"), qsTr("Oblique"), qsTr("All"), qsTr("Center"), qsTr("Conical"), qsTr("Advanced")]
            visible: colorGradient.value
        }
        //高级设置 6
        P.SpinPreference {
            name: "animationAdvancedStartX"
            label: " --- --- " + qsTr("Start X")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: root.settingsTarget?.animationDirect == 6 && colorGradient.value
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        P.SpinPreference {
            name: "animationAdvancedStartY"
            label: " --- --- " + qsTr("Start Y")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: root.settingsTarget?.animationDirect == 6 && colorGradient.value
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        P.SpinPreference {
            name: "animationAdvancedEndX"
            label: " --- --- " + qsTr("End X")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: root.settingsTarget?.animationDirect == 6 && colorGradient.value
            defaultValue: 100
            from: -10000
            to: 10000
            stepSize: 5
        }
        P.SpinPreference {
            name: "animationAdvancedEndY"
            label: " --- --- " + qsTr("End Y")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: root.settingsTarget?.animationDirect == 6 && colorGradient.value
            defaultValue: 100
            from: -10000
            to: 10000
            stepSize: 5
        }
        //方向 4/5 的水平/垂直/角度，4 的水平/垂直半径
        P.SpinPreference {
            name: "animationHorizontal"
            label: qsTr("Horizontal")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: (root.settingsTarget?.animationDirect == 4 || root.settingsTarget?.animationDirect == 5) && colorGradient.value
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        P.SpinPreference {
            name: "animationVertical"
            label: qsTr("Vertical")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: (root.settingsTarget?.animationDirect == 4 || root.settingsTarget?.animationDirect == 5) && colorGradient.value
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        P.SpinPreference {
            name: "animationAngle"
            label: qsTr("Angle")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: (root.settingsTarget?.animationDirect == 4 || root.settingsTarget?.animationDirect == 5) && colorGradient.value
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        P.SpinPreference {
            name: "animationHorizontalRadius"
            label: qsTr("Horizontal Radius")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: root.settingsTarget?.animationDirect == 4 && colorGradient.value
            defaultValue: 50
            from: -10000
            to: 10000
            stepSize: 5
        }
        P.SpinPreference {
            name: "animationVerticalRadius"
            label: qsTr("Vertical Radius")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: root.settingsTarget?.animationDirect == 4 && colorGradient.value
            defaultValue: 50
            from: -10000
            to: 10000
            stepSize: 5
        }
    }
    //渐变颜色
    P.ObjectPreferenceGroup {
        defaultValue: root.settingsTarget
        syncProperties: true
        enabled: root.groupEnabled
        width: parent.width
        data: PreferenceGroupIndicator { anchors.topMargin: cycleColor.height; visible: cycleColor.value; color: "#662196f3"; anchors.leftMargin: 4 }
        P.SelectPreference {
            id: cycleColor
            name: "cycleColor"
            label: qsTr("Cycle Color")
            defaultValue: 0
            model: [ qsTr("Rainbow"), qsTr("Custom")+"Ⅰ", qsTr("Custom")+"Ⅱ", qsTr("Custom")+"Ⅲ"]
            visible: colorGradient.value
        }
        //自定义颜色 1
        P.SpinPreference {
            name: "cycleColorCustomStart"
            label: qsTr("Color Start")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: colorGradient.value && root.settingsTarget?.cycleColor == 1
            defaultValue: 0
            from: -5000
            to: 5000
            stepSize: 16
        }
        P.SpinPreference {
            name: "cycleColorCustomEnd"
            label: qsTr("Color End")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: colorGradient.value && root.settingsTarget?.cycleColor == 1
            defaultValue: 160
            from: -5000
            to: 5000
            stepSize: 16
        }
        //自定义颜色 2（16 色，三列）
        Row {
            spacing: 4
            visible: colorGradient.value && root.settingsTarget?.cycleColor == 2
            Column {
                Label { text: qsTr("00~05"); anchors.right: parent.right; anchors.rightMargin: 12 }
                P.ObjectPreferenceGroup {
                    syncProperties: true
                    enabled: root.groupEnabled
                    defaultValue: root.settingsTarget
                    NoDefaultColorPreference { name: "cycleColor0"; defaultValue: root.colorInit(0); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor1"; defaultValue: root.colorInit(1); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor2"; defaultValue: root.colorInit(2); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor3"; defaultValue: root.colorInit(3); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor4"; defaultValue: root.colorInit(4); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor5"; defaultValue: root.colorInit(5); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                }
            }
            Column {
                Label { text: qsTr("06~10"); anchors.right: parent.right; anchors.rightMargin: 12 }
                P.ObjectPreferenceGroup {
                    syncProperties: true
                    enabled: root.groupEnabled
                    defaultValue: root.settingsTarget
                    NoDefaultColorPreference { name: "cycleColor6"; defaultValue: root.colorInit(6); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor7"; defaultValue: root.colorInit(7); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor8"; defaultValue: root.colorInit(8); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor9"; defaultValue: root.colorInit(9); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor10"; defaultValue: root.colorInit(10); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                }
            }
            Column {
                Label { text: qsTr("11~15"); anchors.right: parent.right; anchors.rightMargin: 12 }
                P.ObjectPreferenceGroup {
                    syncProperties: true
                    enabled: root.groupEnabled
                    defaultValue: root.settingsTarget
                    NoDefaultColorPreference { name: "cycleColor11"; defaultValue: root.colorInit(11); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor12"; defaultValue: root.colorInit(12); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor13"; defaultValue: root.colorInit(13); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor14"; defaultValue: root.colorInit(14); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                    NoDefaultColorPreference { name: "cycleColor15"; defaultValue: root.colorInit(15); visible: colorGradient.value && root.settingsTarget?.cycleColor == 2 }
                }
            }
        }
        //自定义颜色 3（fillStops）
        GradientPreference {
            name: "fillStops"
            label: qsTr("Fill Gradient")
            defaultValue: root.defaultFillStops
            visible: colorGradient.value && root.settingsTarget?.cycleColor == 3
        }
    }
    //饱和度/亮度/透明度（模式 0/1）
    P.SpinPreference {
        name: "cycleSaturation"
        label: qsTr("Saturation")
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: colorGradient.value && root.settingsTarget?.cycleColor != 2 && root.settingsTarget?.cycleColor != 3
        defaultValue: 100
        from: 0
        to: 100
        stepSize: 1
    }
    P.SpinPreference {
        name: "cycleValue"
        label: qsTr("Value")
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: colorGradient.value && root.settingsTarget?.cycleColor != 2 && root.settingsTarget?.cycleColor != 3
        defaultValue: 100
        from: 0
        to: 100
        stepSize: 1
    }
    P.SpinPreference {
        name: "cycleOpacity"
        label: qsTr("Opacity")
        editable: true
        display: P.TextFieldPreference.ExpandLabel
        visible: colorGradient.value && root.settingsTarget?.cycleColor != 2 && root.settingsTarget?.cycleColor != 3
        defaultValue: 100
        from: 0
        to: 100
        stepSize: 1
    }
    //渐变动画
    P.ObjectPreferenceGroup {
        defaultValue: root.settingsTarget
        syncProperties: true
        enabled: root.groupEnabled
        width: parent.width
        data: PreferenceGroupIndicator { anchors.topMargin: enableColorAnimation.height; visible: enableColorAnimation.value; color: "#662196f3"; anchors.leftMargin: 4 }
        P.SwitchPreference {
            id: enableColorAnimation
            name: "enableColorAnimation"
            label: qsTr("Color Animation")
            visible: colorGradient.value
        }
        P.SpinPreference {
            name: "cycleTime"
            label: qsTr("Cycle Time")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: enableColorAnimation.value && colorGradient.value
            defaultValue: 500
            from: 0
            to: 50000
            stepSize: 100
        }
        P.SpinPreference {
            name: "pauseColorAnimationTime"
            label: qsTr("Pause Time")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: enableColorAnimation.value && colorGradient.value
            defaultValue: 0
            from: 0
            to: 10000
            stepSize: 100
        }
        P.SpinPreference {
            name: "cycleColorFrom"
            label: qsTr("Color From")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: enableColorAnimation.value && colorGradient.value && root.settingsTarget?.cycleColor != 3
            defaultValue: 0
            from: 0
            to: 10000
            stepSize: 1
        }
        P.SpinPreference {
            name: "cycleColorTo"
            label: qsTr("Color To")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: enableColorAnimation.value && colorGradient.value && root.settingsTarget?.cycleColor != 3
            defaultValue: 15
            from: 0
            to: 10000
            stepSize: 1
        }
    }
    //是否缓存
    P.SwitchPreference {
        name: "enableColorAnimationCached"
        label: qsTr("Cached")
        visible: colorGradient.value
    }
}
