import QtQuick 2.12
import QtQuick.Controls 2.12
import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

// 可复用的"完整图形特效"偏好面板（颜色 / 特效 / 混合遮罩 / 渐变 四页签）。
//
// 完全基于已有的可复用偏好件搭建，写入键名与 ImageEffectStack / ColorCycleGradient 一致。
//
// 用法：
//   EffectPreferencePanel { settingsTarget: currentElement.advancedEffect; groupEnabled: currentElement }
//
// 实现说明：用 TabBar + Loader（按当前页签加载对应内容 Column）替代 Page + StackLayout——
// 后者的 implicitHeight 在首次显示时常算不出（内容区塌陷为 0 高），导致页签内容看不见或溢出。
// Loader 方案下 implicitHeight = 页签栏高 + 当前内容 Column 高，始终正确，无需 clip 兜底。
Item {
    id: panel

    // 写入目标设置表
    property NVG.SettingsMap settingsTarget
    // 各分组的 enabled 门控（通常 = currentElement / currentItem）
    property var groupEnabled: true
    // 可选的前置页签：[{ label, component }, ...]。宿主可在内置四页之前插入自有页签（如 Basic），
    // 从而把宿主特有内容与共享特效页拼成同一行扁平页签，避免再嵌一层 TabBar。
    property var leadingTabs: []
    readonly property int leadingCount: leadingTabs.length
    readonly property var builtinTabLabels: [qsTr("Color"), qsTr("Effects"), qsTr("Blend"), qsTr("Gradient")]

    width: parent ? parent.width : 400
    implicitHeight: tabBar.height + contentLoader.height

    Column {
        width: parent.width

        TabBar {
            id: tabBar
            width: parent.width
            clip: true
            Repeater {
                model: panel.leadingTabs.map(function(t){ return t.label; }).concat(panel.builtinTabLabels)
                TabButton {
                    text: modelData
                    // 至少按文字本身的宽度撑开（避免被截断成 COL···），有富余时再均分填满
                    width: Math.max(implicitWidth, tabBar.width / Math.max(1, panel.leadingCount + panel.builtinTabLabels.length))
                }
            }
        }

        Loader {
            id: contentLoader
            width: parent.width
            sourceComponent: {
                var i = tabBar.currentIndex;
                if (i < panel.leadingCount)
                    return panel.leadingTabs[i].component;
                switch (i - panel.leadingCount) {
                    case 0: return colorComp;
                    case 1: return effectsComp;
                    case 2: return blendComp;
                    default: return gradientComp;
                }
            }
        }
    }

    // ===== 颜色调整 =====
    Component {
        id: colorComp
        Column {
            width: contentLoader.width
            topPadding: 16
            bottomPadding: 16

            EffectPreferenceGroup {
                id: colorOverlayGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "colorOverlay"
                switchLabel: qsTr("Color Overlay")
                NoDefaultColorPreference { name: "color"; label: qsTr("Color"); defaultValue: "transparent"; visible: colorOverlayGroup.switchValue }
                NoDefaultColorPreference { name: "hoveredColor"; label: qsTr("Hovered Color"); defaultValue: "transparent"; visible: colorOverlayGroup.switchValue }
                NoDefaultColorPreference { name: "pressedColor"; label: qsTr("Pressed Color"); defaultValue: "transparent"; visible: colorOverlayGroup.switchValue }
            }
            EffectPreferenceGroup {
                id: brightnessContrastGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "changeBrightnessContrast"
                switchLabel: qsTr("Brightness Contrast")
                EffectSliderPreference { owner: brightnessContrastGroup; name: "brightness"; label: qsTr("Brightness"); defaultValue: 0; from: -100; to: 100 }
                EffectSliderPreference { owner: brightnessContrastGroup; name: "contrast"; label: qsTr("Contrast"); defaultValue: 0; from: -100; to: 100 }
                EffectSwitchPreference { owner: brightnessContrastGroup; name: "brightnessContrastCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: colorizeGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "colorize"
                switchLabel: qsTr("Colorize")
                EffectSliderPreference { owner: colorizeGroup; name: "colorizeHue"; label: qsTr("HUE"); defaultValue: 0; from: 0; to: 100 }
                EffectSliderPreference { owner: colorizeGroup; name: "colorizeLightness"; label: qsTr("Lightness"); defaultValue: 0; from: -100; to: 100 }
                EffectSliderPreference { owner: colorizeGroup; name: "colorizeSaturation"; label: qsTr("Saturation"); defaultValue: 100; from: 0; to: 100 }
                EffectSwitchPreference { owner: colorizeGroup; name: "colorizeCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: desaturateGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "desaturate"
                switchLabel: qsTr("Desaturate")
                EffectSliderPreference { owner: desaturateGroup; name: "desaturation"; label: qsTr("Desaturation"); defaultValue: 0; from: 0; to: 100 }
                EffectSwitchPreference { owner: desaturateGroup; name: "desaturateCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: gammaAdjustGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "gammaAdjust"
                switchLabel: qsTr("Gamma Adjust")
                EffectSliderPreference { owner: gammaAdjustGroup; name: "gamma"; label: qsTr("Gamma"); defaultValue: 1000; from: 0; to: 100000 }
                EffectSwitchPreference { owner: gammaAdjustGroup; name: "gammaCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: hueSaturationGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "hueSaturation"
                switchLabel: qsTr("Hue Saturation")
                EffectSliderPreference { owner: hueSaturationGroup; name: "hueSaturationHue"; label: qsTr("HUE"); defaultValue: 0; from: -100; to: 100 }
                EffectSliderPreference { owner: hueSaturationGroup; name: "hueSaturationLightness"; label: qsTr("Lightness"); defaultValue: 0; from: -100; to: 100 }
                EffectSliderPreference { owner: hueSaturationGroup; name: "hueSaturationSaturation"; label: qsTr("Saturation"); defaultValue: 0; from: -100; to: 100 }
                EffectSwitchPreference { owner: hueSaturationGroup; name: "hueSaturationCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: levelAdjustGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "levelAdjust"
                switchLabel: qsTr("Level Adjust")
                EffectSliderPreference { owner: levelAdjustGroup; name: "levelAdjustGammaX"; label: qsTr("Gamma X"); defaultValue: 100; from: -10000; to: 10000; displayValue: value/100 }
                EffectSliderPreference { owner: levelAdjustGroup; name: "levelAdjustGammaY"; label: qsTr("Gamma Y"); defaultValue: 100; from: -100000; to: 100000; displayValue: value/100 }
                EffectSliderPreference { owner: levelAdjustGroup; name: "levelAdjustGammaZ"; label: qsTr("Gamma Z"); defaultValue: 100; from: -10000; to: 10000; displayValue: value/100 }
                NoDefaultColorPreference { name: "maximumInputColor"; label: qsTr("Max Input Color"); defaultValue: "#ffffffff"; visible: levelAdjustGroup.switchValue }
                NoDefaultColorPreference { name: "maximumOutputColor"; label: qsTr("Max Output Color"); defaultValue: "#ffffffff"; visible: levelAdjustGroup.switchValue }
                NoDefaultColorPreference { name: "minimumInputColor"; label: qsTr("Min Input Color"); defaultValue: "transparent"; visible: levelAdjustGroup.switchValue }
                NoDefaultColorPreference { name: "minimumOutputColor"; label: qsTr("Min Output Color"); defaultValue: "transparent"; visible: levelAdjustGroup.switchValue }
                EffectSwitchPreference { owner: levelAdjustGroup; name: "levelAdjustCached"; label: qsTr("Cached") }
            }
        }
    }

    // ===== 特效（模糊 / 阴影 / 发光）=====
    Component {
        id: effectsComp
        Column {
            width: contentLoader.width
            topPadding: 16
            bottomPadding: 16

            EffectPreferenceGroup {
                id: fastBlurGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "fastBlur"
                switchLabel: qsTr("Fast Blur")
                EffectSpinPreference { owner: fastBlurGroup; name: "fastBlurRadius"; label: qsTr("Radius"); defaultValue: 5; from: 0; to: 500 }
                EffectSwitchPreference { owner: fastBlurGroup; name: "fastBlurTransparentBorder"; label: qsTr("Transparent Border") }
                EffectSwitchPreference { owner: fastBlurGroup; name: "fastBlurCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: gaussianBlurGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "gaussianBlur"
                switchLabel: qsTr("Gaussian Blur")
                EffectSpinPreference { owner: gaussianBlurGroup; name: "gaussianBlurRadius"; label: qsTr("Radius"); defaultValue: 5; from: 0; to: 500 }
                EffectSpinPreference { owner: gaussianBlurGroup; name: "gaussianBlurDeviation"; label: qsTr("Deviation"); defaultValue: 3; from: 0; to: 1000 }
                EffectSpinPreference { owner: gaussianBlurGroup; name: "gaussianBlurSamples"; label: qsTr("Samples"); defaultValue: 5; from: 0; to: 100 }
                EffectSwitchPreference { owner: gaussianBlurGroup; name: "gaussianBlurTransparentBorder"; label: qsTr("Transparent Border") }
                EffectSwitchPreference { owner: gaussianBlurGroup; name: "gaussianBlurCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: maskedBlurGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "maskedBlur"
                switchLabel: qsTr("Masked Blur")
                P.ImagePreference {
                    name: "maskedBlurMaskSource"
                    label: qsTr("Mask Source")
                    visible: maskedBlurGroup.switchValue && !blendMaskedBlurDataEnabled.value
                }
                EffectSpinPreference { owner: maskedBlurGroup; name: "maskedBlurRadius"; label: qsTr("Radius"); defaultValue: 0; from: 0; to: 100 }
                EffectSpinPreference { owner: maskedBlurGroup; name: "maskedBlurSamples"; label: qsTr("Samples"); defaultValue: 9; from: 0; to: 100 }
                EffectSwitchPreference {
                    id: blendMaskedBlurDataEnabled
                    owner: maskedBlurGroup
                    name: "blendDataEnabled"
                    label: qsTr("Enable Data Source")
                }
                EffectSwitchPreference { owner: maskedBlurGroup; name: "maskedBlurCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: recursiveBlurGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "recursiveBlur"
                switchLabel: qsTr("Recursive Blur")
                EffectSpinPreference { owner: recursiveBlurGroup; name: "recursiveBlurRadius"; label: qsTr("Radius"); defaultValue: 0; from: 0; to: 160 }
                EffectSpinPreference { owner: recursiveBlurGroup; name: "recursiveBlurLoops"; label: qsTr("Loops"); defaultValue: 0; from: 0; to: 10000 }
                EffectSpinPreference { owner: recursiveBlurGroup; name: "recursiveBlurProgress"; label: qsTr("Progress"); defaultValue: 1; from: 0; to: 100 }
                EffectSwitchPreference { owner: recursiveBlurGroup; name: "recursiveBlurTransparentBorder"; label: qsTr("Transparent Border") }
                EffectSwitchPreference { owner: recursiveBlurGroup; name: "recursiveBlurCached"; label: qsTr("Cached") }
            }
            P.Separator{}
            EffectPreferenceGroup {
                id: directionalBlurGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "directionalBlur"
                switchLabel: qsTr("Directional Blur")
                EffectSpinPreference { owner: directionalBlurGroup; name: "directionalBlurLength"; label: qsTr("Length"); defaultValue: 0; from: 0; to: 1000 }
                EffectSpinPreference { owner: directionalBlurGroup; name: "directionalBlurAngle"; label: qsTr("Angle"); defaultValue: 0; from: -180; to: 180 }
                EffectSpinPreference { owner: directionalBlurGroup; name: "directionalBlurSamples"; label: qsTr("Samples"); defaultValue: 0; from: 0; to: 250 }
                EffectSwitchPreference { owner: directionalBlurGroup; name: "directionalBlurTransparentBorder"; label: qsTr("Transparent Border") }
                EffectSwitchPreference { owner: directionalBlurGroup; name: "directionalBlurCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: radialBlurGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "radialBlur"
                switchLabel: qsTr("Radial Blur")
                EffectSpinPreference { owner: radialBlurGroup; name: "radialBlurHorizontalOffset"; label: qsTr("Horizontal Offset"); defaultValue: 0; from: 0; to: 1000 }
                EffectSpinPreference { owner: radialBlurGroup; name: "radialBlurVerticalOffset"; label: qsTr("Vertical Offset"); defaultValue: 0; from: 0; to: 1000 }
                EffectSpinPreference { owner: radialBlurGroup; name: "radialBlurAngle"; label: qsTr("Angle"); defaultValue: 0; from: 0; to: 360 }
                EffectSpinPreference { owner: radialBlurGroup; name: "radialBlurSamples"; label: qsTr("Samples"); defaultValue: 0; from: 0; to: 250 }
                EffectSwitchPreference { owner: radialBlurGroup; name: "radialBlurTransparentBorder"; label: qsTr("Transparent Border") }
                EffectSwitchPreference { owner: radialBlurGroup; name: "radialBlurCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: zoomBlurGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "zoomBlur"
                switchLabel: qsTr("Zoom Blur")
                EffectSpinPreference { owner: zoomBlurGroup; name: "zoomBlurHorizontalOffset"; label: qsTr("Horizontal Offset"); defaultValue: 0; from: 0; to: 1000 }
                EffectSpinPreference { owner: zoomBlurGroup; name: "zoomBlurVerticalOffset"; label: qsTr("Vertical Offset"); defaultValue: 0; from: 0; to: 1000 }
                EffectSpinPreference { owner: zoomBlurGroup; name: "zoomBlurrLength"; label: qsTr("Length"); defaultValue: 0; from: 0; to: 1000 }
                EffectSpinPreference { owner: zoomBlurGroup; name: "zoomBlurSamples"; label: qsTr("Samples"); defaultValue: 0; from: 0; to: 250 }
                EffectSwitchPreference { owner: zoomBlurGroup; name: "zoomBlurTransparentBorder"; label: qsTr("Transparent Border") }
                EffectSwitchPreference { owner: zoomBlurGroup; name: "zoomBlurCached"; label: qsTr("Cached") }
            }
            P.Separator{}
            EffectPreferenceGroup {
                id: dropShadowGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "enableDropShadow"
                switchLabel: qsTr("Drop Shadow")
                NoDefaultColorPreference { name: "dropShadowColor"; label: qsTr("Color"); defaultValue: "white"; visible: dropShadowGroup.switchValue }
                EffectSpinPreference { owner: dropShadowGroup; name: "dropShadowRadius"; label: qsTr("Radius"); defaultValue: 5; from: 0; to: 500 }
                EffectSpinPreference { owner: dropShadowGroup; name: "dropShadowSamples"; label: qsTr("Samples"); defaultValue: 5; from: 0; to: 1000 }
                EffectSpinPreference { owner: dropShadowGroup; name: "dropShadowHorizontalOffset"; label: qsTr("Horizontal Offset"); defaultValue: 0; from: 0; to: 1000 }
                EffectSpinPreference { owner: dropShadowGroup; name: "dropShadowVerticalOffset"; label: qsTr("Vertical Offset"); defaultValue: 0; from: 0; to: 1000 }
                EffectSwitchPreference { owner: dropShadowGroup; name: "dropShadowTransparentBorder"; label: qsTr("Transparent Border") }
                EffectSwitchPreference { owner: dropShadowGroup; name: "dropShadowCache"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: innerShadowGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "enableInnerShadow"
                switchLabel: qsTr("Inner Shadow")
                NoDefaultColorPreference { name: "innerShadowColor"; label: qsTr("Color"); defaultValue: "white"; visible: innerShadowGroup.switchValue }
                EffectSpinPreference { owner: innerShadowGroup; name: "innerShadowRadius"; label: qsTr("Radius"); defaultValue: 5; from: 0; to: 500 }
                EffectSpinPreference { owner: innerShadowGroup; name: "innerShadowSamples"; label: qsTr("Samples"); defaultValue: 5; from: 0; to: 33 }
                EffectSpinPreference { owner: innerShadowGroup; name: "innerShadowHorizontalOffset"; label: qsTr("Horizontal Offset"); defaultValue: 0; from: 0; to: 1000 }
                EffectSpinPreference { owner: innerShadowGroup; name: "innerShadowVerticalOffset"; label: qsTr("Vertical Offset"); defaultValue: 0; from: 0; to: 1000 }
                EffectSwitchPreference { owner: innerShadowGroup; name: "innerShadowFastAlgorithm"; label: qsTr("Fast Algorithm") }
                EffectSwitchPreference { owner: innerShadowGroup; name: "innerShadowCache"; label: qsTr("Cached") }
            }
            P.Separator{}
            EffectPreferenceGroup {
                id: glowGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "enableGlow"
                switchLabel: qsTr("Glow")
                NoDefaultColorPreference { name: "glowColor"; label: qsTr("Color"); defaultValue: "white"; visible: glowGroup.switchValue }
                EffectSpinPreference { owner: glowGroup; name: "glowRadius"; label: qsTr("Radius"); defaultValue: 5; from: 0; to: 500 }
                EffectSpinPreference { owner: glowGroup; name: "glowSpread"; label: qsTr("Spread"); defaultValue: 50; from: 0; to: 100 }
                EffectSpinPreference { owner: glowGroup; name: "glowSamples"; label: qsTr("Samples"); defaultValue: 5; from: 0; to: 1000 }
                EffectSwitchPreference { owner: glowGroup; name: "glowTransparentBorder"; label: qsTr("Transparent Border") }
                EffectSwitchPreference { owner: glowGroup; name: "glowCache"; label: qsTr("Cached") }
            }
        }
    }

    // ===== 混合 / 遮罩 / 取代 =====
    Component {
        id: blendComp
        Column {
            width: contentLoader.width
            topPadding: 16
            bottomPadding: 16

            EffectPreferenceGroup {
                id: enableBlendGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "enableBlend"
                switchLabel: qsTr("Blend")
                P.ImagePreference {
                    name: "blendSource"
                    label: qsTr("Blend Image")
                    visible: enableBlendGroup.switchValue && !blendDataEnabled.value
                }
                P.SelectPreference {
                    name: "blendMode"
                    label: qsTr("Mode")
                    defaultValue: 0
                    model: [ qsTr("normal"), qsTr("addition"), qsTr("average"), qsTr("color"), qsTr("colorBurn"), qsTr("colorDodge"),qsTr("darken"),qsTr("darkerColor"),qsTr("difference"),qsTr("divide"),qsTr("exclusion"),qsTr("hardLight"),qsTr("hue"),qsTr("lighten"),qsTr("lighterColor"),qsTr("lightness"),qsTr("multiply"),qsTr("negation"),qsTr("saturation"),qsTr("screen"),qsTr("subtract"),qsTr("softLight")]
                    visible: enableBlendGroup.switchValue
                }
                EffectSwitchPreference { id: blendDataEnabled; owner: enableBlendGroup; name: "blendDataEnabled"; label: qsTr("Enable Data Source") }
                EffectSwitchPreference { owner: enableBlendGroup; name: "enableBlendCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: opacityMaskGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "enableOpacityMask"
                switchLabel: qsTr("Opacity Mask")
                P.ImagePreference {
                    name: "opacityMaskSource"
                    label: qsTr("Opacity Mask Image")
                    visible: opacityMaskGroup.switchValue && !opacityMaskDataEnabled.value
                }
                EffectSwitchPreference { owner: opacityMaskGroup; name: "opacityMaskInvert"; label: qsTr("Invert") }
                EffectSwitchPreference { id: opacityMaskDataEnabled; owner: opacityMaskGroup; name: "opacityMaskDataEnabled"; label: qsTr("Enable Data Source") }
                EffectSwitchPreference { owner: opacityMaskGroup; name: "enableOpacityMaskCached"; label: qsTr("Cached") }
            }
            EffectPreferenceGroup {
                id: thresholdMaskGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "enableThresholdMask"
                switchLabel: qsTr("Threshold Mask")
                P.ImagePreference {
                    name: "thresholdMaskSource"
                    label: qsTr("Threshold Mask Image")
                    visible: thresholdMaskGroup.switchValue && !thresholdMaskDataEnabled.value
                }
                EffectSpinPreference { owner: thresholdMaskGroup; name: "thresholdMaskSpread"; label: qsTr("Spread"); defaultValue: 50; from: 0; to: 100 }
                EffectSpinPreference { owner: thresholdMaskGroup; name: "thresholdMaskSourceThreshold"; label: qsTr("Threshold"); defaultValue: 50; from: 0; to: 100 }
                EffectSwitchPreference { id: thresholdMaskDataEnabled; owner: thresholdMaskGroup; name: "thresholdMaskDataEnabled"; label: qsTr("Enable Data Source") }
                EffectSwitchPreference { owner: thresholdMaskGroup; name: "enableThresholdMaskCached"; label: qsTr("Cached") }
            }
            P.Separator{}
            EffectPreferenceGroup {
                id: displaceGroup
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
                switchName: "enableDisplace"
                switchLabel: qsTr("Displace")
                P.ImagePreference {
                    name: "displacementSource"
                    label: qsTr("Displace Image")
                    visible: displaceGroup.switchValue && !displaceDataEnabled.value
                }
                EffectSliderPreference { owner: displaceGroup; name: "displacement"; label: qsTr("Displacement"); defaultValue: 0; from: -1; to: 1; stepSize: 0.01; displayValue: value*100 }
                EffectSwitchPreference { id: displaceDataEnabled; owner: displaceGroup; name: "displaceDataEnabled"; label: qsTr("Enable Data Source") }
                EffectSwitchPreference { owner: displaceGroup; name: "enableDisplaceCached"; label: qsTr("Cached") }
            }
        }
    }

    // ===== 渐变（cycleColor 颜色循环渐变）=====
    Component {
        id: gradientComp
        Column {
            width: contentLoader.width
            topPadding: 16
            bottomPadding: 16

            ColorGradientPreference {
                settingsTarget: panel.settingsTarget
                groupEnabled: panel.groupEnabled
            }
        }
    }
}
