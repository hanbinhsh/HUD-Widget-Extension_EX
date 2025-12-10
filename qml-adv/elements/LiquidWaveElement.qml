import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    dataConfiguration: settings.data ?? undefined

    // --- 核心尺寸参数 ---
    readonly property int padSize: 4
    readonly property int centerX: width / 2
    readonly property int centerY: height / 2
    readonly property int radius: Math.min(width, height) / 2 - padSize

    // --- 样式属性 ---
    readonly property color waveColor: settings.waveColor ?? "#00AAFF"
    readonly property color bgColor: settings.bgColor ?? "#22000000"
    readonly property color strokeColor: settings.strokeColor ?? "#FFFFFF"
    readonly property int strokeSize: settings.strokeSize ?? 2
    readonly property bool showText: settings.showText ?? true
    readonly property color textColor: settings.textColor ?? "#FFFFFF"
    
    // --- 形状控制 ---
    readonly property bool isPolygon: settings.isPolygon ?? false
    readonly property int polygonSides: settings.polygonSides ?? 6
    
    // --- [新增] 旋转角度 ---
    readonly property real rotationAngle: settings.rotationAngle ?? 0
    
    // --- 波浪物理属性 ---
    readonly property real waveAmplitude: settings.waveAmplitude ?? 5 
    readonly property real waveFrequency: settings.waveFrequency ?? 1.5 
    readonly property real waveSpeed: settings.waveSpeed ?? 10

    // --- 数据处理 ---
    readonly property real rawData: {
        if (!output.result) return 0;
        var str = String(output.result).trim();
        var match = str.match(/-?[\d\.]+/);
        return match ? Number(match[0]) : 0;
    }
    
    readonly property real maxValue: settings.maxValue ?? 100

    property real currentProgress: 0
    property real currentRawValue: 0

    title: qsTranslate("utils", "Liquid Shape")
    implicitWidth: 150
    implicitHeight: 150

    // 数值平滑过渡动画
    Behavior on currentProgress { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on currentRawValue { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    onRawDataChanged: {
        currentRawValue = rawData;
        var p = rawData / maxValue;
        currentProgress = Math.max(0, Math.min(1, p));
    }

    // 监听属性变化触发重绘
    onWaveColorChanged: canvas.requestPaint()
    onBgColorChanged: canvas.requestPaint()
    onStrokeColorChanged: canvas.requestPaint()
    onIsPolygonChanged: canvas.requestPaint()
    onPolygonSidesChanged: canvas.requestPaint()
    onWaveSpeedChanged: canvas.requestPaint()
    // [新增] 监听旋转
    onRotationAngleChanged: canvas.requestPaint()
    
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

        // --- 形状设置 ---
        P.SwitchPreference {
            id: pIsPolygon
            name: "isPolygon"
            label: qsTr("Polygon Shape") 
            defaultValue: false
        }

        P.SpinPreference {
            name: "polygonSides"
            label: qsTr("Sides Count") 
            defaultValue: 6
            from: 3
            to: 12
            stepSize: 1
            visible: pIsPolygon.value 
            display: P.TextFieldPreference.ExpandLabel
        }

        // --- [新增] 旋转设置 ---
        P.SliderPreference {
            name: "rotationAngle"
            label: qsTr("Rotation")
            displayValue: value + " °"
            defaultValue: 0
            from: -180
            to: 180
            stepSize: 1
            live: true // 实时预览
            visible: pIsPolygon.value // 只有多边形才需要旋转，圆形转了也看不出来
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

    Timer {
        id: waveTimer
        interval: 16 
        running: true
        repeat: true
        property real phase: 0
        onTriggered: {
            phase += waveSpeed / 100;
            if (phase > Math.PI * 2) {
                phase -= Math.PI * 2;
            }
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Threaded
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            
            ctx.clearRect(0, 0, w, h);
            ctx.save();

            // 1. 计算顶点 (应用旋转)
            let vertices = [];
            let visualOffsetY = 0; 
            let minY = 0;
            let maxY = 0;

            if (thiz.isPolygon) {
                const sides = Math.max(3, thiz.polygonSides);
                const step = (2 * Math.PI) / sides;
                
                // [关键修改] 将用户设置的角度转换为弧度，加到起始角度上
                // -Math.PI / 2 是为了让多边形默认尖角朝上
                const rotationRad = thiz.rotationAngle * (Math.PI / 180);
                const startAngle = -Math.PI / 2 + rotationRad;

                let localMinY = 10000;
                let localMaxY = -10000;

                for (let i = 0; i < sides; i++) {
                    const angle = startAngle + step * i;
                    // 计算相对圆心的坐标
                    const vx = radius * Math.cos(angle);
                    const vy = radius * Math.sin(angle);
                    vertices.push({x: vx, y: vy});
                    
                    if (vy < localMinY) localMinY = vy;
                    if (vy > localMaxY) localMaxY = vy;
                }
                
                // 自动居中计算
                // 无论怎么旋转，我们都找出旋转后图形的中心 Y 轴偏移
                const shapeCenterY = (localMinY + localMaxY) / 2;
                visualOffsetY = -shapeCenterY;
                
                // 记录边界用于水位计算
                minY = localMinY;
                maxY = localMaxY;
            } else {
                // 圆形
                minY = -radius;
                maxY = radius;
                visualOffsetY = 0;
            }

            // 2. 将坐标系移到视觉中心
            ctx.translate(centerX, centerY + visualOffsetY);

            // 3. 绘制剪切路径
            ctx.beginPath();
            if (thiz.isPolygon) {
                if (vertices.length > 0) {
                    ctx.moveTo(vertices[0].x, vertices[0].y);
                    for (let i = 1; i < vertices.length; i++) {
                        ctx.lineTo(vertices[i].x, vertices[i].y);
                    }
                }
            } else {
                ctx.arc(0, 0, radius, 0, Math.PI * 2);
            }
            ctx.closePath();
            
            // 剪切：之后绘制的内容会被限制在这个旋转后的形状内
            ctx.clip();

            // 绘制背景
            ctx.fillStyle = bgColor;
            ctx.fill();

            // 4. 绘制波浪
            // 关键点：我们没有使用 ctx.rotate() 旋转画布，只是旋转了顶点。
            // 所以 drawWave 里的水平线绘制 (lineTo x, y) 依然是相对于屏幕水平的。
            
            const fillHeight = maxY - minY;
            const currentLevelY = maxY - (fillHeight * currentProgress); 

            // 注意：safeBottom 必须足够大，因为旋转后的多边形可能最底点并不是 radius
            // 但其实上面已经算出了 localMaxY (即maxY)，所以用 maxY 即可
            drawWave(ctx, waveTimer.phase + 1.5, 0.6, currentLevelY, colorAlpha(waveColor, 0.4), minY, maxY);
            drawWave(ctx, waveTimer.phase, 1.0, currentLevelY, waveColor, minY, maxY);

            // 恢复剪切状态
            ctx.restore(); 

            // 5. 绘制边框
            if (strokeSize > 0) {
                ctx.save();
                ctx.translate(centerX, centerY + visualOffsetY);
                
                ctx.beginPath();
                if (thiz.isPolygon) {
                    if (vertices.length > 0) {
                        ctx.moveTo(vertices[0].x, vertices[0].y);
                        for (let j = 1; j < vertices.length; j++) {
                            ctx.lineTo(vertices[j].x, vertices[j].y);
                        }
                    }
                } else {
                    ctx.arc(0, 0, radius, 0, Math.PI * 2);
                }
                ctx.closePath();
                
                ctx.lineWidth = strokeSize;
                ctx.strokeStyle = strokeColor;
                ctx.stroke();
                ctx.restore();
            }
        }

        function drawWave(ctx, offset, freqMult, levelY, color, topLimit, bottomLimit) {
            ctx.fillStyle = color;
            ctx.beginPath();
            
            const startX = -radius; 
            const endX = radius;
            const step = 2; 

            const amp = radius * waveAmplitude / 100; 

            // 使用 maxY 作为底部，多加一点 buffer 防止浮点误差导致的缝隙
            const safeBottom = bottomLimit + 5; 
            
            ctx.moveTo(startX, safeBottom);

            for (let x = startX; x <= endX; x += step) {
                const angle = ((x - startX) / (radius * 2)) * (Math.PI * 2 * waveFrequency * freqMult) + offset;
                const y = Math.sin(angle) * amp + levelY;
                ctx.lineTo(x, y);
            }

            ctx.lineTo(endX, safeBottom);
            ctx.lineTo(startX, safeBottom);
            ctx.closePath();
            ctx.fill();
        }
    }

    Item {
        anchors.fill: parent
        visible: showText
        
        Column {
            anchors.centerIn: parent
            spacing: -5 

            Text {
                id: valueText
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(currentRawValue)
                color: textColor
                font.pixelSize: radius * 0.8
                font.bold: true
                font.family: "Segoe UI, Roboto, Helvetica"
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

    NVG.DataSourceTextOutput {
        id: output
        source: thiz.dataSource ?? null
    }
}