// Utils/ColorAnimation.js

/**
 * [初始化] 重建渐变点对象
 * 仅在设置改变时调用，不要在动画循环中调用
 * @param {object} settings - 设置对象
 * @param {Component} gradientStopComponent - QML组件
 * @param {Item} parent - 父对象 (Gradient)
 * @returns {object} { qmlStops: [], cache: [] }
 */
function rebuildGradientStops(settings, gradientStopComponent, parent) {
    // 1. 基础检查
    var stopsData = settings.fillStops;
    if (!stopsData || stopsData.length === 0) return { qmlStops: [], cache: [] };

    // 2. 数据清洗与排序
    var baseStops = [];
    for (var i = 0; i < stopsData.length; i++) {
        var item = stopsData[i];
        if (item) {
            baseStops.push({
                pos: Number(item.position),
                // 确保转为字符串，防止由对象引起的绑定错误
                color: (item.color ? item.color.toString() : "#FF0000")
            });
        }
    }
    baseStops.sort(function(a, b) { return a.pos - b.pos; });

    // 3. 生成 3 倍数量的 Stop 对象 (k = -1, 0, 1) 用于无缝循环
    var qmlStops = [];
    var localCache = [];
    
    for (var k = -1; k <= 1; k++) {
        for (var j = 0; j < baseStops.length; j++) {
            var original = baseStops[j];
            var basePosition = original.pos + k;

            // 创建 QML 对象
            var stopObj = gradientStopComponent.createObject(parent, {
                "color": original.color,
                "position": basePosition
            });

            if (stopObj) {
                // 存入缓存：记录对象引用和它的初始位置
                localCache.push({
                    qmlObject: stopObj,
                    basePos: basePosition
                });
                qmlStops.push(stopObj);
            }
        }
    }

    return {
        qmlStops: qmlStops,
        cache: localCache
    };
}

/**
 * [动画帧] 更新位置
 * 极低开销，每帧调用
 */
function updateGradientPositions(phase, cache) {
    if (!cache) return;
    var len = cache.length;
    for (var i = 0; i < len; i++) {
        var item = cache[i];
        // 仅检查对象是否存活
        if (item.qmlObject) {
            // 核心动画逻辑：基础位置 + 偏移量
            item.qmlObject.position = item.basePos + phase;
        }
    }
}

/**
 * [清理] 清除旧缓存引用
 */
function clearGradientCache(cache) {
    if (cache) {
        cache.length = 0;
    }
}

/**
 * [辅助] 色相旋转 (用于简易模式)
 */
function adjustGradientColor(clr, phase, settings) {
    if (!clr) return "#000000";
    if (!(settings.enableOverallGradientEffect ?? false)) return clr;
    if (!(settings.enableOverallGradientAnim ?? false)) return clr;
    if (settings.useFillGradient ?? false) return clr; 
    
    var c = Qt.lighter(clr, 1.0);
    var h = c.hslHue + phase; 
    if (h > 1.0) h -= 1.0;    
    
    return Qt.hsla(h, c.hslSaturation, c.hslLightness, c.a);
}