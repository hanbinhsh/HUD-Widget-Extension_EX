import QtQuick 2.12
//动画必备
import QtGraphicalEffects 1.12 

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id:  thiz

    readonly property bool dataEnabled: settings.mode ?? false
//颜色
    readonly property color normalColor: settings.color ?? ctx_widget.defaultTextColor
    readonly property color hoveredColor: settings.hoveredColor ?? "transparent"
    readonly property color pressedColor: settings.pressedColor ?? "transparent"
//样式颜色
    readonly property color styleNormalColor: settings.styleColor ?? ctx_widget.defaultTextColor
    readonly property color styleHoveredColor: settings.styleHoveredColor ?? "transparent"
    readonly property color stylePressedColor: settings.stylePressedColor ?? "transparent"
//颜色渐变动画
    readonly property bool enableColorGradient: settings.enableColorAnimation ?? false
    readonly property real changingCycleTime: settings.cycleTime ?? 800
    property int idxx: 1

    readonly property string displayUnit: dataSource.suffix ?? output.unit

    readonly property var displayText: {
        if (settings.output === 2) { // unit only
            return (value, unit) => unit;
        } else if (settings.output === 1 || !displayUnit) { // value only
            return (value, unit) => value;
        } // value and unit
        return (value, unit) => value + ' ' + unit;
    }

    title: qsTranslate("utils", "Advanced Text")
    implicitHeight: textSource.implicitHeight
    Binding on implicitWidth {
        delayed: true // avoid binding loop
        value: textSource.implicitWidth
    }
    dataConfiguration: dataEnabled ? settings.data : undefined

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true
//启用数据
        P.SwitchPreference {
            id: pMode
            name: "mode"
            label: qsTr("Enable Data Source")
        }
//文字输入
        P.TextAreaPreference {
            name: "text"
            label: qsTr("Text")
            visible: !pMode.value
        }
//数据输入
        P.DataPreference {
            name: "data"
            label: qsTr("Data")
            visible: pMode.value
        }
//显示设置
        P.SelectPreference {
            name: "output"
            label: qsTr("Output")
            visible: pMode.value
            defaultValue: 0
            model: [ qsTr("Value and Unit"), qsTr("Value Only"), qsTr("Unit Only") ]
        }
//取整
        P.SelectPreference {
            id: pRounding
            name: "rounding"
            label: qsTr("Rounding Numbers")
            visible: pMode.value
            defaultValue: 0
            model: [ qsTr("Auto"), qsTr("Fixed") ]
        }
//
        P.SpinPreference {
            name: "decimal"
            label: qsTr("Decimal Digits")
            display: P.TextFieldPreference.ExpandLabel
            visible: pMode.value && pRounding.value === 1
            defaultValue: 0
            from: 0
            to: 10
            stepSize: 1
        }

        P.SelectPreference {
            name: "format"
            label: qsTr("Text Format")
            defaultValue: 0
            model: [ qsTr("Auto"), qsTr("Plain Text"), qsTr("Rich Text"), qsTr("HTML Text") ]
        }

//字体
        P.FontPreference {
            name: "font"
            label: qsTr("Font")
            defaultValue: ctx_widget.defaultFont
        }
//填充
        P.SelectPreference {
            id: pSizeMode
            name: "sizeMode"
            label: qsTr("Font Size Mode")
            defaultValue: 0
            model: [ qsTr("Fixed Size"), qsTr("Horizontal Fit"), qsTr("Vertical Fit"), qsTr("Fit") ]
        }

        P.SpinPreference {
            name: "minimumSize"
            label: qsTr("Minimum Font Size")
            display: P.TextFieldPreference.ExpandLabel
            defaultValue: 14
            from: 1
            to: 999
            stepSize: 1
            editable: true
            visible: pSizeMode.value
        }
