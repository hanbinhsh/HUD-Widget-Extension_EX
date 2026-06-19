import QtQuick 2.12
import QtGraphicalEffects 1.12

// 可复用的全局涟漪控制器（从 HUDWidget 抽出，HUD 与 EX 启动器共用）。
// 用法：GlobalRippleController { id: r; settings: widget.defaultSettings; maskItem: itemView }，点击处理里调用 r.trigger(x, y)
Item {
    id: rippleRoot
    property var settings: null
    property Item maskItem: null
    anchors.fill: parent
    // 抽出前 globalRippleOverlay 是 itemView 的同级、z:9999 直接覆盖在物品之上；
    // 抽出后 overlay 变成本组件的子项，其内部 z 只在本组件内生效，需让整个组件浮到同级最上层。
    // 纯 Item 无 MouseArea，不拦截输入，点击会穿透到下方物品/控件。
    z: 9999

    // --- 涟漪效果实现 ---
    Timer {
        id: burstTimer
        property real targetX: 0
        property real targetY: 0
        property int remainingCount: 0
        
        repeat: true
        // 只有当开启涟漪且剩余次数大于0时才触发
        onTriggered: {
            if (remainingCount > 0) {
                internalCreateRipple(targetX, targetY);
                remainingCount--;
            } else {
                stop();
            }
        }
    }
    // 从某个源 Item 的局部坐标触发涟漪（调用方无需自己 mapToItem，
    // 也避免对非 Item 的 widget（如 NVG.View）调用 mapToItem 报错）。
    function triggerFromItem(srcItem, lx, ly) {
        if (!srcItem) { trigger(lx, ly); return; }
        var p = srcItem.mapToItem(rippleRoot, lx, ly);
        trigger(p.x, p.y);
    }

    // 1. 涟漪逻辑控制
    function trigger(x, y) {
        // 1. 立即生成第一个涟漪
        internalCreateRipple(x, y);

        // 2. 如果开启了连发模式
        if (settings.rippleBurstMode) {
            // 配置定时器参数
            burstTimer.targetX = x;
            burstTimer.targetY = y;
            // 剩余次数 = 总次数 - 1 (因为刚刚已经生成了一个)
            burstTimer.remainingCount = (settings.rippleBurstCount ?? 3) - 1;
            burstTimer.interval = settings.rippleBurstInterval ?? 150;
            burstTimer.restart(); // 重置并启动
        }
    }

    function internalCreateRipple(x, y) {
        if (globalRippleComponent.status === Component.Ready) {
            
            // 颜色逻辑 (每次生成都重新计算，这样如果是随机颜色，连发的每一个颜色都不一样)
            var finalColor = settings.rippleColor ?? "#40FFFFFF";
            if (settings.rippleColorMode === 1) { 
                finalColor = Qt.hsla(Math.random(), 0.8, 0.6, 1.0);
            }
            
            var bezier = [
                (settings.ripple_bezierX1 ?? 25) / 100.0,
                (settings.ripple_bezierY1 ?? 10) / 100.0,
                (settings.ripple_bezierX2 ?? 25) / 100.0,
                (settings.ripple_bezierY2 ?? 100) / 100.0,
                1, 1
            ];

            // 动态创建涟漪对象
            var ripple = globalRippleComponent.createObject(rippleContainer, {
                "centerX": x, 
                "centerY": y,
                "color": finalColor,
                "maxRadius": settings.maxRadius ?? 200,
                "duration": settings.duration ?? 600,
                
                // 缓动参数
                "easingType": settings.ripple_easingType ?? 1,
                "easingAmplitude": (settings.ripple_easingAmplitude ?? 100) / 100.0,
                "easingOvershoot": (settings.ripple_easingOvershoot ?? 170) / 100.0,
                "easingPeriod": (settings.ripple_easingPeriod ?? 30) / 100.0,
                "easingBezier": bezier,

                "styleMode": settings.rippleStyle ?? 0, 
                "strokeWidth": settings.strokeWidth ?? 2,
                "shapeType": settings.rippleShape ?? 0, 
                "sides": settings.ripplePolygonSides ?? 5,
                "baseRotation": settings.rippleRotation ?? 0,
                "randomizeRotation": settings.randomizeRippleRotation ?? false,
                "rotationOffset": settings.rippleRotationSpeed ?? 0,
                "shrinkMode": settings.rippleShrinkMode ?? false,
            });
        }
    }

    // 2. 涟漪显示层
    Item {
        id: globalRippleOverlay
        anchors.fill: parent
        z: 9999 
        visible: settings.rippleEffectEnabled ?? false
        enabled: false 

        layer.enabled: settings.globalRippleMaskToContent ?? false
        layer.samplerName: "maskSource"
        layer.effect: OpacityMask {
            anchors.fill: parent
            source: rippleContainer
            maskSource: rippleRoot.maskItem 
        }

        Item {
            id: rippleContainer
            anchors.fill: parent
            clip: !(settings.globalRippleMaskToContent ?? false)
        }
    }

    // 3. 涟漪个体组件
    Component {
        id: globalRippleComponent
        Item {
            id: rippleItem
            
            // --- 基础参数 ---
            property real centerX: 0
            property real centerY: 0
            property color color: "white"
            property real maxRadius: 100
            property int duration: 600
            
            // --- 缓动参数 ---
            property int easingType: Easing.OutQuad
            property real easingAmplitude: 1.0
            property real easingOvershoot: 1.7
            property real easingPeriod: 0.3
            property var easingBezier: [0.25, 0.1, 0.25, 1.0, 1, 1]

            // --- 样式与特效 ---
            property int styleMode: 0
            property int strokeWidth: 2
            property int shapeType: 0
            property int sides: 5
            property real baseRotation: 0
            property real currentRadius: 0
            property real currentOpacity: 1.0
            property bool shrinkMode: false
            property bool randomizeRotation: false
            property real rotationOffset: 0
            property real startRotation: randomizeRotation ? Math.random() * 360 : baseRotation
            property real currentRotation: startRotation
            
            width: maxRadius * 2
            height: maxRadius * 2
            x: centerX - maxRadius
            y: centerY - maxRadius

            // --- 绘图逻辑 (Canvas) ---
            Canvas {
                id: rCanvas
                anchors.fill: parent
                renderStrategy: Canvas.Immediate
                renderTarget: Canvas.Image

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    var alpha = rippleItem.currentOpacity;
                    if (alpha <= 0.01) return;
                    
                    ctx.globalAlpha = alpha;
                    drawShape(ctx, rippleItem.currentRadius, rippleItem.color);
                    ctx.globalAlpha = 1.0;
                }

                function drawShape(ctx, r, paintColor) {
                    if (r <= 0) return;
                    ctx.beginPath();
                    if (rippleItem.shapeType === 0) {
                        ctx.arc(width/2, height/2, r, 0, 2 * Math.PI);
                    } else {
                        var cx = width / 2;
                        var cy = height / 2;
                        var sides = Math.max(3, rippleItem.sides);
                        var angleStep = (2 * Math.PI) / sides;
                        var rotRad = (rippleItem.currentRotation - 90) * Math.PI / 180;
                        for (var i = 0; i < sides; i++) {
                            var theta = i * angleStep + rotRad;
                            var px = cx + r * Math.cos(theta);
                            var py = cy + r * Math.sin(theta);
                            if (i === 0) ctx.moveTo(px, py);
                            else ctx.lineTo(px, py);
                        }
                        ctx.closePath();
                    }
                    if (rippleItem.styleMode === 0) { 
                        ctx.fillStyle = paintColor; ctx.fill(); 
                    } else { 
                        ctx.strokeStyle = paintColor; ctx.lineWidth = rippleItem.strokeWidth; ctx.stroke(); 
                    }
                }
            }

            onCurrentRadiusChanged: rCanvas.requestPaint()
            onCurrentOpacityChanged: rCanvas.requestPaint()

            // --- 动画逻辑 ---
            
            // 1. 在组件创建完成时，动态配置动画参数并启动
            Component.onCompleted: {
                // 配置半径动画的缓动参数
                setupEasing(radiusAnim);
                // 启动动画
                anim.start();
            }

            // 辅助函数：只设置需要的参数
            function setupEasing(animation) {
                animation.easing.type = rippleItem.easingType;

                // 贝塞尔曲线 (Type 41)
                if (rippleItem.easingType === Easing.BezierSpline) {
                    animation.easing.bezierCurve = rippleItem.easingBezier;
                } 
                // Elastic (29-32) & Bounce (37-40) -> 需要 Amplitude
                else if ((rippleItem.easingType >= 29 && rippleItem.easingType <= 32) || 
                         (rippleItem.easingType >= 37 && rippleItem.easingType <= 40)) {
                    animation.easing.amplitude = rippleItem.easingAmplitude;
                    // Elastic 还需要 Period
                    if (rippleItem.easingType <= 32) {
                        animation.easing.period = rippleItem.easingPeriod;
                    }
                }
                // Back (33-36) -> 需要 Overshoot
                else if (rippleItem.easingType >= 33 && rippleItem.easingType <= 36) {
                    animation.easing.overshoot = rippleItem.easingOvershoot;
                }
            }

            ParallelAnimation {
                id: anim
                running: false // [修改] 默认为 false，由 onCompleted 启动
                onFinished: rippleItem.destroy()

                NumberAnimation { 
                    id: radiusAnim
                    target: rippleItem
                    property: "currentRadius"
                    from: rippleItem.shrinkMode ? rippleItem.maxRadius : 0
                    to:   rippleItem.shrinkMode ? 0 : rippleItem.maxRadius
                    duration: rippleItem.duration
                }

                NumberAnimation { 
                    target: rippleItem
                    property: "currentOpacity"
                    from: rippleItem.shrinkMode ? 0.0 : 1.0
                    to:   rippleItem.shrinkMode ? 1.0 : 0.0
                    duration: rippleItem.duration
                    easing.type: rippleItem.shrinkMode ? Easing.InQuad : Easing.OutQuad 
                }

                NumberAnimation {
                    target: rippleItem
                    property: "currentRotation"
                    from: rippleItem.startRotation
                    to:   rippleItem.startRotation + rippleItem.rotationOffset
                    duration: rippleItem.duration
                }
            }
        }
    }
    // --- 涟漪效果结束
}