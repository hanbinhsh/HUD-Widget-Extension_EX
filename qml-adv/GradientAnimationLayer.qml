import QtQuick 2.12
import QtGraphicalEffects 1.12

import "./Utils/ColorAnimation.js" as GradientUtils

// 可复用的"整体颜色渐变"机制层。
//
// 集中原本在 HUDWidget 顶层、HUDWidget itemContent、CraftElement 三处逐份复制的
// 渐变脚手架：常驻/动态 Gradient 对象、stop 缓存、相位动画驱动、初始化逻辑，以及
// LinearGradient / RadialGradient / ConicalGradient 三个绘制项。
//
// 职责边界：本组件**只负责生成"按方向选择的渐变绘制项"**（activeGradient），
// 不负责把它接到宿主上。各宿主仍保留自己的 `layer { effect: OpacityMask {...} }`，
// 只需把其中的 `source` 指向 `<本组件>.activeGradient`——因为三处的遮罩接线
// （samplerName / maskSource 目标）各不相同，保留各自原样以避免渲染行为变化。
//
// 用法：
//   GradientAnimationLayer { id: gradLayer; settings: <settingsMap>; sourceItem: <被着色的根项> }
//   // 宿主 layer：effect: OpacityMask { ...; source: gradLayer.activeGradient }
Item {
    id: gradLayer

    // 渐变相关设置所在的设置表（HUDWidget 顶层=defaultSettings；item=modelData；element=settings）
    property var settings
    // 被渐变作用的根项（用于尺寸与渐变绘制项的 anchors）
    property Item sourceItem

    anchors.fill: sourceItem

    // 按方向选中的渐变绘制项；宿主 OpacityMask.source 绑定它
    readonly property Item activeGradient: {
        switch (settings.overallGradientDirect ?? 1) {
            case 0:
            case 1:
            case 2:
            case 5: return linearG;
            case 3: return radialG;
            case 4: return conicalG;
            default: return linearG;
        }
    }

    // --- 数据与状态 ---
    property var defaultStops: [{ position: 0.0, color: "#a18cd1" },{ position: 0.5, color: "#fbc2eb" }]
    // 保底：fillStops 为空时退回 defaultStops，保证 rebuildGradientStops 总有数据
    property var safeFillStops: (settings.fillStops && settings.fillStops.length > 0)
                                ? settings.fillStops
                                : defaultStops
    property var innerLevelStopCache: []
    property var customGradObject: null
    // 仅当"开启自定义且对象已建好"才用自定义对象，否则回退简易渐变
    property var currentGradient: (settings.useFillGradient && customGradObject)
                                  ? customGradObject
                                  : simpleGrad

    property var animDuration: settings.overallGradientAnimDuration ?? 5000
    property real animPhase: 0.0
    onAnimDurationChanged: phaseAnim.restart()

    NumberAnimation on animPhase {
        id: phaseAnim
        running: (settings.enableOverallGradientEffect ?? false) && (settings.enableOverallGradientAnim ?? false)
        from: 0.0
        to: 1.0
        duration: gradLayer.animDuration
        loops: Animation.Infinite
    }

    onAnimPhaseChanged: {
        if (settings.useFillGradient && settings.enableOverallGradientAnim) {
            GradientUtils.updateGradientPositions(animPhase, innerLevelStopCache);
        }
    }

    Connections {
        target: settings
        onUseFillGradientChanged: initCustomGradient()
        onEnableOverallGradientAnimChanged: initCustomGradient()
        onOverallGradientColor0Changed: initCustomGradient()
        onOverallGradientColor1Changed: initCustomGradient()
    }
    onSafeFillStopsChanged: initCustomGradient()
    Component.onCompleted: initCustomGradient()

    function initCustomGradient() {
        // A. 未开启自定义颜色：清理并退出（currentGradient 自动回退 simpleGrad）
        if (!settings.useFillGradient) {
            if (customGradObject) {
                GradientUtils.clearGradientCache(innerLevelStopCache);
                innerLevelStopCache = [];
                customGradObject.destroy();
                customGradObject = null;
            }
            return;
        }

        // B. 重建自定义渐变对象
        GradientUtils.clearGradientCache(innerLevelStopCache);
        innerLevelStopCache = [];
        if (customGradObject) {
            customGradObject.destroy();
            customGradObject = null;
        }

        var newGradObj = customGradComponent.createObject(gradLayer);
        if (newGradObj) {
            // 强制使用 safeFillStops，保证有数据
            var tempSettings = {
                fillStops: safeFillStops,
                enableOverallGradientEffect: settings.enableOverallGradientEffect,
                enableOverallGradientAnim: settings.enableOverallGradientAnim,
                useFillGradient: true
            };
            var result = GradientUtils.rebuildGradientStops(tempSettings, stopComponent, newGradObj);
            if (result.qmlStops.length > 0) {
                newGradObj.stops = result.qmlStops;
                innerLevelStopCache = result.cache;
                customGradObject = newGradObj;
            } else {
                newGradObj.destroy();
                customGradObject = null;
            }
        }
    }

    // --- 组件定义 ---
    Gradient {
        id: simpleGrad
        GradientStop {
            position: 0.0
            color: GradientUtils.adjustGradientColor(settings.overallGradientColor0 ?? "#a18cd1", gradLayer.animPhase, settings)
        }
        GradientStop {
            position: 1.0
            color: GradientUtils.adjustGradientColor(settings.overallGradientColor1 ?? "#fbc2eb", gradLayer.animPhase, settings)
        }
    }
    Component { id: customGradComponent; Gradient { } }
    Component { id: stopComponent; GradientStop { } }

    // --- 渐变绘制项（visible:false，仅作 OpacityMask 的 source）---
    LinearGradient {
        id: linearG
        anchors.fill: parent
        visible: false
        gradient: gradLayer.currentGradient
        start: {
            switch (settings.overallGradientDirect ?? 1) {
                case 0:
                case 1:
                case 2:
                case 3: return Qt.point(0, 0);
                case 5: return Qt.point(settings.overallGradientStartX ?? 0, settings.overallGradientStartY ?? 0);
                default: return Qt.point(0, 0);
            }
        }
        end: {
            switch (settings.overallGradientDirect ?? 1) {
                case 0: return Qt.point(width, 0);
                case 1: return Qt.point(0, height);
                case 2: return Qt.point(width, height);
                case 5: return Qt.point(settings.overallGradientEndX ?? 100, settings.overallGradientEndY ?? 100);
                default: return Qt.point(width, 0);
            }
        }
        cached: settings.overallGradientCached ?? false
    }
    RadialGradient {
        id: radialG
        anchors.fill: parent
        visible: false
        gradient: gradLayer.currentGradient
        angle: settings.overallGradientAngle ?? 0
        horizontalOffset: settings.overallGradientHorizontal ?? 0
        verticalOffset: settings.overallGradientVertical ?? 0
        horizontalRadius: settings.overallGradientHorizontalRadius ?? 50
        verticalRadius: settings.overallGradientVerticalRadius ?? 50
        cached: settings.overallGradientCached ?? false
    }
    ConicalGradient {
        id: conicalG
        anchors.fill: parent
        visible: false
        gradient: gradLayer.currentGradient
        angle: settings.overallGradientAngle ?? 0
        horizontalOffset: settings.overallGradientHorizontal ?? 0
        verticalOffset: settings.overallGradientVertical ?? 0
        cached: settings.overallGradientCached ?? false
    }
}
