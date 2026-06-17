import QtQuick 2.12
import QtGraphicalEffects 1.12
import NERvGear 1.0 as NVG

// ImageElementAdvanced 的图形特效叠加层。
//
// 从 ImageElementAdvanced.qml 中迁出的"特效兄弟节点 + 遮罩源 + 数据源输出"整体，
// 以 (sourceItem + settings) 参数化。语义与原先保持一致：每个特效都以原图(sourceItem)
// 为源、各自独立叠加显示，由对应的 settings 开关控制 visible/source。
//
// 接口（其余取值均由 settings 内部推导，见下方 readonly 属性）：
//   sourceItem   : 被处理的原图项（= ImageElementAdvanced 的 imageSource）
//   settings     : 元素设置表（= thiz.settings）
//   dataSource   : 数据源（= thiz.dataSource），供各遮罩数据源输出使用
//   itemPressed  : 按下态（= thiz.itemPressed），用于颜色叠加三态
//   itemHovered  : 悬停态（= thiz.itemHovered）
//   gradient     : 颜色渐变动画使用的常驻 Gradient 对象（= dynamicGradient）
Item {
    id: stack

    property Item sourceItem
    property var settings
    property NVG.DataSource dataSource
    property bool itemPressed: false
    property bool itemHovered: false
    property Gradient gradient: null

    // 该层与原图等大、等位（sourceItem 为同级兄弟项，可直接锚定）
    anchors.fill: sourceItem

    // ===== 由 settings 推导的内部取值（对应原 thiz 上的派生属性）=====
    readonly property bool blendDataEnabled: settings.blendDataEnabled ?? false
    readonly property bool opacityMaskDataEnabled: settings.opacityMaskDataEnabled ?? false
    readonly property bool thresholdMaskDataEnabled: settings.thresholdMaskDataEnabled ?? false
    readonly property bool displaceDataEnabled: settings.displaceDataEnabled ?? false
    readonly property bool blendMaskedBlurDataEnabled: settings.blendMaskedBlurDataEnabled ?? false

    readonly property bool enableColorGradient: settings.colorGradient ?? false
    readonly property bool allowGlowTransparentBorder: settings.glowTransparentBorder ?? false
    readonly property int fillMode: settings.fill ?? Image.PreserveAspectFit

    // 颜色叠加三态
    readonly property color normalColor: settings.color ?? "transparent"
    readonly property color hoveredColor: settings.hoveredColor ?? normalColor
    readonly property color pressedColor: settings.pressedColor ?? hoveredColor

    // 电平调节颜色
    readonly property color minInput: settings.minimumInputColor ?? "transparent"
    readonly property color minOutput: settings.minimumOutputColor ?? "transparent"
    readonly property color maxInput: settings.maximumInputColor ?? "#ffffffff"
    readonly property color maxOutput: settings.maximumOutputColor ?? "#ffffffff"

    // 遮罩源图片
    readonly property var blendImage: settings.enableBlend ? settings.blendSource : ""
    readonly property var displaceImage: settings.enableDisplace ? settings.displacementSource : ""
    readonly property var opacityMaskImage: settings.enableOpacityMask ? settings.opacityMaskSource : ""
    readonly property var thresholdMaskImage: settings.enableThresholdMask ? settings.thresholdMaskSource : ""

//颜色
    //颜色
    ColorOverlay{
        visible:settings.colorOverlay ?? false
        anchors.fill: parent
        source: settings.colorOverlay ? sourceItem : null
        color: {
        if (stack.itemPressed && pressedColor.a)
            return pressedColor;
        if (stack.itemHovered && hoveredColor.a)
            return hoveredColor;
        return normalColor;
        }
    }
    //亮度对比度
    BrightnessContrast {
        anchors.fill: parent
        source: settings.changeBrightnessContrast ? sourceItem : null
        visible: settings.changeBrightnessContrast ?? false
        brightness: (settings.brightness ?? 0)/100//亮度
        contrast: (settings.contrast ?? 0)/100//对比度
        cached:settings.brightnessContrastCached ?? false//缓存
    }
    //着色
    Colorize {
        anchors.fill: parent
        source: settings.colorize ? sourceItem : null
        visible: settings.colorize ?? false
        hue: (settings.colorizeHue ?? 0)/100
        saturation: (settings.colorizeSaturation ?? 100)/100
        lightness: (settings.colorizeLightness ?? 0)/100
        cached:settings.colorizeCached ?? false//[修复] 原误用 brightnessContrastCached
    }
    //去饱和
    Desaturate {
        anchors.fill: parent
        source: settings.desaturate ? sourceItem : null
        visible: settings.desaturate ?? false
        desaturation: (settings.desaturation ?? 0)/100
        cached: settings.desaturateCached ?? false
    }
    //伽马调节
    GammaAdjust {
        anchors.fill: parent
        source: settings.gammaAdjust ? sourceItem : null
        visible: settings.gammaAdjust ?? false
        gamma: (settings.gamma ?? 1000)/1000
        cached: settings.gammaCached ?? false
    }
    //色相饱和度
    HueSaturation {
        anchors.fill: parent
        source: settings.hueSaturation ? sourceItem : null
        visible: settings.hueSaturation ?? false
        hue: (settings.hueSaturationHue ?? 0)/100
        saturation: (settings.hueSaturationSaturation ?? 0)/100
        lightness: (settings.hueSaturationLightness ?? 0)/100
        cached: settings.hueSaturationCached ?? false
    }
    //电平调节
    LevelAdjust {
        anchors.fill: parent
        source: settings.levelAdjust ? sourceItem : null
        visible: settings.levelAdjust ?? false
        gamma : Qt.vector3d((settings.levelAdjustGammaX ?? 100)/100, (settings.levelAdjustGammaY ?? 100)/100, (settings.levelAdjustGammaZ ?? 100)/100)
        maximumInput : maxInput
        maximumOutput : maxOutput
        minimumInput : minInput
        minimumOutput : minOutput
        cached : settings.levelAdjustCached ?? false
    }
//动画
    //颜色动画
        //颜色动画选项0~3 , 6
        LinearGradient {
            anchors.fill: parent
            cached: settings.enableColorAnimationCached ?? false
            source: (enableColorGradient && (settings.animationDirect >= 0 && settings.animationDirect <= 3 || settings.animationDirect == 6)) ? sourceItem : null
            visible: (enableColorGradient && (settings.animationDirect >= 0 && settings.animationDirect <= 3 || settings.animationDirect == 6))

            // [优化] 绑定常驻对象
            gradient: stack.gradient

            start: {
                switch (settings.animationDirect ?? 0) {
                    case 0 :
                    case 1 :
                    case 2 :
                    case 3 : return Qt.point(0, 0); break;
                    case 6 : return Qt.point(settings.animationAdvancedStartX ?? 0, settings.animationAdvancedStartY ?? 0); break;
                    default: return Qt.point(0, 0); break;
                }
                return Qt.point(0, 0);
            }
            end: {
                switch (settings.animationDirect ?? 0) {
                    case 0 : return Qt.point(sourceItem.width, 0); break;
                    case 1 : return Qt.point(0, sourceItem.height); break;
                    case 2 : return Qt.point(sourceItem.width, sourceItem.height); break;
                    case 3 : return Qt.point(0, 0); break;
                    case 6 : return Qt.point(settings.animationAdvancedEndX ?? 100, settings.animationAdvancedEndY ?? 100); break;
                    default: return Qt.point(sourceItem.width, 0); break;
                }
                return Qt.point(sourceItem.width, 0);
            }
        }

        // 颜色动画选项 4 (Radial)
        RadialGradient {
            anchors.fill: parent
            angle: settings.animationAngle ?? 0
            cached: settings.enableColorAnimationCached ?? false
            horizontalOffset: settings.animationHorizontal ?? 0
            verticalOffset: settings.animationVertical ?? 0
            horizontalRadius: settings.animationHorizontalRadius ?? 50
            verticalRadius: settings.animationVerticalRadius ?? 50
            source: (enableColorGradient && (settings.animationDirect == 4)) ? sourceItem : null
            visible: (enableColorGradient && (settings.animationDirect == 4))

            // [优化] 绑定常驻对象
            gradient: stack.gradient
        }

        // 颜色动画选项 5 (Conical)
        ConicalGradient {
            anchors.fill: parent
            cached: settings.enableColorAnimationCached ?? false
            angle: settings.animationAngle ?? 0
            horizontalOffset: settings.animationHorizontal ?? 0
            verticalOffset: settings.animationVertical ?? 0
            source: (enableColorGradient && (settings.animationDirect == 5)) ? sourceItem : null
            visible: (enableColorGradient && (settings.animationDirect == 5))

            // [优化] 绑定常驻对象
            gradient: stack.gradient
        }
//发光
    Glow {
        anchors.fill: parent
        source: settings.enableGlow ? sourceItem : null
        visible: settings.enableGlow ?? false
        cached: settings.glowCache ?? false//缓存
        radius: settings.glowRadius ?? 5//作用范围
        samples: settings.glowSamples ?? 5//采样数
        spread: (settings.glowSpread ?? 50)/100//强度
        color: settings.glowColor ?? "white"//颜色
        transparentBorder: allowGlowTransparentBorder ?? false//透明边框 bool
    }
//阴影
    //外阴影
    DropShadow {
        anchors.fill: parent
        source: settings.enableDropShadow ? sourceItem : null
        visible: settings.enableDropShadow ?? false
        color: settings.dropShadowColor ?? "white"//颜色
        radius: settings.dropShadowRadius ?? 5//半径
        samples: settings.dropShadowSamples ?? 5//样本数
        horizontalOffset: settings.dropShadowHorizontalOffset ?? 0//水平位移
        verticalOffset: settings.dropShadowVerticalOffset ?? 0//垂直位移
        transparentBorder: settings.dropShadowTransparentBorder ?? false//透明边框
        cached: settings.dropShadowCache ?? false//缓存
    }
    //内阴影
    InnerShadow {
        anchors.fill: parent
        source: settings.enableInnerShadow ? sourceItem : null
        visible: settings.enableInnerShadow ?? false
        color: settings.innerShadowColor ?? "white"//颜色
        radius: settings.innerShadowRadius ?? 5//半径
        samples: settings.innerShadowSamples ?? 5//样本数
        horizontalOffset: settings.innerShadowHorizontalOffset ?? 0//水平位移
        verticalOffset: settings.innerShadowVerticalOffset ?? 0//垂直位移
        fast: settings.innerShadowFastAlgorithm ?? false//快速渲染
        cached: settings.innerShadowCache ?? false//缓存
    }
//模糊
    //快速模糊
        FastBlur {
            anchors.fill: parent
            source: settings.fastBlur ? sourceItem : null
            visible: settings.fastBlur ?? false
            radius: settings.fastBlurRadius ?? 5//半径
            transparentBorder: settings.fastBlurTransparentBorder ?? false//透明边框
            cached: settings.fastBlurCached ?? false//缓存
        }
    //高斯模糊
        GaussianBlur {
            anchors.fill: parent
            source: settings.gaussianBlur ? sourceItem : null
            visible: settings.gaussianBlur ?? false
            radius: settings.gaussianBlurRadius ?? 5//半径
            deviation: settings.gaussianBlurDeviation ?? 3//偏差值
            samples: settings.gaussianBlurSamples ?? 5//样本数
            transparentBorder: settings.gaussianBlurTransparentBorder ?? false//[修复] 原误用 dropShadowTransparentBorder
            cached: settings.gaussianBlurCached ?? false//缓存
        }
    //蒙版模糊
        NVG.ImageSource {
            visible: settings.maskedBlur ?? false
            id: maskedBlurIamge
            anchors.fill: parent
            fillMode: stack.fillMode
            playing: status === Image.Ready
            configuration: {
                if (blendMaskedBlurDataEnabled)//启用数据源
                    return maskedBluroutput.result;
                return maskedBlurIamge;
            }
        }
        MaskedBlur {
            anchors.fill: parent
            source: settings.maskedBlur ? sourceItem : null
            visible: settings.maskedBlur ?? false
            maskSource: maskedBlurIamge//遮罩源
            radius: settings.maskedBlurRadius ?? 0
            samples: settings.maskedBlurSamples ?? 9
            cached: settings.maskedBlurCached ?? false
        }
    //递归模糊
        RecursiveBlur {
            anchors.fill: parent
            source: settings.recursiveBlur ? sourceItem : null
            visible: settings.recursiveBlur ?? false
            loops : settings.recursiveBlurLoops ?? 0
            progress : settings.recursiveBlurProgress ?? 1
            radius : (settings.recursiveBlurRadius ?? 0)/10
            transparentBorder : settings.recursiveBlurTransparentBorder ?? false
            cached : settings.recursiveBlurCached ?? false
        }
//动态模糊
    //方向模糊
        DirectionalBlur {
            anchors.fill: parent
            source : settings.directionalBlur ? sourceItem : null
            visible: settings.directionalBlur ?? false
            angle : settings.directionalBlurAngle ?? 0//角度
            length : settings.directionalBlurLength ?? 0//长度
            samples : settings.directionalBlurSamples ?? 0//采样数
            transparentBorder : settings.directionalBlurTransparentBorder ?? false
            cached : settings.directionalBlurCached ?? false
        }
    //径向模糊
        RadialBlur {
            anchors.fill: parent
            source: settings.radialBlur ? sourceItem : null
            visible: settings.radialBlur ?? false
            angle: settings.radialBlurAngle ?? 0
            horizontalOffset: settings.radialBlurHorizontalOffset ?? 0
            verticalOffset: settings.radialBlurVerticalOffset ?? 0
            samples: settings.radialBlurSamples ?? 0
            transparentBorder: settings.radialBlurTransparentBorder ?? false
            cached: settings.radialBlurCached ?? false//[修复] 原默认值误写为 0
        }
    //缩放模糊
        ZoomBlur {
            anchors.fill: parent
            source: settings.zoomBlur ? sourceItem : null
            visible: settings.zoomBlur ?? false
            horizontalOffset: settings.zoomBlurHorizontalOffset ?? 0
            verticalOffset: settings.zoomBlurVerticalOffset ?? 0
            length: settings.zoomBlurrLength ?? 0
            samples: settings.zoomBlurSamples ?? 0
            transparentBorder: settings.zoomBlurTransparentBorder ?? false
            cached: settings.zoomBlurCached ?? false
        }
//遮罩和取代
    NVG.ImageSource {
        visible: settings.enableBlend ?? false
        id: blendImageSource
        anchors.fill: parent
        fillMode: stack.fillMode
        playing: status === Image.Ready
        configuration: {
            if (blendDataEnabled)//启用数据源
                return blendOutput.result;
            return blendImage;
        }
    }
    Blend {
        anchors.fill: parent
        source: settings.enableBlend ? sourceItem : null
        visible: settings.enableBlend ?? false
        //遮罩图像
        foregroundSource: blendImageSource
        //模式
        mode: {
            switch(settings.blendMode) {
                case 0: return "normal";
                case 1: return "addition";
                case 2: return "average";
                case 3: return "color";
                case 4: return "colorBurn";
                case 5: return "colorDodge";
                case 6: return "darken";
                case 7: return "darkerColor";
                case 8: return "difference";
                case 9: return "divide";
                case 10: return "exclusion";
                case 11: return "hardLight";
                case 12: return "hue";
                case 13: return "lighten";
                case 14: return "lighterColor";
                case 15: return "lightness";
                case 16: return "multiply";
                case 17: return "negation";
                case 18: return "saturation";
                case 19: return "screen";
                case 20: return "subtract";
                case 21: return "softLight";
            }
            return "normal";
        }
        //缓存
        cached: settings.enableBlendCached ?? false
    }
    //不透明遮罩
    NVG.ImageSource {
        visible: settings.enableOpacityMask ?? false
        id: opacityMaskImageSource
        anchors.fill: parent
        //mirror : mirrorEnabled//镜像
        fillMode: stack.fillMode
        playing: status === Image.Ready
        configuration: {
            if (opacityMaskDataEnabled)//启用数据源
                return opacityMaskOutput.result;
            return opacityMaskImage;
        }
    }
    OpacityMask {
        anchors.fill: parent
        source: settings.enableOpacityMask ? sourceItem : null
        visible: settings.enableOpacityMask ?? false
        maskSource: opacityMaskImageSource//遮罩来源
        invert: settings.opacityMaskInvert ?? false//反转
        cached: settings.enableOpacityMaskCached ?? false//缓存
    }
    //覆盖遮罩
    NVG.ImageSource {
        visible: settings.enableThresholdMask ?? false
        id: thresholdMaskImageSource
        anchors.fill: parent
        //mirror : mirrorEnabled//镜像
        fillMode: stack.fillMode
        playing: status === Image.Ready
        configuration: {
            if (thresholdMaskDataEnabled)//启用数据源
                return thresholdMaskOutput.result;
            return thresholdMaskImage;
        }
    }
    ThresholdMask {
        anchors.fill: parent
        source: settings.enableThresholdMask ? sourceItem : null
        visible: settings.enableThresholdMask ?? false
        maskSource: thresholdMaskImageSource//来源
        threshold: (settings.thresholdMaskSourceThreshold ?? 50)/100//阔值
        spread: (settings.thresholdMaskSpread ?? 50)/100//强度
        cached: settings.enableThresholdMaskCached ?? false//缓存
    }
    //取代
    NVG.ImageSource {
        id: displaceImageSource
        anchors.fill: parent
        visible: settings.enableDisplace ?? false
        fillMode: stack.fillMode
        playing: status === Image.Ready
        configuration: {
            if (displaceDataEnabled)//启用数据源
                return displaceOutput.result;
            return displaceImage;
        }
    }
    Displace {
        anchors.fill: parent
        source: settings.enableDisplace ? sourceItem : null
        visible: settings.enableDisplace ?? false
        displacementSource: displaceImageSource
        displacement: settings.displacement ?? 50
        cached: settings.enableDisplaceCached ?? false
    }
//数据源
    NVG.DataSourceRawOutput {
        id: maskedBluroutput
        source: blendMaskedBlurDataEnabled ? stack.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: blendOutput
        source: blendDataEnabled ? stack.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: opacityMaskOutput
        source: opacityMaskDataEnabled ? stack.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: thresholdMaskOutput
        source: thresholdMaskDataEnabled ? stack.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: displaceOutput
        source: displaceDataEnabled ? stack.dataSource : null
    }
}