//颜色渐变动画
        P.SwitchPreference {
            id: enableColorAnimation
            name: "enableColorAnimation"
            label: qsTr("Color Animation(Must Reload)")
        }
    //渐变方向
        P.SelectPreference {
            id:animationDirect
            name: "animationDirect"
            label: qsTr("Animation Direct")
            defaultValue: 0
            //从左到右,从下到上,从左上到右下,全部
            //旋转 4
            //中心 5
            //高级选项6 用于改变线性的start,end值
            model: [ qsTr("Horizontal"), qsTr("Vertical"), qsTr("Oblique"), qsTr("All"), qsTr("Center"), qsTr("Conical")/*,qsTr("Advanced")*/]
            visible: enableColorAnimation.value
        }
    // //高级选项 6
    //     //s.x
    //     P.SpinPreference {
    //         id: animationAdvancedStartX
    //         name: "animationAdvancedStartX"
    //         label: qsTr("StartX")
    //         editable: true
    //         display: P.TextFieldPreference.ExpandLabel
    //         visible: settings.animationDirect==6
    //         defaultValue: 0
    //         from: -10000
    //         to: 10000
    //         stepSize: 5
    //     }
    //     //s.y
    //     P.SpinPreference {
    //         id: animationAdvancedStartY
    //         name: "animationAdvancedStartY"
    //         label: qsTr("StartY")
    //         editable: true
    //         display: P.TextFieldPreference.ExpandLabel
    //         visible: settings.animationDirect==6
    //         defaultValue: 0
    //         from: -10000
    //         to: 10000
    //         stepSize: 5
    //     }
    //     //e.x
    //     P.SpinPreference {
    //         id: animationAdvancedEndX
    //         name: "animationAdvancedEndX"
    //         label: qsTr("EndX")
    //         editable: true
    //         display: P.TextFieldPreference.ExpandLabel
    //         visible: settings.animationDirect==6
    //         defaultValue: 100
    //         from: -10000
    //         to: 10000
    //         stepSize: 5
    //     }
    //     //e.y
    //     P.SpinPreference {
    //         id: animationAdvancedEndY
    //         name: "animationAdvancedEndY"
    //         label: qsTr("EndY")
    //         editable: true
    //         display: P.TextFieldPreference.ExpandLabel
    //         visible: settings.animationDirect==6
    //         defaultValue: 100
    //         from: -10000
    //         to: 10000
    //         stepSize: 5
    //     }
    //方向为4,5时提供的垂直水平角度选项
        //水平
        P.SpinPreference {
            id: animationHorizontal
            name: "animationHorizontal"
            label: qsTr("Horizontal")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: settings.animationDirect==4||settings.animationDirect==5
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        //垂直
        P.SpinPreference {
            id: animationVertical
            name: "animationVertical"
            label: qsTr("Vertical")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: settings.animationDirect==4||settings.animationDirect==5
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        //角度
        P.SpinPreference {
            id: animationAngle
            name: "animationAngle"
            label: qsTr("Angle")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: settings.animationDirect==4||settings.animationDirect==5
            defaultValue: 0
            from: -10000
            to: 10000
            stepSize: 5
        }
        //水平半径
        P.SpinPreference {
            id: animationHorizontalRadius
            name: "animationHorizontalRadius"
            label: qsTr("Horizontal Radius")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: settings.animationDirect==4
            defaultValue: 50
            from: -10000
            to: 10000
            stepSize: 5
        }
        //垂直半径
        P.SpinPreference {
            id: animationVerticalRadius
            name: "animationVerticalRadius"
            label: qsTr("Vertical Radius")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: settings.animationDirect==4
            defaultValue: 50
            from: -10000
            to: 10000
            stepSize: 5
        }
    //渐变颜色
        P.SelectPreference {
            id:cycleColor
            name: "cycleColor"
            label: qsTr("Cycle Color")
            defaultValue: 0
            //所有,黑白
            model: [ qsTr("All") /*,qsTr("B/W")*/]
            visible: enableColorAnimation.value
        }
    //渐变时间
        P.SpinPreference {
            id: cycleTime
            name: "cycleTime"
            label: qsTr("Cycle Time")
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: enableColorAnimation.value
            defaultValue: 500
            from: 0
            to: 3000
            stepSize: 100
        }
    //渐变次数?

//颜色
        NoDefaultColorPreference {
            name: "color"
            label: qsTr("Color")
            defaultValue: ctx_widget.defaultTextColor
            visible: !enableColorAnimation.value
        }
    //悬停
        NoDefaultColorPreference {
            name: "hoveredColor"
            label: qsTr("Hovered Color")
            defaultValue: "transparent"
            visible: !enableColorAnimation.value
        }
    //按下
        NoDefaultColorPreference {
            name: "pressedColor"
            label: qsTr("Pressed Color")
            defaultValue: "transparent"
            visible: !enableColorAnimation.value
        }
//风格
        P.SelectPreference {
            id:style
            name: "style"
            label: qsTr("Style")
            defaultValue: 0
            model: [ qsTr("Normal"), qsTr("Outline"), qsTr("Raised"), qsTr("Sunken") ]
            visible: !enableColorAnimation.value
        }
//风格颜色
        NoDefaultColorPreference {
            name: "styleColor"
            label: qsTr("Style Color")
            defaultValue: ctx_widget.defaultStyleColor
            visible:style.value&&!enableColorAnimation.value
        }
    //悬停
        NoDefaultColorPreference {
            name: "styleHoveredColor"
            label: qsTr("Style Hovered Color")
            defaultValue: "transparent"
            visible:style.value&&!enableColorAnimation.value
        }
    //按下
        NoDefaultColorPreference {
            name: "stylePressedColor"
            label: qsTr("Style Pressed Color")
            defaultValue: "transparent"
            visible:style.value&&!enableColorAnimation.value
        }
//对齐方式
        P.SelectPreference {
            name: "hAlign"
            label: qsTr("Horizontal Alignment")
            defaultValue: 0
            model: [ qsTr("Left"), qsTr("Right"), qsTr("Center") ]
        }

        P.SelectPreference {
            name: "vAlign"
            label: qsTr("Vertical Alignment")
            defaultValue: 0
            model: [ qsTr("Top"), qsTr("Bottom"), qsTr("Center") ]
        }
//行间距
        P.SpinPreference {
            name: "lineHeight"
            label: qsTr("Line Height")
            display: P.TextFieldPreference.ExpandLabel
            defaultValue: 100
            from: 50
            to: 250
            stepSize: 10
        }
    }

    Text {
        id: textSource
        anchors.fill: parent

        font: thiz.settings.font ? Qt.font(thiz.settings.font) : ctx_widget.defaultFont
        style: thiz.settings.style ?? Text.Normal
        //styleColor: thiz.settings.styleColor ?? ctx_widget.defaultStyleColor
        lineHeight: (thiz.settings.lineHeight ?? 100) / 100
        fontSizeMode: thiz.settings.sizeMode ?? Text.FixedSize
        minimumPixelSize: thiz.settings.minimumSize ?? 14
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        // BUG: text area tracks MouseArea
        enabled: false
//颜色
        color: {
            if (thiz.itemPressed && pressedColor.a)
                return pressedColor;

            if (thiz.itemHovered && hoveredColor.a)
                return hoveredColor;

            return normalColor;
        }
//样式颜色
        styleColor: {
            if (thiz.itemPressed && stylePressedColor.a)
                return stylePressedColor;
            if (thiz.itemHovered && styleHoveredColor.a)
                return styleHoveredColor;
            return styleNormalColor;
        }

        horizontalAlignment: {
            switch (thiz.settings.hAlign) {
                case 2: return Text.AlignHCenter;
                case 1: return Text.AlignRight;
                case 0:
                default: break;
            }
            return Text.AlignLeft;
        }

        verticalAlignment: {
            switch (thiz.settings.vAlign) {
                case 2: return Text.AlignVCenter;
                case 1: return Text.AlignBottom;
                case 0:
                default: break;
            }
            return Text.AlignTop;
        }
//文本
        text: {
            if (thiz.settings.mode)
                return displayText(output.result, displayUnit);

            return thiz.settings.text || thiz.elementLabel || thiz.itemLabel;
        }
    }

    //颜色动画选项0~3 , 6
    LinearGradient {
        anchors.fill: textSource
        source: (enableColorGradient&&(settings.animationDirect>=0&&settings.animationDirect<=3)) ? textSource : null
        visible: (enableColorGradient&&(settings.animationDirect>=0&&settings.animationDirect<=3))
        start: {
            switch (settings.animationDirect) {
                case 0 : 
                case 1 : 
                case 2 : 
                case 3 : return Qt.point(0, 0); 
                //case 6 : return Qt.point(settings.animationAdvancedStartX, settings.animationAdvancedStartY); break;
            }
            return Qt.point(0, 0)
        }
        end: {
            switch (settings.animationDirect) {
                case 0 : return Qt.point(textSource.width, 0); break;//1.横向渐变
                case 1 : return Qt.point(0, textSource.height); break;//2.竖向渐变
                case 2 : return Qt.point(textSource.width, textSource.height); break;//3.斜向渐变
                case 3 : return Qt.point(0, 0); break;// All
                //case 6 : return Qt.point(settings.animationAdvancedEndX, settings.animationAdvancedEndY); break;
            }
            return Qt.point(textSource.width, 0)
        }
        gradient: {
            switch (settings.cycleColor) {
                case 0: return gradientAll;
                //case 1: return gradientBW;
                default: return gradientAll;
            }
            return null;//switch必须在这里返回初始值
        }
    }
    //颜色动画选项4
    RadialGradient {
        anchors.fill: textSource
        //可调节的角度,x,y值
        angle: settings.animationAngle ?? 0
        horizontalOffset: settings.animationHorizontal ?? 0
        verticalOffset: settings.animationVertical ?? 0
        horizontalRadius:settings.animationHorizontalRadius ?? 50
        verticalRadius:settings.animationVerticalRadius ?? 50
        source: (enableColorGradient&&(settings.animationDirect>=4&&settings.animationDirect<=4)) ? textSource : null
        visible: (enableColorGradient&&(settings.animationDirect>=4&&settings.animationDirect<=4))
        gradient: {
            switch (settings.cycleColor) {
                case 0: return gradientAll;
                //case 1: return gradientBW;
                default: return gradientAll;
            }
            return null;//switch必须在这里返回初始值
        }
    }
    //颜色动画选项5
    ConicalGradient {
        anchors.fill: textSource
        //可调节的角度,x,y值
        angle: settings.animationAngle ?? 0
        horizontalOffset: settings.animationHorizontal ?? 0
        verticalOffset: settings.animationVertical ?? 0
        source: (enableColorGradient&&(settings.animationDirect>=5&&settings.animationDirect<=5)) ? textSource : null
        visible: (enableColorGradient&&(settings.animationDirect>=5&&settings.animationDirect<=5))
        gradient: {
            switch (settings.cycleColor) {
                case 0: return gradientAll;
                //case 1: return gradientBW;
                default: return gradientAll;
            }
            return null;//switch必须在这里返回初始值
        }
    }
    //动画颜色All
    Gradient {
        id: gradientAll
       GradientStop { position: 0.0; color: Qt.hsva((15 - (((idxx + 10) > 15) ? idxx - 15 + 10:idxx + 10)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.1; color: Qt.hsva((15 - (((idxx + 9) > 15) ? idxx - 15 + 9:idxx + 9)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.2; color: Qt.hsva((15 - (((idxx + 8) > 15) ? idxx - 15 + 8:idxx + 8)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.3; color: Qt.hsva((15 - (((idxx + 7) > 15) ? idxx - 15 + 7:idxx + 7)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.4; color: Qt.hsva((15 - (((idxx + 6) > 15) ? idxx - 15 + 6:idxx + 6)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.5; color: Qt.hsva((15 - (((idxx + 5) > 15) ? idxx - 15 + 5:idxx + 5)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.6; color: Qt.hsva((15 - (((idxx + 4) > 15) ? idxx - 15 + 4:idxx + 4)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.7; color: Qt.hsva((15 - (((idxx + 3) > 15) ? idxx - 15 + 3:idxx + 3)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.8; color: Qt.hsva((15 - (((idxx + 2) > 15) ? idxx - 15 + 2:idxx + 2)) * 16/255, 1, 1,1) }
       GradientStop { position: 0.9; color: Qt.hsva((15 - (((idxx + 1) > 15) ? idxx - 15 + 1:idxx + 1)) * 16/255, 1, 1,1) }
       GradientStop { position: 1.0; color: Qt.hsva((15 - (((idxx) > 15) ? idxx - 15:idxx)) * 16/255, 1, 1,1) }
    }
        // //动画颜色BW
        // Gradient {
        //     id: gradientBW
        //     GradientStop {position: ((idxx+0.3)>1 ? idxx-1+0.3 : idxx+0.3); color: "#F0F0F0"}
        //     GradientStop {position: ((idxx+0.6)>1 ? idxx-1+0.6 : idxx+0.6); color: "#000000"}
        //     GradientStop {position: ((idxx+0.9)>1 ? idxx-1+0.9 : idxx+0.9); color: "#F0F0F0"}
        // }
    SequentialAnimation {
        running: enableColorGradient && widget.NVG.View.exposed  // 默认启动
        loops:Animation.Infinite  // 无限循环
        NumberAnimation {
            target: thiz  // 目标对象
            property: { // 目标对象中的属性
                switch(settings.cycleColor) {
                    case 0: return "idxx";
                    //case 1: return "idxx1";
                    default: return "idxx";
                }
            }
            duration: changingCycleTime // 变化时间
            to: { // 目标值
                switch(settings.cycleColor) {
                    case 0: return 15;
                    //case 1: return 0.1;
                    default: return 15;
                }
            }
        }
    }

    NVG.DataSourceTextOutput {
        id: output
        source: dataEnabled ? thiz.dataSource : null
        undefinedText: ""
        nullText: ""
        fixedDecimalDigits: thiz.settings.rounding ? (thiz.settings.decimal ?? 0) : -1
    }
}
