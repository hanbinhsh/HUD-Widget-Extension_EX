import QtQuick 2.12
import QtQuick.Controls 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import "../../../top.mashiros.widget.advp/qml/" as ADVP

import ".." 

DataSourceElement {
    id: thiz

    title: qsTranslate("utils", "Audio Shape")
    implicitWidth: 300
    implicitHeight: 300

    // --- 核心配置 ---
    readonly property int padSize: 10
    readonly property int centerX: width / 2
    readonly property int centerY: height / 2
    
    readonly property int innerRadius: (Math.min(width, height) / 2) * (settings.innerRatio ?? 60) / 100
    readonly property int maxRadius: Math.min(width, height) / 2 - padSize

    // --- 采样点数量 ---
    readonly property int barCount: settings.barCount ?? 64

    // --- [新增] 双通道立体声开关 ---
    readonly property bool stereoMode: settings.stereoMode ?? false

    // --- 形状模式 ---
    // 0=Circle, 1=Polygon, 2=Rose/Parametric, 3=Custom Formula
    readonly property int shapeMode: settings.shapeMode ?? 0

    // --- 对称模式 ---
    // 0=Mirror(左右镜像), 1=Radial(中心环绕)
    readonly property int symmetryMode: settings.symmetryMode ?? 0

    // 参数
    readonly property int polygonSides: settings.polygonSides ?? 6
    readonly property real paramN: settings.paramN ?? 2.0 
    readonly property real paramD: settings.paramD ?? 1.0 
    property string customFormula: settings.customFormula ?? "Math.abs(Math.cos(3*t))"
    property var _compiledFunc: null 
    readonly property real rotationAngle: settings.rotationAngle ?? 0
    readonly property int jumpMode: settings.jumpMode ?? 0

    // --- 静默线条 ---
    readonly property bool showIdleLine: settings.showIdleLine ?? true
    readonly property int idleLineWidth: settings.idleLineWidth ?? 1
    readonly property color idleLineColor: settings.idleLineColor ?? "#66FFFFFF"

    // --- 样式 ---
    readonly property color barColorStart: settings.barColorStart ?? "#00AAFF"
    readonly property color barColorEnd: settings.barColorEnd ?? "#AA00FF"
    readonly property int barWidth: settings.barWidth ?? 2
    readonly property bool roundCap: settings.roundCap ?? true
    readonly property real sensitivity: settings.sensitivity ?? 100 
    readonly property real decay: settings.decay ?? 0.05 

    // --- [修改] 数据存储分开左右通道 ---
    property var displayDataL: new Array(barCount).fill(0)
    property var displayDataR: new Array(barCount).fill(0)

    // 重置数组
    onBarCountChanged: {
        displayDataL = new Array(barCount).fill(0);
        displayDataR = new Array(barCount).fill(0);
        canvas.requestPaint();
    }

    // --- 设置面板 ---
    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SpinPreference {
            name: "sensitivity"
            label: qsTr("Sensitivity")
            defaultValue: 100
            from: 1
            to: 10000
            stepSize: 10
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SpinPreference {
            name: "innerRatio"
            label: qsTr("Scale / Radius")
            defaultValue: 60
            from: 1
            to: 100
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SpinPreference {
            name: "barCount"
            label: qsTr("Bar Count")
            defaultValue: 64
            from: 16
            to: 128 
            stepSize: 16
            display: P.TextFieldPreference.ExpandLabel
        }
        
        // --- [新增] 立体声开关 ---
        P.SwitchPreference {
            name: "stereoMode"
            label: qsTr("Dual Channel (Stereo)")
            defaultValue: false
        }

        P.Separator {}

        P.SelectPreference {
            name: "shapeMode"
            label: qsTr("Shape Mode")
            defaultValue: 0
            model: [ qsTr("Circle"), qsTr("Polygon"), qsTr("Rose / Star"), qsTr("Custom Formula") ]
        }
        
        P.SelectPreference {
            name: "symmetryMode"
            label: qsTr("Symmetry")
            defaultValue: 0
            model: [ qsTr("Mirror (Left/Right)"), qsTr("Radial (360°)") ]
        }

        P.SpinPreference {
            name: "polygonSides"
            label: qsTr("Sides")
            defaultValue: 6
            from: 2 
            to: 16
            visible: shapeMode === 1
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SliderPreference {
            name: "paramN"
            label: qsTr("Petals (n)")
            defaultValue: 2.0
            from: 1.0
            to: 10.0
            stepSize: 0.1
            visible: shapeMode === 2
            live: true
            displayValue: value.toFixed(1)
        }
        P.SliderPreference {
            name: "paramD"
            label: qsTr("Shape (d)")
            defaultValue: 1.0
            from: 0.1
            to: 4.0
            stepSize: 0.1
            visible: shapeMode === 2
            live: true
            displayValue: value.toFixed(1)
        }

        P.TextFieldPreference {
            name: "customFormula"
            label: qsTr("r(t)=")
            defaultValue: "Math.abs(Math.cos(3*t))"
            hint: "e.g. 1 - Math.sin(t)"
            visible: shapeMode === 3
        }

        P.Separator {}

        P.SliderPreference {
            name: "rotationAngle"
            label: qsTr("Rotation")
            defaultValue: 0
            from: -180
            to: 180
            stepSize: 1
            displayValue: value + "°"
            live: true
        }

        P.SelectPreference {
            name: "jumpMode"
            label: qsTr("Jump Mode")
            defaultValue: 0
            model: [ qsTr("Outer (Above)"), qsTr("Inner (Below)"), qsTr("Both") ]
        }
        
        P.Separator {}

        P.SwitchPreference {
            name: "showIdleLine"
            label: qsTr("Show Base Line") 
            defaultValue: true
        }
        P.SpinPreference {
            name: "idleLineWidth"
            label: qsTr("Base Line Width")
            defaultValue: 1
            from: 1
            to: 10
            visible: showIdleLine
            display: P.TextFieldPreference.ExpandLabel
        }
        NoDefaultColorPreference {
            name: "idleLineColor"
            label: qsTr("Base Line Color")
            defaultValue: "#66FFFFFF"
            visible: showIdleLine
        }

        P.Separator {}

        NoDefaultColorPreference {
            name: "barColorStart"
            label: qsTr("Color Start")
            defaultValue: "#00AAFF"
        }
        NoDefaultColorPreference {
            name: "barColorEnd"
            label: qsTr("Color End")
            defaultValue: "#AA00FF"
        }

        P.SpinPreference {
            name: "barWidth"
            label: qsTr("Bar Width")
            defaultValue: 2
            from: 1
            to: 20
            display: P.TextFieldPreference.ExpandLabel
        }
        
        P.SwitchPreference {
            name: "roundCap"
            label: qsTr("Round Cap")
            defaultValue: true
        }
        
        P.SliderPreference {
            name: "decay"
            label: qsTr("Smoothness") 
            defaultValue: 0.05
            from: 0.01
            to: 0.3
            stepSize: 0.01
            live: true
            displayValue: Math.round(value * 100)
        }
    }

    onShapeModeChanged: { compileCustomFunc(); canvas.requestPaint(); }
    onSymmetryModeChanged: canvas.requestPaint()
    onCustomFormulaChanged: { compileCustomFunc(); canvas.requestPaint(); }
    onParamNChanged: canvas.requestPaint()
    onParamDChanged: canvas.requestPaint()
    onPolygonSidesChanged: canvas.requestPaint()
    onRotationAngleChanged: canvas.requestPaint()
    onJumpModeChanged: canvas.requestPaint()
    onShowIdleLineChanged: canvas.requestPaint()
    onIdleLineWidthChanged: canvas.requestPaint()
    onIdleLineColorChanged: canvas.requestPaint()
    // [新增] 监听立体声模式
    onStereoModeChanged: canvas.requestPaint()

    Component.onCompleted: compileCustomFunc()

    function compileCustomFunc() {
        if (shapeMode !== 3) return;
        try {
            var body = "return " + customFormula + ";";
            _compiledFunc = new Function("t", body);
        } catch (e) {
            console.error("Formula Error:", e.message);
            _compiledFunc = function(t) { return 1; }; 
        }
    }

    Connections {
        enabled: widget.NVG.View.exposed
        target: ADVP.Common
        Component.onCompleted: { if (!ADVP.Common) console.error("Audio Ring: ADVP.Common is NULL!") }
        onAudioDataUpdated: thiz.updateSpectrum(audioData)
    }

    // --- 数据更新逻辑 (分离左右通道) ---
    function updateSpectrum(audioData) {
        if (!audioData) return;
        
        let arrL = thiz.displayDataL;
        let arrR = thiz.displayDataR;

        // 保护：数组长度重置
        if (arrL.length !== thiz.barCount) {
            arrL = new Array(thiz.barCount).fill(0);
            arrR = new Array(thiz.barCount).fill(0);
            thiz.displayDataL = arrL;
            thiz.displayDataR = arrR;
        }

        let needsRepaint = false;
        let multiplier = 0.01 * sensitivity; 
        
        // 128个数据点，0-63是左声道，64-127是右声道
        const fftSize = 128;
        const channelSize = 64;

        for (let i = 0; i < thiz.barCount; i++) {
            // 映射索引：将 i 映射到 0~63
            let srcIndex = Math.floor(i * (channelSize / thiz.barCount));
            if (srcIndex >= channelSize) srcIndex = channelSize - 1;

            // 获取原始数据
            let rawL = (audioData[srcIndex] || 0) * multiplier;
            let rawR = (audioData[srcIndex + channelSize] || 0) * multiplier;

            // 如果关闭立体声，取平均值
            if (!stereoMode) {
                let avg = (rawL + rawR) / 2;
                rawL = avg;
                rawR = avg;
            }

            // --- 处理左通道衰减 ---
            let oldL = arrL[i];
            let newL = oldL;
            if (rawL > oldL) newL = rawL;
            else {
                newL = oldL - (oldL * decay) - 0.5;
                if (newL < 0) newL = 0;
            }
            if (Math.abs(newL - oldL) > 0.01) {
                arrL[i] = newL;
                needsRepaint = true;
            }

            // --- 处理右通道衰减 ---
            let oldR = arrR[i];
            let newR = oldR;
            if (rawR > oldR) newR = rawR;
            else {
                newR = oldR - (oldR * decay) - 0.5;
                if (newR < 0) newR = 0;
            }
            if (Math.abs(newR - oldR) > 0.01) {
                arrR[i] = newR;
                needsRepaint = true;
            }
        }

        if (needsRepaint) canvas.requestPaint();
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
            ctx.translate(centerX, centerY);

            // 1. 底座
            if (showIdleLine) {
                drawBaseShape(ctx);
            }

            // 2. 渐变
            var gradient = ctx.createRadialGradient(0, 0, innerRadius * 0.5, 0, 0, maxRadius);
            gradient.addColorStop(0, barColorStart);
            gradient.addColorStop(1, barColorEnd);

            ctx.fillStyle = gradient;
            ctx.strokeStyle = gradient;
            ctx.lineCap = roundCap ? "round" : "butt";
            ctx.lineWidth = barWidth;

            // 3. 绘制频谱
            const totalBars = barCount; 
            const rotRad = thiz.rotationAngle * Math.PI / 180;
            
            // === 直线模式 ===
            if (shapeMode === 1 && polygonSides === 2) {
                let nx = Math.cos(rotRad);
                let ny = Math.sin(rotRad);
                let px = -Math.sin(rotRad);
                let py = Math.cos(rotRad);

                for (let i = 0; i < totalBars; i++) {
                    const valL = displayDataL[i];
                    const valR = displayDataR[i];
                    
                    let progress = i / totalBars; 
                    
                    if (symmetryMode === 0) {
                        // Mirror Mode: 左边用Left数据，右边用Right数据
                        // 0 (Low) -> Center, 1 (High) -> Tips
                        let offset = progress * innerRadius; 
                        
                        if (valR > 0.1)
                            drawLinearBar(ctx, px * offset, py * offset, nx, ny, valR); // 正方向 (右)
                        
                        if (valL > 0.1)
                            drawLinearBar(ctx, -px * offset, -py * offset, nx, ny, valL); // 负方向 (左)

                    } else {
                        // Radial Mode (直线模式下比较少见，但为了逻辑统一)
                        // 使用平均值或者混合? 既然没有左右之分，统一用 L+R 的平均 或 只用R
                        // 这里我们简单处理：混合显示
                        let offset = -innerRadius + (progress * 2 * innerRadius);
                        // Radial模式下单行显示，取一个代表值 (Right channel)
                        if (valR > 0.1)
                            drawLinearBar(ctx, px * offset, py * offset, nx, ny, valR);
                    }
                }
            } 
            // === 极坐标模式 ===
            else {
                for (let i = 0; i < totalBars; i++) {
                    const valL = displayDataL[i];
                    const valR = displayDataR[i];

                    if (symmetryMode === 0) {
                        // --- Mirror Mode ---
                        // 左半圆用 Left 数据，右半圆用 Right 数据
                        const stepAngle = Math.PI / totalBars; 
                        const angleRight = -Math.PI / 2 + (i * stepAngle); // 0 ~ 180 (Right Side)
                        const angleLeft = -Math.PI / 2 - (i * stepAngle);  // 0 ~ -180 (Left Side)
                        
                        if (valR > 0.1) drawPolarBar(ctx, angleRight, valR);
                        if (valL > 0.1) drawPolarBar(ctx, angleLeft, valL);

                    } else {
                        // --- Radial Mode (360°) ---
                        // 单圈模式，此时没有明确的左右之分，通常用混合数据
                        // 但既然我们分离了数据，Radial 模式我们使用 Right Channel 绘制全圈 (或者 Left)
                        // 为了避免混淆，在 Radial 下我们只展示 displayDataR (如果是单声道的 Mix 也是一样的)
                        // 如果立体声打开，Radial模式下看起来可能只会显示右声道数据
                        // 或者：0-180度显示右，180-360度显示左？(这样会有接缝)
                        // 简单起见，Radial 模式使用 displayDataR (如果没开双通道，它是 L+R 平均)
                        
                        const stepAngle = (2 * Math.PI) / totalBars; 
                        const angle = -Math.PI / 2 + (i * stepAngle);
                        
                        if (valR > 0.1) drawPolarBar(ctx, angle, valR);
                    }
                }
            }
            
            ctx.restore();

            // ================= 辅助函数 =================

            function getRadiusAt(angle) {
                const rotRad = thiz.rotationAngle * Math.PI / 180;
                let t = angle - rotRad;
                if (shapeMode === 0) return innerRadius; 
                else if (shapeMode === 1) { 
                    if (polygonSides === 2) return innerRadius;
                    const slice = (2 * Math.PI) / polygonSides;
                    const phase = (t % slice + slice) % slice;
                    const delta = phase - (slice / 2);
                    const apothem = Math.cos(slice / 2);
                    return (innerRadius * apothem) / Math.cos(delta);
                }
                else if (shapeMode === 2) { 
                    let shape = Math.abs(Math.cos(paramN * t));
                    return innerRadius * Math.pow(shape, paramD);
                }
                else if (shapeMode === 3) { 
                    if (_compiledFunc) {
                        try {
                            let factor = _compiledFunc(t);
                            if (isNaN(factor)) factor = 0;
                            return innerRadius * Math.abs(factor);
                        } catch(e) { return innerRadius; }
                    }
                }
                return innerRadius;
            }

            function drawBaseShape(ctx) {
                ctx.beginPath();
                ctx.lineWidth = idleLineWidth;
                ctx.strokeStyle = idleLineColor;

                if (shapeMode === 1 && polygonSides === 2) {
                    const rotRad = thiz.rotationAngle * Math.PI / 180;
                    let vx = -Math.sin(rotRad) * innerRadius;
                    let vy = Math.cos(rotRad) * innerRadius;
                    ctx.moveTo(-vx, -vy);
                    ctx.lineTo(vx, vy);
                } else if (shapeMode === 0) {
                    ctx.arc(0, 0, innerRadius, 0, Math.PI * 2);
                } else {
                    const segments = 120;
                    for (let i = 0; i <= segments; i++) {
                        const theta = -Math.PI / 2 + (i * (2 * Math.PI) / segments);
                        const r = getRadiusAt(theta);
                        const x = Math.cos(theta) * r;
                        const y = Math.sin(theta) * r;
                        if (i === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    }
                }
                ctx.stroke();
            }

            function drawPolarBar(ctx, angle, length) {
                const startR = getRadiusAt(angle);
                const coords = calculateJumpCoords(startR, length);
                ctx.beginPath();
                ctx.moveTo(Math.cos(angle) * coords.start, Math.sin(angle) * coords.start);
                ctx.lineTo(Math.cos(angle) * coords.end, Math.sin(angle) * coords.end);
                ctx.stroke();
            }

            function drawLinearBar(ctx, originX, originY, nx, ny, length) {
                let startScale = 0;
                let endScale = 0;
                if (jumpMode === 0) { startScale = 0; endScale = -length; }
                else if (jumpMode === 1) { startScale = 0; endScale = length; }
                else { startScale = -length / 2; endScale = length / 2; }
                const x1 = originX + nx * startScale;
                const y1 = originY + ny * startScale;
                const x2 = originX + nx * endScale;
                const y2 = originY + ny * endScale;
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
            }

            function calculateJumpCoords(baseRadius, length) {
                let rStart = 0, rEnd = 0;
                if (jumpMode === 0) { 
                    rStart = baseRadius; rEnd = baseRadius + length; 
                    if (rEnd > maxRadius) rEnd = maxRadius;
                } else if (jumpMode === 1) { 
                    rStart = baseRadius; rEnd = Math.max(0, baseRadius - length);
                } else { 
                    rStart = Math.max(0, baseRadius - length/2); 
                    rEnd = Math.min(maxRadius, baseRadius + length/2);
                }
                return { start: rStart, end: rEnd };
            }
        }
    }
}