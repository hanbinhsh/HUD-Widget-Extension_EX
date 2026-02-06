import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12 // 引入图形特效库用于 GPU 发光

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    // --- 尺寸与位置 ---
    readonly property int padSize: 20
    readonly property int centerX: width / 2
    readonly property int centerY: height / 2
    readonly property int maxRadius: Math.min(width, height) / 2 - padSize

    // --- 外观配置 ---
    readonly property int holeRadiusPercent: settings.holeRadius ?? 0
    readonly property real startAngleDeg: settings.startAngle ?? -90
    
    readonly property color strokeColor: settings.strokeColor ?? "#FFFFFF"
    readonly property int strokeSize: settings.strokeSize ?? 2
    readonly property bool strokeGlow: settings.strokeGlow ?? true
    
    // 默认调色板
    property var defaultColors: ["#FF5555", "#55FF55", "#5555FF", "#FFFF55", "#55FFFF", "#FF55FF", "#FFAA00", "#00AAFF"]
    
    readonly property bool enableAnimation: settings.enableAnimation ?? true

    // --- 数据处理 ---
    readonly property var dataOutputs: {
        if (!output.result || typeof output.result !== "string")
            return [];

        return output.result
                .trim()
                .split(/\s+/)
                .map(v => Number(v));
    }
    
    // 动态获取数据长度，最少显示1个占位
    readonly property int dataCount: Math.max(1, dataOutputs.length)

    // 监听数据变化
    onDataOutputsChanged: syncData()

    function syncData() {
        // 同步数据到动画器
        for (var i = 0; i < valueAnimator.count; i++) {
            var val = (i < dataOutputs.length) ? dataOutputs[i] : 0;
            if (valueAnimator.itemAt(i)) {
                valueAnimator.itemAt(i).value = Math.max(0, val);
            }
        }
        // 请求重绘
        fillCanvas.requestPaint()
        strokeCanvas.requestPaint()
    }

    // 监听外观变化
    onHoleRadiusPercentChanged: { fillCanvas.requestPaint(); strokeCanvas.requestPaint() }
    onStartAngleDegChanged: { fillCanvas.requestPaint(); strokeCanvas.requestPaint() }
    onStrokeColorChanged: strokeCanvas.requestPaint()
    onStrokeSizeChanged: strokeCanvas.requestPaint()
    
    // 注意：Glow 属性变化不需要 requestPaint，因为它是后处理效果

    title: qsTranslate("utils", "Pie Chart")
    implicitWidth: 200
    implicitHeight: 200
    
    dataConfiguration: settings.data ?? undefined

    // --- 设置面板 ---
    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.DataPreference {
            name: "data"
            label: qsTr("Data")
            environment: thiz.environment
            message: qsTr("You need to select the custom script in the data selector among other data, choose multiple input data, and select asynchronous data in the example below.")
        }

        P.Separator {}

        P.SliderPreference {
            name: "holeRadius"
            label: qsTr("Hole Size")
            displayValue: value + "%"
            defaultValue: 0
            from: 0
            to: 90
            stepSize: 1
            live: true
        }

        P.SliderPreference {
            name: "startAngle"
            label: qsTr("Rotation")
            displayValue: value + "°"
            defaultValue: -90
            from: -360
            to: 360
            stepSize: 1
            live: true
        }

        P.Separator {}

        NoDefaultColorPreference {
            name: "strokeColor"
            label: qsTr("Border Color")
            defaultValue: "#FFFFFF"
        }

        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Border Width")
            defaultValue: 2
            from: 0
            to: 10
            stepSize: 1
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SwitchPreference {
            name: "strokeGlow"
            label: qsTr("Border Glow")
            defaultValue: true
        }

        P.Separator {}

        // [修改]：根据检测到的数据数量动态生成颜色设置项
        Repeater {
            model: thiz.dataCount // 绑定到数据长度
            NoDefaultColorPreference {
                name: "sliceColor" + index
                label: qsTr("Slice ") + (index + 1)
                // 默认值循环取自 defaultColors
                defaultValue: thiz.defaultColors[index % thiz.defaultColors.length]
            }
        }

        P.Separator {}

        P.SwitchPreference {
            name: "enableAnimation"
            label: qsTr("Enable Animation")
            defaultValue: true
        }
    }

    // --- 动画代理器 ---
    // 为了应对动态数据长度，这里设置一个较大的容量，或者也可以动态 model
    // 建议设置一个合理的上限，比如 32
    Repeater {
        id: valueAnimator
        model: 32 
        
        Item {
            property real value: 0
            Behavior on value {
                enabled: thiz.enableAnimation
                NumberAnimation { 
                    duration: 500
                    easing.type: Easing.OutCubic 
                }
            }
            // 动画过程中触发重绘
            onValueChanged: {
                // 只有当前正在显示的数据索引发生变化才重绘，节省性能
                if (index < thiz.dataCount) {
                     fillCanvas.requestPaint()
                     strokeCanvas.requestPaint()
                }
            }
        }
    }

    // --- 绘图逻辑：图层分离 ---

    // 1. 底层：填充层 (Fill Layer)
    // 这一层只画颜色，不画边框，没有发光效果
    Canvas {
        id: fillCanvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var totalValue = calculateTotal();
            if (totalValue <= 0.001) return;

            ctx.save();
            ctx.translate(centerX, centerY);

            var currentStartRad = (startAngleDeg * Math.PI) / 180;
            var holeR = maxRadius * (holeRadiusPercent / 100.0);
            
            for (var i = 0; i < thiz.dataCount; i++) {
                var val = valueAnimator.itemAt(i).value;
                if (val <= 0) continue;

                var sliceRad = (val / totalValue) * (2 * Math.PI);
                var endRad = currentStartRad + sliceRad;

                // 路径绘制
                ctx.beginPath();
                ctx.arc(0, 0, maxRadius, currentStartRad, endRad, false);
                if (holeRadiusPercent > 0) {
                    ctx.arc(0, 0, holeR, endRad, currentStartRad, true);
                } else {
                    ctx.lineTo(0, 0);
                }
                ctx.closePath();

                // 获取颜色
                var colorKey = "sliceColor" + i;
                var sliceColor = thiz.settings[colorKey] ?? thiz.defaultColors[i % thiz.defaultColors.length];
                
                ctx.fillStyle = sliceColor;
                ctx.fill();

                currentStartRad = endRad;
            }
            ctx.restore();
        }
    }

    // 2. 顶层：描边层 (Stroke Layer)
    // 这一层只画线，背景透明。我们对这个 Item 应用 Glow 效果。
    Item {
        id: strokeContainer
        anchors.fill: parent
        visible: strokeSize > 0 // 如果没有边框，直接隐藏这一层节省性能

        // [核心优化] 使用 GPU Shader 实现发光，而非 Canvas 软件发光
        layer.enabled: strokeGlow
        layer.effect: Glow {
            samples: 15     // 采样数，越高越平滑但消耗增加
            radius: 8       // 发光半径
            spread: 0.3     // 发光强度
            color: strokeColor
            transparentBorder: true
            cached: false   // 动画时不能缓存
        }

        Canvas {
            id: strokeCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                // 如果没有边框宽度，直接跳过绘制
                if (strokeSize <= 0) return;

                var totalValue = calculateTotal();
                if (totalValue <= 0.001) return;

                ctx.save();
                ctx.translate(centerX, centerY);

                var currentStartRad = (startAngleDeg * Math.PI) / 180;
                var holeR = maxRadius * (holeRadiusPercent / 100.0);
                
                ctx.strokeStyle = strokeColor;
                ctx.lineWidth = strokeSize;
                // 线条结合处形状，Round 会更圆润
                ctx.lineJoin = "round"; 

                for (var i = 0; i < thiz.dataCount; i++) {
                    var val = valueAnimator.itemAt(i).value;
                    if (val <= 0) continue;

                    var sliceRad = (val / totalValue) * (2 * Math.PI);
                    var endRad = currentStartRad + sliceRad;

                    ctx.beginPath();
                    ctx.arc(0, 0, maxRadius, currentStartRad, endRad, false);
                    if (holeRadiusPercent > 0) {
                        ctx.arc(0, 0, holeR, endRad, currentStartRad, true);
                    } else {
                        ctx.lineTo(0, 0);
                    }
                    ctx.closePath();
                    ctx.stroke();

                    currentStartRad = endRad;
                }
                ctx.restore();
            }
        }
    }

    // 辅助函数：计算总值
    function calculateTotal() {
        var total = 0;
        for (var i = 0; i < thiz.dataCount; i++) {
            var val = valueAnimator.itemAt(i).value;
            if (val > 0) total += val;
        }
        return total;
    }

    // 辅助数据源输出
    NVG.DataSourceTextOutput {
        id: output
        source: thiz.dataSource ?? null
    }
}