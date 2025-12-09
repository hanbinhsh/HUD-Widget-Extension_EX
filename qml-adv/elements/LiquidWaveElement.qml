import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12 // 如果需要高级滤镜，通常需要这个，这里暂时只用Canvas

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    dataConfiguration: settings.data ?? undefined

    // --- 核心参数计算 ---
    readonly property int padSize: 4
    readonly property int centerX: width / 2
    readonly property int centerY: height / 2
    readonly property int radius: Math.min(width, height) / 2 - padSize

    // --- 样式属性 (从 settings 读取) ---
    readonly property color waveColor: settings.waveColor ?? "#00AAFF"
    readonly property color bgColor: settings.bgColor ?? "#22000000"
    readonly property color strokeColor: settings.strokeColor ?? "#FFFFFF"
    readonly property int strokeSize: settings.strokeSize ?? 2
    readonly property bool showText: settings.showText ?? true
    readonly property color textColor: settings.textColor ?? "#FFFFFF"
    
    // --- 波浪物理属性 ---
    // 振幅 (波浪高低)
    readonly property real waveAmplitude: settings.waveAmplitude ?? 5 // 相对于半径的比例
    // 频率 (波浪密集度)
    readonly property real waveFrequency: settings.waveFrequency ?? 1.5 
    // 速度
    readonly property real waveSpeed: settings.waveSpeed ?? 10

    // --- 数据处理 ---
    // 假设数据源返回的是 0-100 的数值 (如 CPU, 内存)
    readonly property real rawData: {
        if (!output.result) return 0;
        // 尝试解析字符串中的第一个数字
        var str = String(output.result).trim();
        var match = str.match(/-?[\d\.]+/);
        return match ? Number(match[0]) : 0;
    }
    
    // 最大值，用于计算百分比 (0.0 - 1.0)
    readonly property real maxValue: settings.maxValue ?? 100

    // 显示用的平滑数值 (0.0 - 1.0)
    property real currentProgress: 0
    // 显示用的原始数值 (用于文本显示)
    property real currentRawValue: 0

    title: qsTranslate("utils", "Liquid Sphere")
    implicitWidth: 150
    implicitHeight: 150

    // 数值平滑动画
    Behavior on currentProgress { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on currentRawValue { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    onRawDataChanged: {
        currentRawValue = rawData;
        var p = rawData / maxValue;
        currentProgress = Math.max(0, Math.min(1, p)); // 限制在 0~1 之间
    }

    // 监听属性变化重绘
    onWaveColorChanged: canvas.requestPaint()
    onBgColorChanged: canvas.requestPaint()
    onStrokeColorChanged: canvas.requestPaint()
    
    // --- 设置面板 ---
    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.DataPreference {
            name: "data"
            label: qsTr("Data Source")
            environment: thiz.environment
        }

        P.SpinPreference {
            name: "maxValue"
            label: qsTr("Max Value")
            defaultValue: 100
            from: 1
            to: 10000
            display: P.TextFieldPreference.ExpandLabel
        }

        P.Separator {}

        NoDefaultColorPreference {
            name: "waveColor"
            label: qsTr("Liquid Color")
            defaultValue: "#00AAFF"
        }

        NoDefaultColorPreference {
            name: "bgColor"
            label: qsTr("Background Color")
            defaultValue: "#22000000"
        }

        NoDefaultColorPreference {
            name: "strokeColor"
            label: qsTr("Border Color")
            defaultValue: "#FFFFFF"
        }

        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Border Size")
            defaultValue: 2
            from: 0
            to: 10
            display: P.TextFieldPreference.ExpandLabel
        }
        
        P.Separator {}

        P.SwitchPreference {
            name: "showText"
            label: qsTr("Show Text")
            defaultValue: true
        }
        
        NoDefaultColorPreference {
            name: "textColor"
            label: qsTr("Text Color")
            defaultValue: "#FFFFFF"
            visible: showText
        }

        P.Separator {}

        // 高级波浪设置
        P.SpinPreference {
            name: "waveSpeed"
            label: qsTr("Wave Speed")
            defaultValue: 10
            from: 0
            to: 100
            stepSize: 1
            display: P.TextFieldPreference.ExpandLabel
        }
        
        P.SpinPreference {
            name: "waveAmplitude"
            label: qsTr("Wave Height")
            defaultValue: 5
            from: 0
            to: 20
            stepSize: 1
            display: P.TextFieldPreference.ExpandLabel
        }
    }

    function colorAlpha(c, a) { 
        return Qt.rgba(c.r, c.g, c.b, a); 
    }

    // --- 动画驱动器 ---
    // 这是一个高频计时器，用于驱动波浪的相位 (Phase) 变化
    Timer {
        id: waveTimer
        interval: 16 // 约 60 FPS
        running: true
        repeat: true
        property real phase: 0
        onTriggered: {
            // 增加相位，实现波浪移动
            phase += waveSpeed/100;
            // 防止数值溢出，虽然JS能处理很大数字，但周期性重置是个好习惯
            if (phase > Math.PI * 2) {
                phase -= Math.PI * 2;
            }
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        // 开启渲染优化
        renderStrategy: Canvas.Threaded
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            
            ctx.clearRect(0, 0, w, h);

            // 1. 绘制圆形外框和背景
            // 保存状态，以便后续使用 clip
            ctx.save();
            
            // 定义圆形路径
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
            ctx.closePath();

            // 剪切：之后的所有绘制都只会显示在圆内
            ctx.clip();

            // 绘制背景色
            ctx.fillStyle = bgColor;
            ctx.fill();

            // 2. 绘制波浪
            // 我们绘制两层波浪：后层较浅，前层较深

            const amp = radius * waveAmplitude/100; // 振幅像素值
            const waterLevel = 2 * radius * (1 - currentProgress) + padSize; // 水位高度 (y轴坐标)
            
            // [后层波浪]
            // 相位偏移一点，看起来错落有致
            drawWave(ctx, waveTimer.phase + 1.5, 0.6, waterLevel, colorAlpha(waveColor, 0.4));
            
            // [前层波浪]
            drawWave(ctx, waveTimer.phase, 1.0, waterLevel, waveColor);

            // 恢复剪切前的状态
            ctx.restore();

            // 3. 绘制圆形边框 (Stroke)
            // 边框画在外面，不需要 clip
            if (strokeSize > 0) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                ctx.lineWidth = strokeSize;
                ctx.strokeStyle = strokeColor;
                ctx.stroke();
            }
        }

        // 辅助函数：绘制单个正弦波
        function drawWave(ctx, offset, freqMult, level, color) {
            ctx.fillStyle = color;
            ctx.beginPath();
            
            // 从左侧开始
            // x 坐标遍历整个宽度
            // y = A * sin(kx + offset) + level
            
            const startX = centerX - radius;
            const endX = centerX + radius;
            
            // 为了保证波浪充满圆形，我们遍历 x
            // 步长设为 2~4 像素，平衡性能和画质
            const step = 2; 

            ctx.moveTo(startX, height); // 左下角起点

            const amp = radius * waveAmplitude/100; // 振幅像素值

            for (let x = startX; x <= endX; x += step) {
                // 将 x 映射到弧度： (x / width) * 频率
                const angle = ((x - startX) / (radius * 2)) * (Math.PI * 2 * waveFrequency * freqMult) + offset;
                const y = Math.sin(angle) * amp + level;
                ctx.lineTo(x, y);
            }

            // 封闭路径：右下 -> 左下
            ctx.lineTo(endX, height);
            ctx.lineTo(startX, height);
            ctx.closePath();
            ctx.fill();
        }
    }

    // --- 中心文字 ---
    // 使用 Item 包裹以便居中，且不被 Canvas 的重绘影响
    Item {
        anchors.fill: parent
        visible: showText
        
        Column {
            anchors.centerIn: parent
            spacing: -5 // 让百分号稍微紧凑一点

            Text {
                id: valueText
                anchors.horizontalCenter: parent.horizontalCenter
                // 显示整数
                text: Math.round(currentRawValue)
                color: textColor
                font.pixelSize: radius * 0.8
                font.bold: true
                font.family: "Segoe UI, Roboto, Helvetica"
                
                // 给文字加一点阴影，防止波浪颜色太浅看不清
                style: Text.Outline
                styleColor: colorAlpha(bgColor, 0.5)
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "%"
                color: colorAlpha(textColor, 0.8)
                font.pixelSize: radius * 0.25
                font.bold: true
                style: Text.Outline
                styleColor: colorAlpha(bgColor, 0.5)
            }
        }
    }

    // 数据获取组件
    NVG.DataSourceTextOutput {
        id: output
        source: thiz.dataSource ?? null
    }
}