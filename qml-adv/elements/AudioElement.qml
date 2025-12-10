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

    // --- 立体声开关 ---
    readonly property bool stereoMode: settings.stereoMode ?? false

    // --- 形状模式 ---
    // 0=Circle, 1=Polygon, 2=Rose/Parametric, 3=Custom Formula
    readonly property int shapeMode: settings.shapeMode ?? 0

    // --- 对称模式 ---
    // 0=Mirror(左右镜像), 1=Radial(中心环绕)
    readonly property int symmetryMode: settings.symmetryMode ?? 0

    // --- 绘图模式 ---
    // 0=Bars, 1=Lines, 2=Both
    readonly property int drawMode: settings.drawMode ?? 0
    // --- 平滑曲线开关 ---
    readonly property bool smoothLine: settings.smoothLine ?? true

    // 参数
    readonly property int polygonSides: settings.polygonSides ?? 6
    readonly property real paramN: settings.paramN ?? 2.0 
    readonly property real paramD: settings.paramD ?? 1.0 
    property string customFormula: settings.customFormula ?? "Math.abs(Math.cos(3*t))"
    property var _compiledFunc: null 
    readonly property real rotationAngle: settings.rotationAngle ?? 0
    // [关键] 跳动模式: 0=Outer, 1=Inner, 2=Both
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

    property var displayDataL: new Array(barCount).fill(0)
    property var displayDataR: new Array(barCount).fill(0)

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
        
        P.SwitchPreference {
            name: "stereoMode"
            label: qsTr("Dual Channel (Stereo)")
            defaultValue: false
        }

        P.Separator {}

        P.SelectPreference {
            name: "drawMode"
            label: qsTr("Draw Style")
            defaultValue: 0
            model: [ qsTr("Bars"), qsTr("Lines"), qsTr("Bars + Lines") ]
        }

        P.SwitchPreference {
            name: "smoothLine"
            label: qsTr("Smooth Curve")
            defaultValue: true
            visible: drawMode !== 0
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
            stepSize: 0.5
            visible: shapeMode === 2
            live: true
            displayValue: (value*2).toFixed(1)
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
            label: qsTr("Decay") 
            defaultValue: 0.05
            from: 0.01
            to: 0.5
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
    onStereoModeChanged: canvas.requestPaint()
    onDrawModeChanged: canvas.requestPaint()
    onSmoothLineChanged: canvas.requestPaint()

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

    function updateSpectrum(audioData) {
        if (!audioData) return;
        
        let arrL = thiz.displayDataL;
        let arrR = thiz.displayDataR;

        if (arrL.length !== thiz.barCount) {
            arrL = new Array(thiz.barCount).fill(0);
            arrR = new Array(thiz.barCount).fill(0);
            thiz.displayDataL = arrL;
            thiz.displayDataR = arrR;
        }

        let needsRepaint = false;
        let multiplier = 0.01 * sensitivity; 
        
        const validDataLimit = 64; 

        for (let i = 0; i < thiz.barCount; i++) {
            let srcIndex = Math.floor(i * (validDataLimit / thiz.barCount));
            if (srcIndex >= validDataLimit) srcIndex = validDataLimit - 1;

            let inputL = (audioData[srcIndex] || 0) * multiplier;
            let inputR = (audioData[srcIndex + 64] || 0) * multiplier;

            if (!stereoMode) {
                let avg = (inputL + inputR) / 2;
                inputL = avg;
                inputR = avg;
            }

            let oldL = arrL[i];
            let newL = (inputL > oldL) ? inputL : Math.max(0, oldL - (oldL * decay) - 0.5);
            if (Math.abs(newL - oldL) > 0.01) { arrL[i] = newL; needsRepaint = true; }

            let oldR = arrR[i];
            let newR = (inputR > oldR) ? inputR : Math.max(0, oldR - (oldR * decay) - 0.5);
            if (Math.abs(newR - oldR) > 0.01) { arrR[i] = newR; needsRepaint = true; }
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

            if (showIdleLine) {
                drawBaseShape(ctx);
            }

            var gradient = ctx.createRadialGradient(0, 0, innerRadius * 0.5, 0, 0, maxRadius);
            gradient.addColorStop(0, barColorStart);
            gradient.addColorStop(1, barColorEnd);

            ctx.fillStyle = gradient;
            ctx.strokeStyle = gradient;
            ctx.lineCap = roundCap ? "round" : "butt";
            ctx.lineWidth = barWidth;

            const totalBars = barCount; 
            const rotRad = thiz.rotationAngle * Math.PI / 180;
            
            // --- [修改] 存储 Start 和 End 两组坐标 ---
            var points1_start = []; 
            var points1_end = [];
            var points2_start = [];
            var points2_end = [];

            // === 模式A: 直线模式 ===
            if (shapeMode === 1 && polygonSides === 2) {
                let nx = Math.cos(rotRad);
                let ny = Math.sin(rotRad);
                let px = -Math.sin(rotRad);
                let py = Math.cos(rotRad);

                for (let i = 0; i < totalBars; i++) {
                    const valL = displayDataL[i];
                    const valR = displayDataR[i];
                    let progress = i / totalBars; 
                    
                    if (symmetryMode === 0) { // Mirror
                        let offset = progress * innerRadius; 
                        
                        let ptR = calcLinearTip(px * offset, py * offset, nx, ny, valR);
                        points1_start.push(ptR.start);
                        points1_end.push(ptR.end);
                        if (drawMode !== 1 && valR > 0.1) drawLinearBar(ctx, ptR.start, ptR.end);

                        let ptL = calcLinearTip(-px * offset, -py * offset, nx, ny, valL);
                        points2_start.push(ptL.start);
                        points2_end.push(ptL.end);
                        if (drawMode !== 1 && valL > 0.1) drawLinearBar(ctx, ptL.start, ptL.end);

                    } else { // Radial
                        let offset = -innerRadius + (progress * 2 * innerRadius);
                        let pt = calcLinearTip(px * offset, py * offset, nx, ny, valR);
                        points1_start.push(pt.start);
                        points1_end.push(pt.end);
                        if (drawMode !== 1 && valR > 0.1) drawLinearBar(ctx, pt.start, pt.end);
                    }
                }
            } 
            // === 模式B: 极坐标模式 ===
            else {
                for (let i = 0; i < totalBars; i++) {
                    const valL = displayDataL[i];
                    const valR = displayDataR[i];

                    if (symmetryMode === 0) { // Mirror Mode
                        const stepAngle = Math.PI / totalBars; 
                        const angleRight = -Math.PI / 2 + (i * stepAngle); 
                        const angleLeft = -Math.PI / 2 - (i * stepAngle);
                        
                        let ptR = calcPolarTip(angleRight, valR);
                        points1_start.push(ptR.start);
                        points1_end.push(ptR.end);
                        if (drawMode !== 1 && valR > 0.1) drawBarByPoints(ctx, ptR.start, ptR.end);

                        let ptL = calcPolarTip(angleLeft, valL);
                        points2_start.push(ptL.start);
                        points2_end.push(ptL.end);
                        if (drawMode !== 1 && valL > 0.1) drawBarByPoints(ctx, ptL.start, ptL.end);

                    } else { // Radial Mode
                        const stepAngle = (2 * Math.PI) / totalBars; 
                        const angle = -Math.PI / 2 + (i * stepAngle);
                        
                        let pt = calcPolarTip(angle, valR);
                        points1_start.push(pt.start);
                        points1_end.push(pt.end);
                        if (drawMode !== 1 && valR > 0.1) drawBarByPoints(ctx, pt.start, pt.end);
                    }
                }
            }
            
            // --- [修改] 绘制折线 ---
            if (drawMode !== 0) {
                let isClosed = (symmetryMode === 1 && !(shapeMode === 1 && polygonSides === 2));
                
                // 1. 始终绘制 End 线 (Outer Tip / Normal Tip)
                drawPolyline(ctx, points1_end, isClosed);
                if (points2_end.length > 0) drawPolyline(ctx, points2_end, isClosed);

                // 2. 如果是 Both 模式，还要绘制 Start 线 (Inner Tip)
                if (jumpMode === 2) {
                    drawPolyline(ctx, points1_start, isClosed);
                    if (points2_start.length > 0) drawPolyline(ctx, points2_start, isClosed);
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

            function calcPolarTip(angle, length) {
                const startR = getRadiusAt(angle);
                const coords = calculateJumpCoords(startR, length);
                return {
                    start: { x: Math.cos(angle) * coords.start, y: Math.sin(angle) * coords.start },
                    end:   { x: Math.cos(angle) * coords.end,   y: Math.sin(angle) * coords.end }
                };
            }

            function calcLinearTip(originX, originY, nx, ny, length) {
                let startScale = 0;
                let endScale = 0;
                if (jumpMode === 0) { startScale = 0; endScale = -length; }
                else if (jumpMode === 1) { startScale = 0; endScale = length; }
                else { startScale = -length / 2; endScale = length / 2; }
                
                return {
                    start: { x: originX + nx * startScale, y: originY + ny * startScale },
                    end:   { x: originX + nx * endScale,   y: originY + ny * endScale }
                };
            }

            function calculateJumpCoords(baseRadius, length) {
                let rStart = 0, rEnd = 0;
                if (jumpMode === 0) { // Outer
                    rStart = baseRadius; 
                    rEnd = baseRadius + length; 
                    if (rEnd > maxRadius) rEnd = maxRadius;
                } else if (jumpMode === 1) { // Inner
                    rStart = baseRadius; 
                    rEnd = Math.max(0, baseRadius - length);
                } else { // Both
                    rStart = Math.max(0, baseRadius - length/2); 
                    rEnd = Math.min(maxRadius, baseRadius + length/2);
                }
                return { start: rStart, end: rEnd };
            }

            function drawBarByPoints(ctx, p1, p2) {
                ctx.beginPath();
                ctx.moveTo(p1.x, p1.y);
                ctx.lineTo(p2.x, p2.y);
                ctx.stroke();
            }

            function drawPolyline(ctx, points, closed) {
                if (points.length < 2) return;
                ctx.beginPath();
                if (!smoothLine) {
                    ctx.moveTo(points[0].x, points[0].y);
                    for (let i = 1; i < points.length; i++) {
                        ctx.lineTo(points[i].x, points[i].y);
                    }
                    if (closed) ctx.closePath();
                } else {
                    if (closed) {
                        let last = points[points.length - 1];
                        let first = points[0];
                        let midX = (last.x + first.x) / 2;
                        let midY = (last.y + first.y) / 2;
                        ctx.moveTo(midX, midY);
                        for (let i = 0; i < points.length; i++) {
                            let curr = points[i];
                            let next = points[(i + 1) % points.length];
                            let nextMidX = (curr.x + next.x) / 2;
                            let nextMidY = (curr.y + next.y) / 2;
                            ctx.quadraticCurveTo(curr.x, curr.y, nextMidX, nextMidY);
                        }
                    } else {
                        ctx.moveTo(points[0].x, points[0].y);
                        for (let i = 0; i < points.length - 1; i++) {
                            let curr = points[i];
                            let next = points[i+1];
                            let midX = (curr.x + next.x) / 2;
                            let midY = (curr.y + next.y) / 2;
                            if (i === 0) ctx.lineTo(midX, midY); 
                            else ctx.quadraticCurveTo(curr.x, curr.y, midX, midY);
                        }
                        let last = points[points.length - 1];
                        let prev = points[points.length - 2];
                        ctx.quadraticCurveTo(prev.x, prev.y, last.x, last.y);
                    }
                }
                ctx.stroke();
            }
        }
    }
}