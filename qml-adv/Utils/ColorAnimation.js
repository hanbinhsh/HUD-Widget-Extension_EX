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

// --------------------------------------Image Use---------------------------------------- //

/**
 * [初始化] 重建 GradientStop 对象
 * @param {Item} parent - 也就是那个常驻的 Gradient 对象
 * @param {Component} component - 用于创建 Stop 的组件
 * @param {Array} stopsData - 用户定义的 fillStops (仅模式3用到)
 * @param {int} mode - 3 为自定义模式，其他为标准模式
 */
function rebuildStops(parent, component, stopsData, mode) {
    var cache = [];
    
    // --- 模式 3: 自定义颜色 + 移动动画 ---
    if (mode === 3) {
        if (!stopsData || stopsData.length === 0) return cache;

        // 1. 清洗并排序
        var baseStops = [];
        for (var i = 0; i < stopsData.length; i++) {
            var item = stopsData[i];
            if (item) {
                baseStops.push({
                    pos: Number(item.position),
                    color: (item.color ? item.color.toString() : "#FF0000")
                });
            }
        }
        baseStops.sort(function(a, b) { return a.pos - b.pos; });

        // 2. 生成 3 倍数量的 Stop (k=-1, 0, 1) 用于无缝滚动
        for (var k = -1; k <= 1; k++) {
            for (var j = 0; j < baseStops.length; j++) {
                var original = baseStops[j];
                var basePos = original.pos + k;

                var obj = component.createObject(parent, {
                    "position": basePos,
                    "color": original.color
                });
                
                if (obj) {
                    cache.push({ qmlObject: obj, basePos: basePos });
                }
            }
        }
    } 
    // --- 模式 0, 1, 2: 标准 16 色循环 ---
    else {
        // 生成固定的 16 个点，位置均匀分布
        // 对应原代码 defaultStops 的结构
        var count = 16;
        for (var m = 0; m < count; m++) {
            // 原代码逻辑: 0.000, 0.067 ... 1.000
            // 这里我们用数学计算: m / (count - 1)
            var pos = m / (count - 1);
            
            var obj2 = component.createObject(parent, {
                "position": pos,
                "color": "transparent" // 初始颜色，稍后由 QML updateColors 填充
            });
            
            if (obj2) {
                // 标准模式不需要 basePos，因为位置不动，只变颜色
                cache.push({ qmlObject: obj2, index: m });
            }
        }
    }
    
    return cache;
}

/**
 * [模式3 专用] 更新位置
 */
function updatePositions(phase, cache) {
    if (!cache) return;
    var len = cache.length;
    for (var i = 0; i < len; i++) {
        var item = cache[i];
        if (item.qmlObject) {
            item.qmlObject.position = item.basePos + phase;
        }
    }
}

/**
 * [通用] 清理缓存
 */
function clearCache(cache) {
    if (!cache) return;
    for (var i = 0; i < cache.length; i++) {
        if (cache[i].qmlObject) {
            cache[i].qmlObject.destroy();
        }
    }
}