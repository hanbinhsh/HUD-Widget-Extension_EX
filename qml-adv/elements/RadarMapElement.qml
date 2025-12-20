import QtQuick 2.12
import QtQuick.Controls 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    readonly property int padSize: 20
    readonly property int centerX: width / 2
    readonly property int centerY: height / 2
    readonly property int maxRadius: Math.min(width, height) / 2 - padSize

    readonly property color strokeColor: settings.strokeColor ?? "#88FFFFFF"
    readonly property color fillColor: settings.fillColor ?? colorAlpha(strokeColor, 0.3)
    readonly property color gridlineColor: settings.gridlineColor ?? "#44FFFFFF"
    readonly property color axisColor: settings.axisColor ?? "#66FFFFFF"

    readonly property int strokeSize: settings.strokeSize ?? 2
    readonly property bool strokeGlow: settings.strokeGlow ?? true
    readonly property bool fillEnabled: settings.fillEnabled ?? true
    readonly property bool drawGridlines: settings.gridline ?? true
    readonly property bool gridlineGlow: settings.gridlineGlow ?? true
    
    readonly property bool polygonGrid: settings.polygonGrid ?? false 

    readonly property int gridLevels: settings.gridLevels ?? 5
    readonly property bool drawAxis: settings.drawAxis ?? true
    readonly property bool axisGlow: settings.axisGlow ?? true
    readonly property int axisCount: settings.axisCount ?? 6

    // 动画开关
    readonly property bool enableAnimation: settings.enableAnimation ?? false

    // 数据输出
    readonly property var dataOutputs: {
        if (!output.result || typeof output.result !== "string")
            return [];

        return output.result
                .trim()
                .split(/\s+/)
                .map(v => Number(v));
    }

    // 监听数据变化，同步到动画代理器中
    onDataOutputsChanged: syncData()
    // 监听轴数量变化，稍后重绘以确保 Repeater 已重建
    onAxisCountChanged: Qt.callLater(syncData)

    function syncData() {
        for (var i = 0; i < valueAnimator.count; i++) {
            var val = (i < dataOutputs.length) ? dataOutputs[i] : 0;
            // 将目标值赋予代理对象，如果开启了 Behavior，它会自动平滑过渡
            if (valueAnimator.itemAt(i)) {
                valueAnimator.itemAt(i).value = val;
            }
        }
        canvas.requestPaint()
    }

    dataConfiguration: settings.data ?? undefined

    title: qsTranslate("utils", "Radar Chart")
    implicitWidth: 200
    implicitHeight: 200

    onStrokeColorChanged: canvas.requestPaint()
    onStrokeSizeChanged: canvas.requestPaint()
    onStrokeGlowChanged: canvas.requestPaint()
    onFillColorChanged: canvas.requestPaint()
    onFillEnabledChanged: canvas.requestPaint()
    onGridlineColorChanged: canvas.requestPaint()
    onGridlineGlowChanged: canvas.requestPaint()
    onDrawGridlinesChanged: canvas.requestPaint()
    
    onPolygonGridChanged: canvas.requestPaint()

    onGridLevelsChanged: canvas.requestPaint()
    onDrawAxisChanged: canvas.requestPaint()
    onAxisColorChanged: canvas.requestPaint()
    onAxisGlowChanged: canvas.requestPaint()

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SpinPreference {
            id: pAxisCount
            name: "axisCount"
            label: qsTr("Axis Count")
            defaultValue: 6
            from: 3
            to: 12
            stepSize: 1
            display: P.TextFieldPreference.ExpandLabel
        }

        P.Separator {}

        Repeater {
            id: maxRepeater
            model: thiz.axisCount   // 跟随坐标轴数量
            P.SpinPreference {
                name: "maxValue" + index
                label: qsTr("Axis ") + (index + 1) + qsTr(" Max")
                defaultValue: 100
                from: 1
                to: 10000
                stepSize: 1
                editable: true
                display: P.TextFieldPreference.ExpandLabel
            }
        }

        P.Separator {}

        // 数据源配置
        P.DataPreference {
            name: "data"
            label: qsTr("Data")
            environment: thiz.environment
            message: qsTr("You need to select the custom script in the data selector among other data, choose multiple input data, and select asynchronous data in the example below.")
        }

        P.Separator {}

        // 样式设置
        NoDefaultColorPreference {
            name: "strokeColor"
            label: qsTr("Line Color")
            defaultValue: "#88FFFFFF"
        }

        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Line Size")
            defaultValue: 2
            from: 1
            to: 5
            stepSize: 1
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SwitchPreference {
            name: "strokeGlow"
            label: qsTr("Line Glow")
            defaultValue: true
        }

        P.SwitchPreference {
            id: pFillEnabled
            name: "fillEnabled"
            label: qsTr("Fill Area")
            defaultValue: true
        }

        NoDefaultColorPreference {
            name: "fillColor"
            label: qsTr("Fill Color")
            defaultValue: colorAlpha(thiz.strokeColor, 0.3)
            visible: pFillEnabled.value
        }

        P.Separator {}

        P.SwitchPreference {
            id: pGridline
            name: "gridline"
            label: qsTr("Draw Gridlines")
            defaultValue: true
        }

        P.SwitchPreference {
            name: "polygonGrid"
            label: qsTr("Polygon Grid") // 多边形网格
            defaultValue: false
            visible: pGridline.value
        }

        NoDefaultColorPreference {
            name: "gridlineColor"
            label: qsTr("Gridlines Color")
            defaultValue: "#44FFFFFF"
            visible: pGridline.value
        }

        P.SwitchPreference {
            name: "gridlineGlow"
            label: qsTr("Gridlines Glow")
            defaultValue: true
            visible: pGridline.value
        }

        P.SpinPreference {
            name: "gridLevels"
            label: qsTr("Grid Levels")
            defaultValue: 5
            from: 3
            to: 10
            stepSize: 1
            display: P.TextFieldPreference.ExpandLabel
            visible: pGridline.value
        }

        P.Separator {}

        P.SwitchPreference {
            id: pDrawAxis
            name: "drawAxis"
            label: qsTr("Draw Axis")
            defaultValue: true
        }

        NoDefaultColorPreference {
            name: "axisColor"
            label: qsTr("Axis Color")
            defaultValue: "#66FFFFFF"
            visible: pDrawAxis.value
        }

        P.SwitchPreference {
            name: "axisGlow"
            label: qsTr("Axis Glow")
            defaultValue: true
            visible: pDrawAxis.value
        }

        P.Separator {}

        P.SwitchPreference {
            name: "enableAnimation"
            label: qsTr("Enable Animation")
            defaultValue: false
        }
    }

    function colorAlpha(c, a) { 
        return Qt.rgba(c.r, c.g, c.b, a); 
    }

    // 数值动画代理
    Repeater {
        id: valueAnimator
        model: thiz.axisCount
        
        Item {
            property real value: 0
            Behavior on value {
                enabled: thiz.enableAnimation
                NumberAnimation { 
                    duration: 400 
                    easing.type: Easing.OutCubic 
                }
            }
            onValueChanged: canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            ctx.save();
            ctx.translate(centerX, centerY);

            // 预先计算角度步长
            const angleStep = (2 * Math.PI) / axisCount;

            // Draw grid (Circles or Polygons)
            if (drawGridlines) {
                const gridColor = colorAlpha(gridlineColor, 0.5);
                const glowColor = gridlineGlow ? colorAlpha(gridlineColor, 0.5) : Qt.rgba(0, 0, 0, 0);
                
                ctx.strokeStyle = gridColor;
                ctx.shadowColor = glowColor;
                ctx.shadowBlur = gridlineGlow ? 4 : 0;
                ctx.lineWidth = 1;

                for (let i = 1; i <= gridLevels; i++) {
                    const radius = (maxRadius / gridLevels) * i;
                    ctx.beginPath();
                    
                    if (thiz.polygonGrid) {
                        // 绘制多边形
                        for (let j = 0; j <= axisCount; j++) {
                            const angle = angleStep * j - Math.PI / 2;
                            const x = Math.cos(angle) * radius;
                            const y = Math.sin(angle) * radius;
                            if (j === 0) {
                                ctx.moveTo(x, y);
                            } else {
                                ctx.lineTo(x, y);
                            }
                        }
                    } else {
                        // 绘制圆形（原逻辑）
                        ctx.arc(0, 0, radius, 0, 2 * Math.PI);
                    }
                    
                    ctx.stroke();
                }
            }

            // Draw axis lines
            if (drawAxis) {
                const glowColor = axisGlow ? colorAlpha(axisColor, 1) : Qt.rgba(0, 0, 0, 0);
                
                ctx.strokeStyle = axisColor;
                ctx.shadowColor = glowColor;
                ctx.shadowBlur = axisGlow ? 4 : 0;
                ctx.lineWidth = 1;

                for (let i = 0; i < axisCount; i++) {
                    const angle = angleStep * i - Math.PI / 2;
                    const x = Math.cos(angle) * maxRadius;
                    const y = Math.sin(angle) * maxRadius;
                    
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(x, y);
                    ctx.stroke();
                }
            }

            // Calculate data points
            const points = [];
            // const angleStep = (2 * Math.PI) / axisCount; // 已上提
            
            for (let i = 0; i < axisCount; i++) {
                const item = valueAnimator.itemAt(i);
                const value = item ? item.value : 0;

                const maxValName = "maxValue" + i;
                const maxVal = thiz.settings[maxValName] ?? 100;

                const normalizedValue = maxVal > 0 ? Math.min(1, value / maxVal) : 0;

                const angle = angleStep * i - Math.PI / 2;
                const radius = normalizedValue * maxRadius;
                const x = Math.cos(angle) * radius;
                const y = Math.sin(angle) * radius;
                points.push({ x: x, y: y });
            }

            // Draw fill
            if (fillEnabled && points.length > 0) {
                ctx.shadowBlur = 0;
                ctx.fillStyle = fillColor;
                ctx.beginPath();
                ctx.moveTo(points[0].x, points[0].y);
                for (let i = 1; i < points.length; i++) {
                    ctx.lineTo(points[i].x, points[i].y);
                }
                ctx.closePath();
                ctx.fill();
            }
            // Draw stroke
            if (points.length > 0) {
                const glowColor = strokeGlow ? colorAlpha(strokeColor, 1) : Qt.rgba(0, 0, 0, 0);
                ctx.strokeStyle = strokeColor;
                ctx.shadowColor = glowColor;
                ctx.shadowBlur = strokeGlow ? 4 : 0;
                ctx.lineWidth = strokeSize;
                ctx.beginPath();
                ctx.moveTo(points[0].x, points[0].y);
                for (let i = 1; i < points.length; i++) {
                    ctx.lineTo(points[i].x, points[i].y);
                }
                ctx.closePath();
                ctx.stroke();
                // Draw points
                ctx.shadowBlur = strokeGlow ? 2 : 0;
                ctx.fillStyle = strokeColor;
                for (let i = 0; i < points.length; i++) {
                    ctx.beginPath();
                    ctx.arc(points[i].x, points[i].y, strokeSize + 1, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }
            ctx.restore();
        }
    }

    NVG.DataSourceTextOutput {
        id: output
        source: thiz.dataSource ?? null
    }
}