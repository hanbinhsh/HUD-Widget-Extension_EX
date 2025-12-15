import QtQuick 2.12
import QtQuick.Shapes 1.12
import QtQuick.Controls 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    // --- 上下文定义 (参考自提供的代码) ---
    QtObject {
        id: ctx_widget
        readonly property font defaultFont: Qt.font({ family: "Source Han Sans SC", pixelSize: 14 })
        readonly property color defaultTextColor: "#FFFFFF"
        readonly property color defaultStyleColor: "#33000000" // 默认阴影/描边色
        readonly property bool exposed: widget ? widget.NVG.View.exposed : true
    }

    // --- 核心配置读取 ---
    readonly property int circleRadius: settings.radius ?? 50
    readonly property int circleStrokeSize: settings.strokeSize ?? 6
    
    // 颜色配置
    readonly property color workColor: settings.workColor ?? "#FF5555"
    readonly property color breakColor: settings.breakColor ?? "#55FF55"
    readonly property color trackColor: settings.trackColor ?? "#33FFFFFF"
    readonly property color fillColor: settings.fillColor ?? "#33000000" 

    readonly property var _userStatusColor: settings.statusColor ?? "transparent" 
    readonly property bool _hasUserStatusColor: _userStatusColor && _userStatusColor.toString() !== "#00000000" && _userStatusColor.toString() !== "transparent"
    
    // 文字通用配置
    readonly property var workText: settings.workText ?? "Work"
    readonly property var breakText: settings.breakText ?? "Break"
    readonly property bool showText: settings.showText ?? true
    readonly property bool showStatus: settings.showStatus ?? true
    readonly property bool showTime: settings.showTime ?? true
    
    // 行为配置
    readonly property bool autoSwitch: settings.autoSwitch ?? false
    readonly property bool showToolTip: settings.showToolTip ?? true

    // 通知设置
    readonly property bool soundPlay: settings.soundPlay ?? false
    readonly property bool messageShow: settings.messageShow ?? false
    readonly property var messageTitleWork: settings.messageTitleWork ?? "Work time is up!"
    readonly property var messageTitleBreak: settings.messageTitleBreak ?? "Break time is up!"
    readonly property var messageTextWork: settings.messageTextWork ?? "Take a break!"
    readonly property var messageTextBreak: settings.messageTextBreak ?? "Back to work!"

    // --- 计时器逻辑 ---
    property bool isRunning: false
    property bool isWorkSession: true 
    property int durationWork: (settings.timeWork ?? 25) * 60
    property int durationBreak: (settings.timeBreak ?? 5) * 60
    
    property int currentSeconds: isWorkSession ? durationWork : durationBreak
    property int totalSeconds: isWorkSession ? durationWork : durationBreak

    readonly property real progress: totalSeconds > 0 ? currentSeconds / totalSeconds : 0

    title: qsTranslate("utils", "Pomodoro Timer")
    implicitWidth: Math.max(circleRadius * 2, 64)
    implicitHeight: implicitWidth

    Connections {
        target: settings
        onTimeWorkChanged: if (!isRunning) resetTimer()
        onTimeBreakChanged: if (!isRunning) resetTimer()
    }

    Timer {
        id: timer
        interval: 1000 
        repeat: true
        running: isRunning && ctx_widget.exposed 
        onTriggered: {
            if (thiz.currentSeconds > 0) {
                thiz.currentSeconds -= 1
            } else {
                // 1. 时间到，先停止当前计时
                timer.stop()
                
                // 2. 切换工作/休息状态
                isWorkSession = !isWorkSession
                
                // 3. 重置时间为新状态的长度
                resetTimer()
                
                // 4. [修复 2] 自动切换逻辑
                if (thiz.autoSwitch) {
                    thiz.isRunning = true;
                    timer.start(); // 必须显式 restart/start
                } else {
                    thiz.isRunning = false;
                }
                
                // 播放提示音
                if(thiz.soundPlay){
                    NVG.SystemCall.playSound(NVG.SFX.NotifyMessage)
                }
                if(thiz.messageShow){
                    NVG.SystemCall.messageBox({
                        title: isWorkSession ? thiz.messageTitleWork : thiz.messageTitleBreak,
                        modal: true,
                        text: isWorkSession ? thiz.messageTextWork : thiz.messageTextBreak
                    });
                }
            }
        }
    }

    function resetTimer() {
        // if (!autoSwitch) isRunning = false
        totalSeconds = isWorkSession ? durationWork : durationBreak
        currentSeconds = totalSeconds
    }

    function formatTime(totalSec) {
        var m = Math.floor(totalSec / 60);
        var s = totalSec % 60;
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
    }

    // --- 设置面板 ---
    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        // 时间设置
        P.SpinPreference {
            name: "timeWork"
            label: qsTr("Work Time (min)")
            defaultValue: 25
            from: 1
            to: 120
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        P.SpinPreference {
            name: "timeBreak"
            label: qsTr("Break Time (min)")
            defaultValue: 5
            from: 1
            to: 60
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        P.SwitchPreference {
            name: "autoSwitch"
            label: qsTr("Auto Start Next Session")
            defaultValue: false
        }

        P.Separator {}

        // 通知设置
        P.SwitchPreference {
            name: "soundPlay"
            label: qsTr("Play Sound (Notify Message)")
            defaultValue: false
        }
        P.SwitchPreference {
            id: pMessageShow
            name: "messageShow"
            label: qsTr("Show Message")
            defaultValue: false
        }
        P.TextAreaPreference {
            name: "messageTitleWork"
            label: qsTr("Message Title (Work)")
            defaultValue: "Work time is up!"
            visible: pMessageShow.value
        }
        P.TextAreaPreference {
            name: "messageTitleBreak"
            label: qsTr("Message Title (Break)")
            defaultValue: "Break time is up!"
            visible: pMessageShow.value
        }
        P.TextAreaPreference {
            name: "messageTextWork"
            label: qsTr("Message Text (Work)")
            defaultValue: "Take a break!"
            visible: pMessageShow.value
        }
        P.TextAreaPreference {
            name: "messageTextBreak"
            label: qsTr("Message Text (Break)")
            defaultValue: "Back to work!"
            visible: pMessageShow.value
        }
        
        P.Separator {}

        // 外观设置
        P.SliderPreference {
            name: "radius"
            label: qsTr("Radius")
            displayValue: value + " px"
            defaultValue: 50
            from: 20
            to: 300
            stepSize: 1
            live: true
        }
        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Line Width")
            defaultValue: 6
            from: 1
            to: 50
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        P.SwitchPreference {
            name: "showToolTip"
            label: qsTr("Show ToolTip")
            defaultValue: true
        }

        P.Separator {}

        // 颜色设置
        NoDefaultColorPreference {
            name: "workColor"
            label: qsTr("Work Color")
            defaultValue: "#FF5555"
        }
        NoDefaultColorPreference {
            name: "breakColor"
            label: qsTr("Break Color")
            defaultValue: "#55FF55"
        }
        NoDefaultColorPreference {
            name: "trackColor"
            label: qsTr("Track Color")
            defaultValue: "#33FFFFFF"
        }
        NoDefaultColorPreference {
            name: "fillColor"
            label: qsTr("Background Fill")
            defaultValue: "#33000000"
        }

        P.Separator {}

        // --- 文字设置 (移植自参考代码) ---
        P.SwitchPreference {
            id: pShowText
            name: "showText"
            label: qsTr("Show Text")
            defaultValue: true
        }

        P.ObjectPreferenceGroup {
            visible: pShowText.value
            syncProperties: true
            defaultValue: thiz.settings
            
            P.SwitchPreference {
                id: pShowStatus
                name: "showStatus"
                label: qsTr("Show Status Text")
                defaultValue: true
            }
            // 文本设置
            P.TextAreaPreference {
                name: "workText"
                label: qsTr("Work Text")
                defaultValue: "Work"
                visible: pShowStatus.value
            }
            P.TextAreaPreference {
                name: "breakText"
                label: qsTr("Break Text")
                defaultValue: "Break"
                visible: pShowStatus.value
            }

            P.SwitchPreference {
                name: "showTime"
                label: qsTr("Show Timer Text")
                defaultValue: true
            }

            P.Separator {}

            // 字体与排版
            P.FontPreference {
                name: "font"
                label: qsTr("Font")
                defaultValue: ctx_widget.defaultFont
            }

            P.SelectPreference {
                id: pSizeMode
                name: "sizeMode"
                label: qsTr("Font Size Mode")
                defaultValue: 1 // 默认为 Horizontal Fit 以适应圆环
                model: [ qsTr("Fixed Size"), qsTr("Horizontal Fit"), qsTr("Vertical Fit"), qsTr("Fit") ]
            }

            P.SpinPreference {
                name: "minimumSize"
                label: qsTr("Minimum Font Size")
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 8
                from: 1
                to: 999
                stepSize: 1
                editable: true
                visible: pSizeMode.value // 只要不是 0 (Fixed) 就显示
            }

            // 样式与对齐
            P.SelectPreference {
                name: "style"
                label: qsTr("Style")
                defaultValue: 0
                model: [ qsTr("Normal"), qsTr("Outline"), qsTr("Raised"), qsTr("Sunken") ]
            }

            NoDefaultColorPreference {
                name: "styleColor"
                label: qsTr("Style Color")
                defaultValue: ctx_widget.defaultStyleColor
            }

            P.SelectPreference {
                name: "hAlign"
                label: qsTr("Horizontal Alignment")
                defaultValue: 2 // Center
                model: [ qsTr("Left"), qsTr("Right"), qsTr("Center") ]
            }
            
            // 文字特定颜色
            P.Separator {}
            NoDefaultColorPreference {
                name: "timeColor"
                label: qsTr("Time Color")
                defaultValue: "#FFFFFF"
            }
            NoDefaultColorPreference {
                name: "statusColor"
                label: qsTr("Status Color")
                defaultValue: "transparent" 
            }
        }
    }

    // --- 界面绘制 ---
    Item {
        anchors.centerIn: parent
        width: circleRadius * 2
        height: width

        // 1. 绘制圆环
        Shape {
            id: shape
            anchors.fill: parent
            z: 1 
            layer.enabled: true
            layer.smooth: true
            layer.samples: 4

            ShapePath {
                id: bgShapePath
                strokeWidth: circleStrokeSize
                strokeColor: trackColor
                fillColor: thiz.fillColor
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: circleRadius; centerY: circleRadius
                    radiusX: circleRadius - circleStrokeSize / 2; radiusY: radiusX
                    startAngle: 0; sweepAngle: 360
                }
            }

            ShapePath {
                strokeWidth: circleStrokeSize
                strokeColor: isWorkSession ? workColor : breakColor
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: circleRadius; centerY: circleRadius
                    radiusX: circleRadius - circleStrokeSize / 2; radiusY: radiusX
                    startAngle: -90
                    sweepAngle: 360 * progress
                    Behavior on sweepAngle {
                        enabled: ctx_widget.exposed && isRunning
                        NumberAnimation { duration: 1000 }
                    }
                }
            }
        }

        // 2. 中间显示文字 (高级排版)
        Column {
            anchors.centerIn: parent
            width: (circleRadius * 2) - (circleStrokeSize * 2) - 10 // 限制宽度在圆环内
            spacing: 0
            visible: showText
            z: 10 

            // 状态 (WORK/BREAK)
            Text {
                id: statusTextItem
                visible: showStatus
                text: isWorkSession ? workText : breakText
                
                // 颜色逻辑：如果设置了 statusColor 则用设置值，否则跟随工作/休息主题色
                color: thiz._hasUserStatusColor ? thiz._userStatusColor : (isWorkSession ? workColor : breakColor)
                
                width: parent.width // 配合 Fit 模式
                height: contentHeight // 让 Column 紧凑

                // --- 移植的属性设置 ---
                font: thiz.settings.font ? Qt.font(thiz.settings.font) : ctx_widget.defaultFont
                
                style: thiz.settings.style ?? Text.Normal
                styleColor: thiz.settings.styleColor ?? ctx_widget.defaultStyleColor
                
                fontSizeMode: thiz.settings.sizeMode ?? Text.HorizontalFit
                minimumPixelSize: thiz.settings.minimumSize ?? 8
                
                horizontalAlignment: {
                    switch (thiz.settings.hAlign) {
                        case 0: return Text.AlignLeft;
                        case 1: return Text.AlignRight;
                        case 2: default: return Text.AlignHCenter;
                    }
                }
            }

            // 时间 (MM:SS)
            Text {
                id: timeTextItem
                visible: showTime
                text: formatTime(currentSeconds)
                color: settings.timeColor ?? "#FFFFFF"
                
                width: parent.width
                height: contentHeight

                font: thiz.settings.font ? Qt.font(thiz.settings.font) : ctx_widget.defaultFont

                style: thiz.settings.style ?? Text.Normal
                styleColor: thiz.settings.styleColor ?? ctx_widget.defaultStyleColor
                
                fontSizeMode: thiz.settings.sizeMode ?? Text.HorizontalFit
                minimumPixelSize: thiz.settings.minimumSize ?? 8
                
                horizontalAlignment: statusTextItem.horizontalAlignment
            }
        }

        // 3. 鼠标交互
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            onClicked: {
                if (mouse.button === Qt.RightButton) {
                    // 右键跳过
                    timer.stop() // 先停
                    thiz.isWorkSession = !thiz.isWorkSession
                    thiz.resetTimer()
                    
                    // 跳过也遵循自动切换逻辑吗？通常跳过意味着用户想立即开始下一段
                    // 或者你可以强制暂停，看你喜好。这里改为强制暂停，让用户准备好再点开始
                    thiz.isRunning = false 
                } else {
                    // 左键暂停/开始
                    if (thiz.isRunning) {
                        thiz.isRunning = false;
                        timer.stop();
                    } else {
                        thiz.isRunning = true;
                        timer.start();
                    }
                }
            }

            onDoubleClicked: {
                thiz.resetTimer()
                thiz.isRunning = false
            }
            
            ToolTip.visible: showToolTip && containsMouse
            ToolTip.text: (isRunning ? qsTr("Pause") : qsTr("Start")) + "\n" +
                          qsTr("Double-Click: Reset") + "\n" +
                          qsTr("R-Click: Skip")
            ToolTip.delay: 500
        }
    }
}