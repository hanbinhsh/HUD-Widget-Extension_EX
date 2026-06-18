import QtQuick 2.12

import "./Utils/ColorAnimation.js" as GradientUtils

// 可复用的"颜色循环渐变"驱动器。
//
// 从 ImageElementAdvanced 抽出的 cycleColor 渐变机制：常驻 Gradient 对象 + stop 缓存 +
// 标准循环(模式0~2,含彩虹/自定义)与高级自定义(模式3,fillStops)两套相位/步进动画 + 初始化逻辑。
// 对外只暴露 `gradient`（一个随设置/动画实时更新的 Gradient），供 ImageEffectStack 等使用。
//
// 用法：
//   ColorCycleGradient { id: ccg; settings: <设置表>; viewExposed: <item>.NVG.View.exposed }
//   ImageEffectStack { ...; gradient: ccg.gradient }
Item {
    id: ccg

    // 渐变相关设置所在的设置表
    property var settings
    // 视图是否可见，作为动画运行门控
    property bool viewExposed: true

    // 对外暴露的常驻 Gradient
    readonly property alias gradient: dynamicGradient

    width: 0; height: 0
    visible: false

    readonly property bool enableColorGradient: settings.colorGradient ?? false
    readonly property bool enableColorGradientAnimation: Boolean(settings.enableColorAnimation && (settings.colorGradient ?? false))
    property int idxx: 1
    // 公用变量
    property real cycleStart: settings.cycleColor == 1 ? (settings.cycleColorCustomStart ?? 0) / 16 : 0
    property real cycleEnd: settings.cycleColor == 1 ? (settings.cycleColorCustomEnd ?? 160) / 10 : 16
    property real cycleSaturation: (settings.cycleSaturation ?? 100) / 100
    property real cycleValue: (settings.cycleValue ?? 100) / 100
    property real cycleOpacity: (settings.cycleOpacity ?? 100) / 100
    property int  cycleTime: settings.cycleTime ?? 500
    property int  pauseColorAnimationTime: settings.pauseColorAnimationTime ?? 0
    property int  cycleColorFrom: settings.cycleColorFrom ?? 0
    property int  cycleColorTo: settings.cycleColorTo ?? 15

    onCycleTimeChanged:                 { if(colorAnimPhaseAnimation.running) colorAnimPhaseAnimation.restart(); if(idxxAnimation.running) idxxAnimation.restart(); }
    onPauseColorAnimationTimeChanged:   { if(colorAnimPhaseAnimation.running) colorAnimPhaseAnimation.restart(); if(idxxAnimation.running) idxxAnimation.restart(); }
    onCycleColorFromChanged:            { if(colorAnimPhaseAnimation.running) colorAnimPhaseAnimation.restart(); if(idxxAnimation.running) idxxAnimation.restart(); }
    onCycleColorToChanged:              { if(colorAnimPhaseAnimation.running) colorAnimPhaseAnimation.restart(); if(idxxAnimation.running) idxxAnimation.restart(); }
    onCycleStartChanged:                { if(colorAnimPhaseAnimation.running) colorAnimPhaseAnimation.restart(); if(idxxAnimation.running) idxxAnimation.restart(); }
    onCycleEndChanged:                  { if(colorAnimPhaseAnimation.running) colorAnimPhaseAnimation.restart(); if(idxxAnimation.running) idxxAnimation.restart(); }

    // 计算颜色的函数
    function colorInit(index){
        var hueIndex = (15 - (((idxx + index) > 15) ? idxx - 15 + index : idxx + index));
        var hue = (hueIndex * cycleEnd / 255) + (cycleStart / 255);
        return Qt.hsva(hue, cycleSaturation, cycleValue, cycleOpacity);
    }
    property var cycleCustomColor2: [settings.cycleColor0 ?? colorInit(0),  settings.cycleColor1  ?? colorInit(1),  settings.cycleColor2  ?? colorInit(2),
                                    settings.cycleColor3  ?? colorInit(3),  settings.cycleColor4  ?? colorInit(4),  settings.cycleColor5  ?? colorInit(5),
                                    settings.cycleColor6  ?? colorInit(6),  settings.cycleColor7  ?? colorInit(7),  settings.cycleColor8  ?? colorInit(8),
                                    settings.cycleColor9  ?? colorInit(9),  settings.cycleColor10 ?? colorInit(10), settings.cycleColor11 ?? colorInit(11),
                                    settings.cycleColor12 ?? colorInit(12), settings.cycleColor13 ?? colorInit(13), settings.cycleColor14 ?? colorInit(14),
                                    settings.cycleColor15 ?? colorInit(15)]
    function getColor(index) {
        if(settings.cycleColor!=2){
            return colorInit(index)
        }else{
            return cycleCustomColor2[(idxx+index)%16]
        }
    }

    // 1. 本地缓存 (持有 Stop 对象)
    property var stopCache: []

    // 2. 常驻 Gradient 对象
    Gradient {
        id: dynamicGradient
    }

    // 3. 基础组件 (用于 JS 创建对象)
    Component {
        id: stopComponent
        GradientStop {}
    }

    property var defaultFillStops: [{ position: 0.0, color: "#a18cd1" },{ position: 0.5, color: "#fbc2eb" }]
    property var fillStops: settings.fillStops ?? defaultFillStops

    Connections {
        target: settings
        onCycleColorChanged: initGradientSystem()
        onFillStopsChanged: initGradientSystem()
        onEnableColorAnimationChanged: initGradientSystem()
    }

    Component.onCompleted: initGradientSystem()

    function initGradientSystem() {
        // 清理旧对象
        GradientUtils.clearCache(stopCache);
        stopCache = [];

        // 模式 3: 自定义高级颜色
        if (settings.cycleColor === 3) {
            // 调用 JS 生成 3 倍数量的 Stops (k=-1,0,1)
            stopCache = GradientUtils.rebuildStops(dynamicGradient, stopComponent, fillStops, 3);

            // 立即更新一次位置
            GradientUtils.updatePositions(colorAnimPhase, stopCache);
        }
        // 模式 0, 1, 2: 标准循环
        else {
            // 调用 JS 生成 16 个固定位置的 Stops
            stopCache = GradientUtils.rebuildStops(dynamicGradient, stopComponent, null, 0);

            // 立即更新一次颜色
            updateStandardColors();
        }

        // 重新绑定 Gradient (触发视图刷新)
        dynamicGradient.stops = stopCache.map(function(item){ return item.qmlObject; });
    }

    // === 模式 3 驱动 (Phase 0.0 ~ 1.0) ===
    property real colorAnimPhase: 0.0
    SequentialAnimation {
        id: colorAnimPhaseAnimation
        running: (settings.cycleColor === 3) && (fillStops.length > 0) && enableColorGradientAnimation && ccg.viewExposed
        loops: Animation.Infinite
        PauseAnimation { duration: pauseColorAnimationTime ?? 0 }
        NumberAnimation {
            target: ccg
            property: "colorAnimPhase"
            duration: cycleTime ?? 500
            from: 0.0
            to: 1.0
        }
    }
    // 监听相位 -> 更新位置 (零内存分配)
    onColorAnimPhaseChanged: {
        if (settings.cycleColor === 3) {
            GradientUtils.updatePositions(colorAnimPhase, stopCache);
        }
    }

    // === 模式 0-2 驱动 (IDXX 整数步进) ===
    SequentialAnimation {
        id: idxxAnimation
        running: enableColorGradientAnimation && (settings.cycleColor !== 3) && ccg.viewExposed
        loops: Animation.Infinite
        PauseAnimation { duration: pauseColorAnimationTime ?? 0 }
        NumberAnimation {
            target: ccg
            property: "idxx"
            duration: cycleTime ?? 500
            from: settings.cycleColor === 3 ? 0 : cycleColorFrom ?? 0
            to: settings.cycleColor === 3 ? 1 : cycleColorTo ?? 15
        }
    }
    // 监听 IDXX -> 更新颜色 (零内存分配)
    onIdxxChanged: {
        if (settings.cycleColor !== 3) {
            updateStandardColors();
        }
    }

    // 辅助: 更新标准模式的 16 个颜色
    function updateStandardColors() {
        if (!stopCache || stopCache.length !== 16) return;
        for (var i = 0; i < 16; i++) {
            var item = stopCache[i];
            if (item.qmlObject) {
                // 原逻辑是倒序映射: stop[0] 对应 getColor(15)
                item.qmlObject.color = getColor(15 - i);
            }
        }
    }
}
