import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".." 

HUDElementTemplate {
    id: root

    title: qsTr("Stepper")
    
    // 尺寸自适应
    implicitWidth: knobSize + 20
    implicitHeight: knobSize + 20

    // ============================================================
    //  配置属性 (Settings)
    // ============================================================

    // --- 基础 ---
    readonly property real knobSize: settings.knobSize ?? 80
    readonly property real sensitivity: settings.sensitivity ?? 30 
    
    // --- 颜色外观 ---
    readonly property color bgColor: settings.bgColor ?? "#40000000"
    readonly property color borderColor: settings.borderColor ?? "#00AAFF"
    readonly property real borderWidth: settings.borderWidth ?? 2
    
    // --- 刻度 (Ticks) ---
    readonly property bool showTicks: settings.showTicks ?? true
    readonly property color tickColor: settings.tickColor ?? "#88FFFFFF"
    readonly property real tickLength: settings.tickLength ?? 6
    readonly property real tickWidth: settings.tickWidth ?? 2

    // --- [新增] 指示器 (Indicator) ---
    readonly property bool showIndicator: settings.showIndicator ?? true
    readonly property int indicatorType: settings.indicatorType ?? 0 // 0=Circle, 1=Bar
    readonly property color indicatorColor: settings.indicatorColor ?? "#FFFFFF"
    readonly property real indicatorWidth: settings.indicatorWidth ?? 8
    readonly property real indicatorHeight: settings.indicatorHeight ?? 8
    readonly property real indicatorOffset: settings.indicatorOffset ?? (knobSize/2 - 12) // 距离圆心的距离

    // --- [新增] 内圈 (Inner Circle) ---
    readonly property bool showInnerCircle: settings.showInnerCircle ?? false
    readonly property real innerRadius: settings.innerRadius ?? 20
    readonly property real innerHole: ((settings.innerHole * 1.0) / 100 )?? 0 // 0.0 ~ 1.0 (0=实心, 1=全空)
    readonly property color innerColor: settings.innerColor ?? "#40FFFFFF"

    // --- [新增] 行为 ---
    readonly property bool autoSnap: settings.autoSnap ?? true // 自动吸附

    // ============================================================
    //  逻辑处理
    // ============================================================

    NVG.ActionSource { id: actionLeft; configuration: settings.actionLeft }
    NVG.ActionSource { id: actionRight; configuration: settings.actionRight }

    function triggerStep(isRight) {
        NVG.SystemCall.playSound(NVG.SFX.FeedbackClick);
        if (isRight) {
            if (settings.actionRight) actionRight.trigger(root);
        } else {
            if (settings.actionLeft) actionLeft.trigger(root);
        }
    }

    // ============================================================
    //  设置面板
    // ============================================================
    preference: P.ObjectPreferenceGroup {
        defaultValue: root.settings
        syncProperties: true

        P.SpinPreference {
            name: "knobSize"
            label: qsTr("Size (px)")
            defaultValue: 80
            from: 20
            to: 500
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        P.SpinPreference {
            name: "sensitivity"
            label: qsTr("Step Angle (°)")
            defaultValue: 30
            from: 5
            to: 180
            stepSize: 5
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }
        // [新增] 自动吸附开关
        P.SwitchPreference {
            name: "autoSnap"
            label: qsTr("Auto Snap to Tick") // 自动吸附/复位到刻度
            defaultValue: true
        }

        P.Separator {}

        // [新增] 指示器设置
        P.SwitchPreference {
            id: pShowInd
            name: "showIndicator"
            label: qsTr("Show Indicator")
            defaultValue: true
        }
        P.ObjectPreferenceGroup {
            visible: pShowInd.value
            syncProperties: true
            defaultValue: root.settings
            
            P.SelectPreference {
                name: "indicatorType"
                label: qsTr("Shape")
                model: [qsTr("Circle"), qsTr("Bar")]
                defaultValue: 0
            }
            P.SpinPreference {
                name: "indicatorWidth"
                label: qsTr("Width")
                defaultValue: 8
                from: 1
                to: 100
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            P.SpinPreference {
                name: "indicatorHeight"
                label: qsTr("Height")
                defaultValue: 8
                from: 1
                to: 100
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            P.SpinPreference {
                name: "indicatorOffset"
                label: qsTr("Offset from Center") // 距离中心的偏移量
                defaultValue: 28
                from: 0
                to: 250
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            NoDefaultColorPreference { name: "indicatorColor"; label: qsTr("Color"); defaultValue: "#FFFFFF" }
        }

        P.Separator {}

        // [新增] 内圈设置
        P.SwitchPreference {
            id: pShowInner
            name: "showInnerCircle"
            label: qsTr("Show Center Cap") // 显示中心盖/内圈
            defaultValue: false
        }
        P.ObjectPreferenceGroup {
            visible: pShowInner.value
            syncProperties: true
            defaultValue: root.settings

            P.SpinPreference {
                name: "innerRadius"
                label: qsTr("Radius")
                defaultValue: 20
                from: 1
                to: 200
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            P.SpinPreference {
                name: "innerHole"
                label: qsTr("Hole Ratio (%)") // 镂空比例
                defaultValue: 0
                from: 0
                to: 99
                stepSize: 1
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            NoDefaultColorPreference { name: "innerColor"; label: qsTr("Color"); defaultValue: "#40FFFFFF" }
        }

        P.Separator {}

        // 刻度
        P.SwitchPreference { name: "showTicks"; label: qsTr("Show Ticks"); defaultValue: true }
        P.ObjectPreferenceGroup {
            visible: settings.showTicks
            syncProperties: true
            defaultValue: root.settings
            P.SpinPreference {
                name: "tickLength"
                label: qsTr("Tick Length")
                defaultValue: 6
                from: 2
                to: 50
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            P.SpinPreference {
                name: "tickWidth"
                label: qsTr("Tick Width")
                defaultValue: 2
                from: 1
                to: 10
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
            NoDefaultColorPreference { name: "tickColor"; label: qsTr("Tick Color"); defaultValue: "#88FFFFFF" }
        }

        P.Separator {}

        // 外观
        NoDefaultColorPreference { name: "bgColor"; label: qsTr("Background Color"); defaultValue: "#40000000" }
        NoDefaultColorPreference { name: "borderColor"; label: qsTr("Border Color"); defaultValue: "#00AAFF" }
        P.SpinPreference {
            name: "borderWidth"
            label: qsTr("Border Width")
            defaultValue: 2
            from: 0
            to: 20
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        P.Separator {}

        // 动作
        P.ActionPreference { name: "actionLeft"; label: qsTr("Action (Left)") }
        P.ActionPreference { name: "actionRight"; label: qsTr("Action (Right)") }
    }

    // ============================================================
    //  界面绘制 (UI)
    // ============================================================
    Item {
        id: content
        anchors.fill: parent

        // 旋钮主体
        Rectangle {
            id: knobBody
            width: knobSize
            height: knobSize
            radius: width / 2
            anchors.centerIn: parent
            
            color: bgColor
            border.color: borderColor
            border.width: borderWidth

            // 1. 刻度盘 (静态)
            Canvas {
                id: tickCanvas
                anchors.fill: parent
                visible: showTicks
                
                Connections {
                    target: root
                    onSensitivityChanged: tickCanvas.requestPaint()
                    onTickColorChanged: tickCanvas.requestPaint()
                    onTickLengthChanged: tickCanvas.requestPaint()
                    onTickWidthChanged: tickCanvas.requestPaint()
                    onKnobSizeChanged: tickCanvas.requestPaint()
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    var cx = width / 2;
                    var cy = height / 2;
                    var r = width / 2 - borderWidth;
                    
                    var stepAngle = Math.max(1, sensitivity);
                    var count = Math.floor(360 / stepAngle);

                    ctx.strokeStyle = tickColor;
                    ctx.lineWidth = tickWidth;
                    ctx.lineCap = "round";

                    for (var i = 0; i < count; i++) {
                        var angleDeg = i * stepAngle;
                        var angleRad = (angleDeg - 90) * Math.PI / 180;
                        
                        ctx.beginPath();
                        var x1 = cx + r * Math.cos(angleRad);
                        var y1 = cy + r * Math.sin(angleRad);
                        var x2 = cx + (r - tickLength) * Math.cos(angleRad);
                        var y2 = cy + (r - tickLength) * Math.sin(angleRad);
                        
                        ctx.moveTo(x1, y1);
                        ctx.lineTo(x2, y2);
                        ctx.stroke();
                    }
                }
            }
            
            // 2. 内部圆/环 (装饰层，不随旋转动)
            Shape {
                visible: showInnerCircle
                anchors.centerIn: parent
                width: innerRadius * 2
                height: width
                
                // 开启多重采样抗锯齿
                layer.enabled: true
                layer.smooth: true
                layer.samples: 4
                
                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: innerColor
                    
                    // 外部圆
                    PathAngleArc {
                        centerX: innerRadius; centerY: innerRadius
                        radiusX: innerRadius; radiusY: innerRadius
                        startAngle: 0; sweepAngle: 360
                    }
                    
                    // 内部镂空圆 (Hole)
                    PathAngleArc {
                        centerX: innerRadius; centerY: innerRadius
                        radiusX: Math.max(0, innerRadius * innerHole)
                        radiusY: Math.max(0, innerRadius * innerHole)
                        startAngle: 0; sweepAngle: 360
                    }
                }
            }

            // 3. 旋转层 (指示器)
            Item {
                id: rotator
                anchors.fill: parent
                rotation: 0

                // [新增] 可配置的指示器
                Rectangle {
                    visible: showIndicator
                    width: indicatorWidth
                    height: indicatorHeight
                    // 圆形: radius = width/2, 条形: radius = 0 或 小数值
                    radius: indicatorType === 0 ? Math.min(width, height) / 2 : 2
                    color: indicatorColor
                    
                    // 定位：水平居中，垂直由 Offset 控制
                    // Offset 是距离圆心的距离。
                    // 0 度时，Indicator 应该在正上方 (y < center)
                    anchors.centerIn: parent
                    
                    // 使用 transform 进行位移，这样旋转中心依然是 parent 的中心
                    transform: Translate {
                        y: -indicatorOffset
                    }
                }
                
                // 平滑旋转动画 (吸附动画)
                Behavior on rotation {
                    id: rotBehavior
                    enabled: !mouseArea.pressed // 拖拽时禁用，松手时启用吸附
                    NumberAnimation { 
                        duration: 300 
                        easing.type: Easing.OutBack // 回弹效果
                        easing.overshoot: 1.0 
                    }
                }
            }

            // 4. 交互逻辑
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                
                property real accumulatedDelta: 0
                property real lastAngle: 0

                function getAngle(x, y) {
                    var cx = width / 2;
                    var cy = height / 2;
                    var dx = x - cx;
                    var dy = y - cy;
                    return (Math.atan2(dy, dx) * 180 / Math.PI) + 90;
                }

                onPressed: {
                    lastAngle = getAngle(mouse.x, mouse.y);
                    accumulatedDelta = 0;
                    // 按下时停止吸附动画，确保跟手
                    rotBehavior.enabled = false; 
                }

                onPositionChanged: {
                    var currentAngle = getAngle(mouse.x, mouse.y);
                    var delta = currentAngle - lastAngle;

                    if (delta > 180) delta -= 360;
                    if (delta < -180) delta += 360;

                    rotator.rotation += delta;
                    accumulatedDelta += delta;

                    // 触发逻辑
                    var step = sensitivity;
                    if (Math.abs(accumulatedDelta) >= step) {
                        var count = Math.floor(Math.abs(accumulatedDelta) / step);
                        var isRight = accumulatedDelta > 0;

                        for(var i=0; i<count; i++) {
                            triggerStep(isRight);
                        }

                        if (isRight) accumulatedDelta -= (count * step);
                        else accumulatedDelta += (count * step);
                    }

                    lastAngle = currentAngle;
                }

                // [新增] 松手自动吸附/复位
                onReleased: {
                    if (autoSnap) {
                        rotBehavior.enabled = true; // 启用动画
                        
                        var step = sensitivity;
                        // 计算最近的刻度角度
                        var targetRotation = Math.round(rotator.rotation / step) * step;
                        
                        // 设置目标角度，Behavior 会自动处理动画
                        rotator.rotation = targetRotation;
                        
                        // 重置累加器，防止下次点击时突变
                        accumulatedDelta = 0;
                    }
                }
            }
        }
    }
}