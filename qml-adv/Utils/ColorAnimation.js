// GradientUtils.js - 渐变相关工具函数

/**
 * 调整渐变颜色（色相旋转动画）
 * @param {color} clr - 原始颜色
 * @param {real} phase - 动画相位 (0.0 ~ 1.0)
 * @param {object} settings - 设置对象
 * @returns {color} 调整后的颜色
 */
function adjustGradientColor(clr, phase, settings) {
    if (!clr) return "#000000";
    
    // 如果没开特效或没开动画，直接返回原色
    if (!(settings.enableOverallGradientEffect ?? false)) return clr;
    if (!(settings.enableOverallGradientAnim ?? false)) return clr;
    if (settings.useFillGradient ?? false) return clr; // 自定义模式不进行色相旋转
    
    var c = Qt.lighter(clr, 1.0);
    var h = c.hslHue + phase; // 偏移色相
    if (h > 1.0) h -= 1.0;    // 归一化
    
    return Qt.hsla(h, c.hslSaturation, c.hslLightness, c.a);
}

/**
 * 生成渐变对象
 * @param {object} settings - 设置对象
 * @param {real} animPhase - 动画相位
 * @param {array} defaultStops - 默认渐变停止点
 * @param {function} makeGradientFunc - makeGradient函数引用
 * @returns {Gradient} 渐变对象
 */
function generateGradient(settings, animPhase, defaultStops, makeGradientFunc) {
    // 1. 如果没开自定义颜色，返回简易渐变对象(由 adjustGradientColor 控制动画)
    if (!settings.useFillGradient) {
        // 返回 null，让调用方使用简单的 Gradient 对象
        return null;
    }

    // 2. 基础数据检查
    var stopsData = settings.fillStops;
    if (!stopsData || stopsData.length === 0) {
        return makeGradientFunc(defaultStops);
    }

    // 3. 如果没开动画，直接渲染静态自定义颜色
    if (!(settings.enableOverallGradientAnim ?? false)) {
        return makeGradientFunc(stopsData);
    }

    // 4. 自定义颜色的动画逻辑 (位置移动)
    // 4.1 清洗并排序数据
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

    // 4.2 构建渲染列表 (三段拼接 k=-1, 0, 1)
    // 这解决了循环时的跳变问题
    var renderStops = [];
    var shift = animPhase; // 0.0 ~ 1.0

    for (var k = -1; k <= 1; k++) {
        for (var j = 0; j < baseStops.length; j++) {
            var original = baseStops[j];
            
            // 新位置 = 原始位置 + 周期偏移 + 动画位移
            var newPos = original.pos + k + shift;

            // 总是保留所有生成的点，交给 QML 处理边界插值
            renderStops.push({
                position: newPos,
                color: original.color
            });
        }
    }
    return makeGradientFunc(renderStops);
}

/**
 * 创建渐变对象的辅助函数
 * 注意：此函数需要在 QML 上下文中调用，因为需要访问 Component
 * @param {array} stopdefs - 渐变停止点数组
 * @param {array} defaultStops - 默认渐变停止点
 * @param {Component} gradientComponent - 渐变组件
 * @returns {Gradient} 渐变对象
 */
function makeGradient(stopdefs, defaultStops, gradientComponent) {
    if (Array.isArray(stopdefs)) {
        return gradientComponent.createObject(null, {stopdefs: stopdefs});
    }
    return makeGradient(defaultStops, defaultStops, gradientComponent);
}