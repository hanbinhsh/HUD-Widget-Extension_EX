import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    // --- 尺寸与布局 ---
    readonly property int padLeft: 10
    readonly property int padRight: 10
    readonly property int padTop: 10
    readonly property int padBottom: 20 // 留出底部空间
    
    readonly property int chartWidth: width - padLeft - padRight
    readonly property int chartHeight: height - padTop - padBottom

    // --- 外观配置 ---
    readonly property int barSpacing: settings.barSpacing ?? 5       // 柱子间距
    readonly property int cornerRadius: settings.cornerRadius ?? 0   // 圆角
    
    // 轴与网格
    readonly property bool drawGrid: settings.drawGrid ?? true
    readonly property color gridColor: settings.gridColor ?? "#40FFFFFF"
    readonly property int gridLines: settings.gridLevels ?? 4

    // 柱子样式
    readonly property color strokeColor: settings.strokeColor ?? "#FFFFFF"
    readonly property int strokeSize: settings.strokeSize ?? 0
    readonly property bool strokeGlow: settings.strokeGlow ?? false
    
    // 数据范围
    readonly property bool autoScale: settings.autoScale ?? true
    readonly property real manualMax: settings.maxValue ?? 100

    // 默认调色板
    property var defaultColors: ["#00AAFF", "#FF5555", "#55FF55", "#FFFF55", "#FF55FF", "#55FFFF"]
    
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
    
    // 数据长度
    readonly property int dataCount: Math.max(1, dataOutputs.length)

    // 监听数据变化
    onDataOutputsChanged: syncData()

    function syncData() {
        for (var i = 0; i < valueAnimator.count; i++) {
            var val = (i < dataOutputs.length) ? dataOutputs[i] : 0;
            if (valueAnimator.itemAt(i)) {
                valueAnimator.itemAt(i).value = Math.max(0, val);
            }
        }
        requestRepaint();
    }

    function requestRepaint() {
        gridCanvas.requestPaint();
        fillCanvas.requestPaint();
        strokeCanvas.requestPaint();
    }

    // 监听外观变化
    onBarSpacingChanged: requestRepaint()
    onCornerRadiusChanged: requestRepaint()
    onDrawGridChanged: requestRepaint()
    onGridColorChanged: requestRepaint()
    onAutoScaleChanged: requestRepaint()
    onManualMaxChanged: requestRepaint()
    onStrokeColorChanged: requestRepaint()
    onStrokeSizeChanged: requestRepaint()

    title: qsTranslate("utils", "Bar Chart")
    implicitWidth: 200
    implicitHeight: 150
    
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

        // 范围设置
        P.SwitchPreference {
            id: pAutoScale
            name: "autoScale"
            label: qsTr("Auto Scale Max Value")
            defaultValue: true
        }

        P.SpinPreference {
            name: "maxValue"
            label: qsTr("Manual Max Value")
            defaultValue: 100
            from: 1
            to: 100000
            editable: true
            display: P.TextFieldPreference.ExpandLabel
            visible: !pAutoScale.value
        }

        P.Separator {}

        // 布局设置
        P.SpinPreference {
            name: "barSpacing"
            label: qsTr("Bar Spacing (px)")
            defaultValue: 5
            from: 0
            to: 50
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SliderPreference {
            name: "cornerRadius"
            label: qsTr("Corner Radius")
            defaultValue: 0
            from: 0
            to: 20
            stepSize: 1
            live: true
        }

        P.Separator {}

        // 网格设置
        P.SwitchPreference {
            id: pDrawGrid
            name: "drawGrid"
            label: qsTr("Draw Background Grid")
            defaultValue: true
        }

        P.SpinPreference {
            name: "gridLevels"
            label: qsTr("Grid Lines")
            defaultValue: 4
            from: 1
            to: 20
            visible: pDrawGrid.value
            display: P.TextFieldPreference.ExpandLabel
        }

        NoDefaultColorPreference {
            name: "gridColor"
            label: qsTr("Grid Color")
            defaultValue: "#40FFFFFF"
            visible: pDrawGrid.value
        }

        P.Separator {}

        // 边框设置
        NoDefaultColorPreference {
            name: "strokeColor"
            label: qsTr("Border Color")
            defaultValue: "#FFFFFF"
        }

        P.SpinPreference {
            name: "strokeSize"
            label: qsTr("Border Width")
            defaultValue: 0
            from: 0
            to: 10
            display: P.TextFieldPreference.ExpandLabel
        }

        P.SwitchPreference {
            name: "strokeGlow"
            label: qsTr("Border Glow")
            defaultValue: false
            visible: strokeSize > 0
        }

        P.Separator {}

        // 动态颜色设置 (没有使用 LabelPreference)
        Repeater {
            model: thiz.dataCount
            NoDefaultColorPreference {
                name: "barColor" + index
                label: qsTr("Bar ") + (index + 1) + qsTr(" Color")
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
    Repeater {
        id: valueAnimator
        model: 32 // 预留足够的槽位
        
        Item {
            property real value: 0
            Behavior on value {
                enabled: thiz.enableAnimation
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutCubic 
                }
            }
            onValueChanged: {
                if (index < thiz.dataCount) {
                    fillCanvas.requestPaint()
                    strokeCanvas.requestPaint()
                }
            }
        }
    }

    // --- 辅助计算函数 ---
    function getMaxValue() {
        if (!autoScale) return manualMax;
        
        var max = 0;
        // 遍历当前动画值，保证缩放平滑
        for (var i = 0; i < thiz.dataCount; i++) {
            var v = valueAnimator.itemAt(i).value;
            if (v > max) max = v;
        }
        // 如果数据很小，给一个默认高度防止除以0
        return max > 0 ? max : 100; 
    }

    // --- 绘图层 ---

    Item {
        anchors.fill: parent
        // 留出边距
        anchors.leftMargin: padLeft
        anchors.rightMargin: padRight
        anchors.topMargin: padTop
        anchors.bottomMargin: padBottom

        // 1. 网格层 (底层)
        Canvas {
            id: gridCanvas
            anchors.fill: parent
            visible: drawGrid
            renderStrategy: Canvas.Cooperative
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                ctx.strokeStyle = gridColor;
                ctx.lineWidth = 1;
                
                // 画横线
                var step = height / gridLines;
                for (var i = 0; i <= gridLines; i++) {
                    var y = Math.floor(i * step);
                    // 修正最后一条线，防止被切掉
                    if (y >= height) y -= 1; 
                    
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                    ctx.stroke();
                }
            }
        }

        // 2. 填充层 (中间层)
        Canvas {
            id: fillCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var maxVal = getMaxValue();
                var count = thiz.dataCount;
                // 计算每个柱子的宽度：(总宽 - (数量-1)*间距) / 数量
                var barW = (width - (count - 1) * barSpacing) / count;
                // 防止间距太大导致宽度为负
                if (barW < 1) barW = 1;

                for (var i = 0; i < count; i++) {
                    var val = valueAnimator.itemAt(i).value;
                    // 计算高度比例
                    var barH = (val / maxVal) * height;
                    
                    var x = i * (barW + barSpacing);
                    var y = height - barH; // Canvas 0点在左上，所以y向下

                    var colorKey = "barColor" + i;
                    var c = thiz.settings[colorKey] ?? thiz.defaultColors[i % thiz.defaultColors.length];

                    ctx.fillStyle = c;
                    
                    ctx.beginPath();
                    // 绘制圆角矩形
                    if (cornerRadius > 0) {
                        // 只上方圆角？还是全圆角？通常条形图上方圆角
                        // 这里简单实现上方圆角
                        ctx.moveTo(x, y + height); // 左下
                        ctx.lineTo(x, y + cornerRadius); 
                        ctx.quadraticCurveTo(x, y, x + cornerRadius, y); // 左上角
                        ctx.lineTo(x + barW - cornerRadius, y);
                        ctx.quadraticCurveTo(x + barW, y, x + barW, y + cornerRadius); // 右上角
                        ctx.lineTo(x + barW, y + height); // 右下
                        ctx.closePath();
                    } else {
                        ctx.rect(x, y, barW, barH);
                    }
                    ctx.fill();
                }
            }
        }

        // 3. 描边与发光层 (顶层)
        Item {
            anchors.fill: parent
            visible: strokeSize > 0
            
            // GPU 发光
            layer.enabled: strokeGlow
            layer.effect: Glow {
                samples: 15
                radius: 8
                spread: 0.3
                color: strokeColor
                transparentBorder: true
                cached: false
            }

            Canvas {
                id: strokeCanvas
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                renderTarget: Canvas.FramebufferObject

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    if (strokeSize <= 0) return;

                    var maxVal = getMaxValue();
                    var count = thiz.dataCount;
                    var barW = (width - (count - 1) * barSpacing) / count;
                    if (barW < 1) barW = 1;

                    ctx.strokeStyle = strokeColor;
                    ctx.lineWidth = strokeSize;

                    for (var i = 0; i < count; i++) {
                        var val = valueAnimator.itemAt(i).value;
                        // 为了避免边框在 0 高度时显示一条线，做个判断
                        if (val <= 0.5) continue;

                        var barH = (val / maxVal) * height;
                        var x = i * (barW + barSpacing);
                        var y = height - barH;

                        ctx.beginPath();
                        if (cornerRadius > 0) {
                            ctx.moveTo(x, y + height); 
                            ctx.lineTo(x, y + cornerRadius); 
                            ctx.quadraticCurveTo(x, y, x + cornerRadius, y); 
                            ctx.lineTo(x + barW - cornerRadius, y);
                            ctx.quadraticCurveTo(x + barW, y, x + barW, y + cornerRadius); 
                            ctx.lineTo(x + barW, y + height); 
                        } else {
                            // 描边矩形，注意描边是居中的，可能需要 inset 一半 strokeSize
                            // 这里简化处理
                            ctx.rect(x, y, barW, barH);
                        }
                        // 这里我们不 closePath，因为底部通常不需要描边（看起来像从底部长出来的）
                        // 如果需要全包围，可以使用 stroke()，如果只想描上面和侧面，需要手动画线
                        // 这里演示画“门”字形描边（左、上、右）
                        ctx.stroke();
                    }
                }
            }
        }
    }

    NVG.DataSourceTextOutput {
        id: output
        source: thiz.dataSource ?? null
    }
}