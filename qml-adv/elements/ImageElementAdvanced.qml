import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.13
import ".."
import "shared.js" as Shared
import NERvGear.Controls 1.0
import NERvExtras 1.0

import "../Utils/ColorAnimation.js" as GradientUtils


DataSourceElement {
    id:  thiz
//数据
    readonly property bool dataEnabled: settings.mode ?? false
    readonly property bool blendDataEnabled: settings.blendDataEnabled ?? false
    readonly property bool opacityMaskDataEnabled: settings.opacityMaskDataEnabled ?? false
    readonly property bool thresholdMaskDataEnabled: settings.thresholdMaskDataEnabled ?? false
    readonly property bool displaceDataEnabled: settings.displaceDataEnabled ?? false
    readonly property bool blendMaskedBlurDataEnabled: settings.blendMaskedBlurDataEnabled ?? false
//图片模式
    readonly property var normalImage: settings.normal ?? ""
    readonly property var hoveredImage: settings.hovered ?? normalImage
    readonly property var pressedImage: settings.pressed ?? hoveredImage
//镜像控制
    readonly property bool mirrorEnabled: Boolean(thiz.settings.mirror)
//颜色
    readonly property color normalColor: settings.color ?? "transparent"
    readonly property color hoveredColor: settings.hoveredColor ?? normalColor
    readonly property color pressedColor: settings.pressedColor ?? hoveredColor
//电平调节
    readonly property color minInput: settings.minimumInputColor ?? "transparent"
    readonly property color minOutput: settings.minimumOutputColor ?? "transparent"
    readonly property color maxInput: settings.maximumInputColor ?? "#ffffffff"
    readonly property color maxOutput: settings.maximumOutputColor ?? "#ffffffff"
//颜色渐变动画
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
        // 这一步对于某些情况下的 Qt 是必要的，尽管对象引用没变，但内容变了
        dynamicGradient.stops = stopCache.map(function(item){ return item.qmlObject; });
    }

    // === 模式 3 驱动 (Phase 0.0 ~ 1.0) ===
    property real colorAnimPhase: 0.0
    SequentialAnimation {
        id: colorAnimPhaseAnimation
        // 逻辑保持原版
        running: (settings.cycleColor === 3) && (fillStops.length > 0) && enableColorGradientAnimation && widget.NVG.View.exposed
        loops: Animation.Infinite
        PauseAnimation { duration: pauseColorAnimationTime ?? 0 }
        NumberAnimation {
            target: thiz
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
        running: enableColorGradientAnimation && (settings.cycleColor !== 3) && widget.NVG.View.exposed 
        loops: Animation.Infinite
        PauseAnimation { duration: pauseColorAnimationTime ?? 0 }
        NumberAnimation {
            target: thiz 
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
        
        // 对应原代码 defaultStops 里的逻辑:
        // position: 0.0 -> getColor(15)
        // position: 1.0 -> getColor(0)
        // 这里的 i 是 stopCache 的索引，从 0(pos 0.0) 到 15(pos 1.0)
        
        for (var i = 0; i < 16; i++) {
            var item = stopCache[i];
            if (item.qmlObject) {
                // 原逻辑是倒序映射: stop[0] 对应 getColor(15)
                item.qmlObject.color = getColor(15 - i);
            }
        }
    }
    // 渐变组件生成完成
//发光
    readonly property bool allowGlowTransparentBorder: settings.glowTransparentBorder ?? false
//遮罩
    readonly property var blendImage: settings.enableBlend ? settings.blendSource : ""
    readonly property var displaceImage: settings.enableDisplace ? settings.displacementSource : ""
    readonly property var opacityMaskImage: settings.enableOpacityMask ? settings.opacityMaskSource : ""
    readonly property var thresholdMaskImage: settings.enableThresholdMask ? settings.thresholdMaskSource : ""
//遮罩模糊
    readonly property var maskedBlurSource: settings.enableBmaskedBlurlend ? settings.maskedBlurMaskSource : ""
//扩展名称
    title: qsTranslate("utils", "Image Advanced")
//确定图片挂件的大小
    implicitWidth: imageSource.status ? imageSource.implicitWidth : 64
    implicitHeight: imageSource.status ? imageSource.implicitHeight : 64
//数据
    dataConfiguration: dataEnabled||blendDataEnabled||opacityMaskDataEnabled||thresholdMaskDataEnabled||displaceDataEnabled||blendMaskedBlurDataEnabled ? settings.data : undefined
//幻灯片
    readonly property bool enableGalleryMode: settings.enableGalleryMode ?? false
//
    preference: Page {
        id: page
        width: parent.width
        implicitHeight: switch(bar.currentIndex)
        {
                case 0: return preferencesLayoutBasic.height + 56;
                case 1: return preferencesLayoutColorSettings.height + 56;
                case 2: return preferencesLayoutEffects.height + 56;
                case 3: return preferencesLayoutBlend.height + 56;
                return 0;
        }
    //页面切换
        header:TabBar {
            id: bar
            width: parent.width
            //超出父项直接裁剪
            clip:true
            Repeater {
                model: [qsTr("Basic"),qsTr("Color"),qsTr("Effects"),qsTr("Blend")]
                TabButton {
                text: modelData
                width: Math.max(108, bar.width / 3)
                }
            }
        }
    //页面
        StackLayout {
            //anchors.centerIn: parent
            width: parent.width
            currentIndex: bar.currentIndex
        //基础设置
            Item{
                //必须资源
                id: basic
                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: preferencesLayoutBasic.height
                    topMargin: 16
                    bottomMargin: 16
                    Column {
                        id: preferencesLayoutBasic
                        width: parent.width
                
                        P.ObjectPreferenceGroup {
                            defaultValue: thiz.settings
                            syncProperties: true
                            enabled: currentItem
                            width: parent.width
                            //必须资源
                        //显示原图像
                            P.SwitchPreference {
                                id: showOriginal
                                name: "showOriginal"
                                label: qsTr("Show original image")
                                defaultValue: true
                            }
                            P.Separator{}
                        //打开幻灯片模式
                            P.ObjectPreferenceGroup {
                                defaultValue: thiz.settings
                                syncProperties: true
                                enabled: currentItem
                                width: parent.width
                                data: PreferenceGroupIndicator { anchors.topMargin: enableGalleryMode.height; visible: enableGalleryMode.value }
                                P.SwitchPreference {
                                    id: enableGalleryMode
                                    name: "enableGalleryMode"
                                    label: qsTr("Enable Gallery Mode")
                                    defaultValue: false
                                }
                                //图片目录
                                P.FolderPreference {
                                    name: "imageFolder"
                                    label: qsTr("Image Folder")
                                    visible: enableGalleryMode.value
                                }
                                // TODO 填充模式
                                P.SelectPreference {
                                    name: "galleryImageFillMode"
                                    label: qsTr("Gallery Image Fill Mode")
                                    model: [ qsTr("Crop"), qsTr("Fit") ]
                                    defaultValue: 0
                                    visible: enableGalleryMode.value
                                }
                                //背景颜色
                                P.ColorPreference {
                                    name: "fillColor"
                                    label: qsTr("Background Color")
                                    defaultValue: "transparent"
                                    visible: enableGalleryMode.value
                                }
                                //相框
                                P.BackgroundPreference {
                                    name: "frame"
                                    label: qsTr("Frame")
                                    preferableFilter: NVG.ResourceFilter {
                                        packagePattern: /com.gpbeta.media/
                                    }
                                    visible: enableGalleryMode.value
                                }
                                //相框在图片前
                                P.SwitchPreference {
                                    name: "framePosition"
                                    label: qsTr("Frame Above Image")
                                    defaultValue: true
                                    visible: enableGalleryMode.value
                                }
                                //随机播放
                                P.SwitchPreference {
                                    name: "shuffle"
                                    label: qsTr("Shuffle Playback")
                                    defaultValue: false
                                    onPreferenceEdited: Qt.callLater(thiz.imageUrlsChanged)
                                    visible: enableGalleryMode.value
                                }
                                //动画
                                P.SelectPreference {
                                    name: "transition"
                                    label: qsTr("Transition Animation")
                                    defaultValue: 0
                                    textRole: "label"
                                    model: {
                                        const array = [ { label: qsTr("Random"), source: "random" } ];
                                        for (const entry in Shared.gl_transitions) // label removes ".glsl"
                                            array.push({ label: entry.slice(0, -5), source: entry });
                                        return array;
                                    }
                                    load: function (newValue) {
                                        if (newValue === undefined) {
                                            value = defaultValue;
                                            return;
                                        }
                                        let index = defaultValue;
                                        for (let i = 0; i < model.length; ++i) {
                                            const item = model[i];
                                            if (item.source === newValue) {
                                                index = i;
                                                break;
                                            }
                                        }
                                        value = index;
                                    }
                                    save: function () {
                                        return model[value].source;
                                    }
                                    onPreferenceEdited: Qt.callLater(aniTransition.restart)
                                    visible: enableGalleryMode.value
                                }
                                //动画速度
                                P.SliderPreference {
                                    name: "animateTime"
                                    label: qsTr("Animation Speed")
                                    displayValue: value
                                    defaultValue: 500
                                    from: 0
                                    to: 9999
                                    stepSize: 1
                                    live: true
                                    onPreferenceEdited: Qt.callLater(aniTransition.restart)
                                    visible: enableGalleryMode.value
                                }
                                P.ObjectPreferenceGroup {
                                    defaultValue: thiz.settings
                                    syncProperties: true
                                    enabled: currentItem
                                    width: parent.width
                                    data: PreferenceGroupIndicator { anchors.topMargin: enableAutoPaly.height; visible: enableAutoPaly.value; color: "#662196f3"; anchors.leftMargin: 4 }
                                    P.SwitchPreference {
                                        id: enableAutoPaly
                                        name: "enableAutoPaly"
                                        label: qsTr("Enable Auto Paly")
                                        defaultValue: false
                                        visible: enableGalleryMode.value
                                    }
                                    //持续时间
                                    P.SelectPreference {
                                        name: "stillTime"
                                        label: qsTr("Change Image Every")
                                        model: [
                                            "10 " + qsTr("Millisecond"),
                                            "50 " + qsTr("Millisecond"),
                                            "100 " + qsTr("Millisecond"),
                                            "500 " + qsTr("Millisecond"),
                                            "1 " + qsTr("Second"),
                                            "5 " + qsTr("Seconds"),
                                            "15 " + qsTr("Seconds"),
                                            "30 " + qsTr("Seconds"),
                                            "1 " + qsTr("Minute"),
                                            "5 " + qsTr("Minutes"),
                                            "15 " + qsTr("Minutes"),
                                            "30 " + qsTr("Minutes"),
                                            "1 " + qsTr("Hour")
                                        ]
                                        defaultValue: 5
                                        load: function (newValue) {
                                            if (newValue === undefined) {
                                                value = defaultValue;
                                                return;
                                            }
                                            // remap times
                                            if (newValue <= 10)
                                                value = 0;
                                            else if (newValue <= 50)
                                                value = 1;
                                            else if (newValue <= 100)
                                                value = 2;
                                            else if (newValue <= 500)
                                                value = 3;
                                            else if (newValue <= 1000)
                                                value = 4;
                                            else if (newValue <= 1000 * 5)
                                                value = 5;
                                            else if (newValue <= 1000 * 15)
                                                value = 6;
                                            else if (newValue <= 1000 * 30)
                                                value = 7;
                                            else if (newValue <= 60000)
                                                value = 8;
                                            else if (newValue <= 60000 * 5)
                                                value = 9;
                                            else if (newValue <= 60000 * 15)
                                                value = 10;
                                            else if (newValue <= 60000 * 30)
                                                value = 11;
                                            else
                                                value = 12;
                                        }
                                        save: function () {
                                            switch (value) {
                                            case 0: return 10;
                                            case 1: return 50;
                                            case 2: return 100;
                                            case 3: return 500;
                                            case 4: return 1000;
                                            case 5: return 1000 * 5;
                                            case 6: return 1000 * 15;
                                            case 7: return 1000 * 30;
                                            case 8: return 60000;
                                            case 9: return 60000 * 5;
                                            case 10: return 60000 * 15;
                                            case 11: return 60000 * 30;
                                            case 12: return 60000 * 60;
                                            default: break;
                                            }
                                        }
                                        onPreferenceEdited: Qt.callLater(aniTransition.restart)
                                        visible: enableGalleryMode.value&&enableAutoPaly.value
                                    }
                                }
                                //点击事件 播放/暂停 播放 停止 下一张 上一张 刷新图库 无事发生
                                P.SelectPreference {
                                    name: "onClick"
                                    label: qsTr("On Click")
                                    model: [
                                        qsTr("Play / Pause"),
                                        qsTr("Play"),
                                        qsTr("Stop"),
                                        qsTr("Next Image"),
                                        qsTr("Previous Image"),
                                        qsTr("Refresh Gallery"),
                                        qsTr("None"),
                                    ]
                                    defaultValue: 0
                                    visible: enableGalleryMode.value&&(!settings.action||!enableAction.value)
                                }
                            }
                        //图片设置
                            P.Separator{}
                            P.ImagePreference {
                                name: "normal"
                                label: qsTr("Normal")
                                visible: !pMode.value
                            }
                            P.ImagePreference {
                                name: "hovered"
                                label: qsTr("Hovered")
                                visible: !pMode.value
                            }
                            P.ImagePreference {
                                name: "pressed"
                                label: qsTr("Pressed")
                                visible: !pMode.value
                            }
                            P.Separator{}
                        //填充模式
                            P.SelectPreference {
                                name: "fill"
                                label: qsTr("Fill Mode")
                                model: [ qsTr("Stretch"), qsTr("Fit"), qsTr("Crop"), qsTr("Tile"), qsTr("Tile Vertically"), qsTr("Tile Horizontally"), qsTr("Pad") ]
                                defaultValue: 1
                            }
                            //镜像
                            P.SwitchPreference {
                                name: "mirror"
                                label: qsTr("Mirror")
                            }
                            //平滑边缘
                            P.SwitchPreference {
                                name: "antialias"
                                label: qsTr("Smooth Edges")
                            }
                            //圆角
                            P.SliderPreference {
                                name: "radius"
                                label: qsTr("Border Radius")
                                displayValue: value <= 50 ? (value + " px") : (value - 50 + " %")
                                defaultValue: 0
                                from: 0
                                to: 150
                                stepSize: 1
                                live: true
                            }
                            P.Separator{}
                            //启用数据
                            P.SwitchPreference {
                                id: pMode
                                name: "mode"
                                label: qsTr("Enable Data Source")
                            }
                            //数据
                            P.DataPreference {
                                name: "data"
                                label: qsTr("Data")
                                //visible: pMode.value
                            }
                        }
                    }
                }
            }
        //颜色设置
            Item{
                //必须资源
                id: colorSettings
                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: preferencesLayoutColorSettings.height
                    topMargin: 16
                    bottomMargin: 16
                    Column {
                        id: preferencesLayoutColorSettings
                        width: parent.width
                        P.ObjectPreferenceGroup {
                            defaultValue: thiz.settings
                            syncProperties: true
                            enabled: currentItem
                            width: parent.width
                            //必须资源
                        //颜色
                        //颜色叠加
                            EffectPreferenceGroup {
                                id: colorOverlayGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "colorOverlay"
                                switchLabel: qsTr("Color Overlay")
                                NoDefaultColorPreference { name: "color"; label: qsTr("Color"); defaultValue: "transparent"; visible: colorOverlayGroup.switchValue }
                                NoDefaultColorPreference { name: "hoveredColor"; label: qsTr("Hovered Color"); defaultValue: "transparent"; visible: colorOverlayGroup.switchValue }
                                NoDefaultColorPreference { name: "pressedColor"; label: qsTr("Pressed Color"); defaultValue: "transparent"; visible: colorOverlayGroup.switchValue }
                            }
                        //亮度对比度 -1~1(/100)
                            EffectPreferenceGroup {
                                id: brightnessContrastGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "changeBrightnessContrast"
                                switchLabel: qsTr("Brightness Contrast")
                                EffectSliderPreference { owner: brightnessContrastGroup; name: "brightness"; label: qsTr("Brightness"); defaultValue: 0; from: -100; to: 100 }
                                EffectSliderPreference { owner: brightnessContrastGroup; name: "contrast"; label: qsTr("Contrast"); defaultValue: 0; from: -100; to: 100 }
                                EffectSwitchPreference { owner: brightnessContrastGroup; name: "brightnessContrastCached"; label: qsTr("Cached") }
                            }
                        //着色
                            EffectPreferenceGroup {
                                id: colorizeGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "colorize"
                                switchLabel: qsTr("Colorize")
                                EffectSliderPreference { owner: colorizeGroup; name: "colorizeHue"; label: qsTr("HUE"); defaultValue: 0; from: 0; to: 100 }
                                EffectSliderPreference { owner: colorizeGroup; name: "colorizeLightness"; label: qsTr("Lightness"); defaultValue: 0; from: -100; to: 100 }
                                EffectSliderPreference { owner: colorizeGroup; name: "colorizeSaturation"; label: qsTr("Saturation"); defaultValue: 100; from: 0; to: 100 }
                                EffectSwitchPreference { owner: colorizeGroup; name: "colorizeCached"; label: qsTr("Cached") }
                            }
                        //去饱和
                            EffectPreferenceGroup {
                                id: desaturateGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "desaturate"
                                switchLabel: qsTr("Desaturate")
                                EffectSliderPreference { owner: desaturateGroup; name: "desaturation"; label: qsTr("Desaturation"); defaultValue: 0; from: 0; to: 100 }
                                EffectSwitchPreference { owner: desaturateGroup; name: "desaturateCached"; label: qsTr("Cached") }
                            }
                        //伽马调节
                            EffectPreferenceGroup {
                                id: gammaAdjustGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "gammaAdjust"
                                switchLabel: qsTr("Gamma Adjust")
                                EffectSliderPreference { owner: gammaAdjustGroup; name: "gamma"; label: qsTr("Gamma"); defaultValue: 1000; from: 0; to: 100000 }
                                EffectSwitchPreference { owner: gammaAdjustGroup; name: "gammaCached"; label: qsTr("Cached") }
                            }
                        //色相饱和度
                            EffectPreferenceGroup {
                                id: hueSaturationGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "hueSaturation"
                                switchLabel: qsTr("Hue Saturation")
                                EffectSliderPreference { owner: hueSaturationGroup; name: "hueSaturationHue"; label: qsTr("HUE"); defaultValue: 0; from: -100; to: 100 }
                                EffectSliderPreference { owner: hueSaturationGroup; name: "hueSaturationLightness"; label: qsTr("Lightness"); defaultValue: 0; from: -100; to: 100 }
                                EffectSliderPreference { owner: hueSaturationGroup; name: "hueSaturationSaturation"; label: qsTr("Saturation"); defaultValue: 0; from: -100; to: 100 }
                                EffectSwitchPreference { owner: hueSaturationGroup; name: "hueSaturationCached"; label: qsTr("Cached") }
                            }
                        //电平调节
                            EffectPreferenceGroup {
                                id: levelAdjustGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
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
                        //颜色渐变
                            P.ObjectPreferenceGroup {
                                defaultValue: thiz.settings
                                syncProperties: true
                                enabled: currentItem
                                width: parent.width
                                data: PreferenceGroupIndicator { anchors.topMargin: colorGradient.height; visible: colorGradient.value }
                                //开启颜色渐变
                                P.SwitchPreference {
                                    id: colorGradient
                                    name: "colorGradient"
                                    label: qsTr("Color Gradient")
                                }
                                //渐变方向
                                P.ObjectPreferenceGroup {
                                    defaultValue: thiz.settings
                                    syncProperties: true
                                    enabled: currentItem
                                    width: parent.width
                                    data: PreferenceGroupIndicator { anchors.topMargin: animationDirect.height; visible: animationDirect.value; color: "#662196f3"; anchors.leftMargin: 4 }
                                    P.SelectPreference {
                                        id:animationDirect
                                        name: "animationDirect"
                                        label: qsTr("Animation Direct")
                                        //defaultValue: 0
                                        //TODO 去掉defaultvalue后需要重新选择才能显示动画?
                                        //从左到右,从下到上,从左上到右下,全部
                                        //旋转 4
                                        //中心 5
                                        //高级选项6 用于改变线性的start,end值
                                        model: [ qsTr("Horizontal"), qsTr("Vertical"), qsTr("Oblique"), qsTr("All"), qsTr("Center"), qsTr("Conical"),qsTr("Advanced")]
                                        visible: colorGradient.value
                                    }
                                    //高级设置 6
                                    //s.x x轴起始值
                                    // bug 要更新后才能使用
                                    P.SpinPreference {
                                        name: "animationAdvancedStartX"
                                        label: " --- --- " + qsTr("Start X")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: settings.animationDirect==6&&colorGradient.value
                                        defaultValue: 0
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //s.y y轴起始值
                                    P.SpinPreference {
                                        name: "animationAdvancedStartY"
                                        label: " --- --- " + qsTr("Start Y")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: settings.animationDirect==6&&colorGradient.value
                                        defaultValue: 0
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //e.x x轴结束值
                                    P.SpinPreference {
                                        name: "animationAdvancedEndX"
                                        label: " --- --- " + qsTr("End X")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: settings.animationDirect==6&&colorGradient.value
                                        defaultValue: 100
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //e.y y轴结束值
                                    P.SpinPreference {
                                        name: "animationAdvancedEndY"
                                        label: " --- --- " + qsTr("End Y")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: settings.animationDirect==6&&colorGradient.value
                                        defaultValue: 100
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //方向为4,5时提供的垂直水平角度选项,为4时提供水平/垂直半径
                                    //水平
                                    P.SpinPreference {
                                        name: "animationHorizontal"
                                        label: qsTr("Horizontal")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: (settings.animationDirect==4||settings.animationDirect==5)&&colorGradient.value
                                        defaultValue: 0
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //垂直
                                    P.SpinPreference {
                                        name: "animationVertical"
                                        label: qsTr("Vertical")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: (settings.animationDirect==4||settings.animationDirect==5)&&colorGradient.value
                                        defaultValue: 0
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //角度
                                    P.SpinPreference {
                                        name: "animationAngle"
                                        label: qsTr("Angle")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: (settings.animationDirect==4||settings.animationDirect==5)&&colorGradient.value
                                        defaultValue: 0
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //水平半径 4
                                    P.SpinPreference {
                                        name: "animationHorizontalRadius"
                                        label: qsTr("Horizontal Radius")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: settings.animationDirect==4&&colorGradient.value
                                        defaultValue: 50
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                    //垂直半径 4
                                    P.SpinPreference {
                                        name: "animationVerticalRadius"
                                        label: qsTr("Vertical Radius")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: settings.animationDirect==4&&colorGradient.value
                                        defaultValue: 50
                                        from: -10000
                                        to: 10000
                                        stepSize: 5
                                    }
                                }
                                //渐变颜色
                                P.ObjectPreferenceGroup {
                                    defaultValue: thiz.settings
                                    syncProperties: true
                                    enabled: currentItem
                                    width: parent.width
                                    data: PreferenceGroupIndicator { anchors.topMargin: cycleColor.height; visible: cycleColor.value; color: "#662196f3"; anchors.leftMargin: 4 }
                                    P.SelectPreference {
                                        id:cycleColor
                                        name: "cycleColor"
                                        label: qsTr("Cycle Color")
                                        defaultValue: 0
                                        //彩虹
                                        model: [ qsTr("Rainbow") ,qsTr("Custom")+"Ⅰ", qsTr("Custom")+"Ⅱ", qsTr("Custom")+"Ⅲ"]
                                        visible: colorGradient.value
                                    }
                                    //自定义颜色 1
                                    //开始颜色
                                    P.SpinPreference {
                                        name: "cycleColorCustomStart"
                                        label: qsTr("Color Start")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: colorGradient.value&&settings.cycleColor==1
                                        defaultValue: 0
                                        from: -5000
                                        to: 5000
                                        stepSize: 16
                                    }
                                    //结束颜色
                                    P.SpinPreference {
                                        name: "cycleColorCustomEnd"
                                        label: qsTr("Color End")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: colorGradient.value&&settings.cycleColor==1
                                        defaultValue: 160
                                        from: -5000
                                        to: 5000
                                        stepSize: 16
                                    }
                                    //自定义颜色 2
                                    Row{
                                        spacing: 4
                                        visible: colorGradient.value&&settings.cycleColor==2
                                        Column {
                                            Label {
                                                text: qsTr("00~05")
                                                anchors.right: parent.right
                                                anchors.rightMargin: 12
                                            }
                                            P.ObjectPreferenceGroup {
                                                syncProperties: true
                                                enabled: currentItem
                                                defaultValue: thiz.settings
                                                NoDefaultColorPreference {
                                                    name: "cycleColor0"
                                                    defaultValue: colorInit(0)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor1"
                                                    defaultValue: colorInit(1)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor2"
                                                    defaultValue: colorInit(2)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor3"
                                                    defaultValue: colorInit(3)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor4"
                                                    defaultValue: colorInit(4)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor5"
                                                    defaultValue: colorInit(5)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                            }
                                        }
                                        Column {
                                            Label {
                                                text: qsTr("06~10")
                                                anchors.right: parent.right
                                                anchors.rightMargin: 12
                                            }
                                            P.ObjectPreferenceGroup {
                                                syncProperties: true
                                                enabled: currentItem
                                                defaultValue: thiz.settings
                                                NoDefaultColorPreference {
                                                    name: "cycleColor6"
                                                    defaultValue: colorInit(6)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor7"
                                                    defaultValue: colorInit(7)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor8"
                                                    defaultValue: colorInit(8)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor9"
                                                    defaultValue: colorInit(9)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor10"
                                                    defaultValue: colorInit(10)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                            }
                                        }
                                        Column {
                                            Label {
                                                text: qsTr("11~15")
                                                anchors.right: parent.right
                                                anchors.rightMargin: 12
                                            }
                                            P.ObjectPreferenceGroup {
                                                syncProperties: true
                                                enabled: currentItem
                                                defaultValue: thiz.settings
                                                NoDefaultColorPreference {
                                                    name: "cycleColor11"
                                                    defaultValue: colorInit(11)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor12"
                                                    defaultValue: colorInit(12)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor13"
                                                    defaultValue: colorInit(13)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor14"
                                                    defaultValue: colorInit(14)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                                NoDefaultColorPreference {
                                                    name: "cycleColor15"
                                                    defaultValue: colorInit(15)
                                                    visible: colorGradient.value&&settings.cycleColor==2
                                                }
                                            }
                                        }
                                    }
                                    //自定义颜色3
                                    GradientPreference {
                                        name: "fillStops"
                                        label: qsTr("Fill Gradient")
                                        defaultValue: defaultFillStops
                                        visible: colorGradient.value&&settings.cycleColor==3
                                    }
                                }
                                //饱和度
                                P.SpinPreference {
                                    name: "cycleSaturation"
                                    label: qsTr("Saturation")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: colorGradient.value&&settings.cycleColor!=2&&settings.cycleColor!=3
                                    defaultValue: 100
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                }
                                //亮度
                                P.SpinPreference {
                                    name: "cycleValue"
                                    label: qsTr("Value")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: colorGradient.value&&settings.cycleColor!=2&&settings.cycleColor!=3
                                    defaultValue: 100
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                }
                                //透明度
                                P.SpinPreference {
                                    name: "cycleOpacity"
                                    label: qsTr("Opacity")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: colorGradient.value&&settings.cycleColor!=2&&settings.cycleColor!=3
                                    defaultValue: 100
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                }
                                //渐变动画
                                P.ObjectPreferenceGroup {
                                    defaultValue: thiz.settings
                                    syncProperties: true
                                    enabled: currentItem
                                    width: parent.width
                                    data: PreferenceGroupIndicator { anchors.topMargin: enableColorAnimation.height; visible: enableColorAnimation.value; color: "#662196f3"; anchors.leftMargin: 4 }
                                    P.SwitchPreference {
                                        id: enableColorAnimation
                                        name: "enableColorAnimation"
                                        label: qsTr("Color Animation")
                                        visible: colorGradient.value
                                    }
                                    //循环时间
                                    P.SpinPreference {
                                        name: "cycleTime"
                                        label: qsTr("Cycle Time")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: enableColorAnimation.value&&colorGradient.value
                                        defaultValue: 500
                                        from: 0
                                        to: 50000
                                        stepSize: 100
                                    }
                                    P.SpinPreference {
                                        name: "pauseColorAnimationTime"
                                        label: qsTr("Pause Time")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: enableColorAnimation.value&&colorGradient.value
                                        defaultValue: 0
                                        from: 0
                                        to: 10000
                                        stepSize: 100
                                    }
                                    //渐变开始值
                                    P.SpinPreference {
                                        name: "cycleColorFrom"
                                        label: qsTr("Color From")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: enableColorAnimation.value&&colorGradient.value&&settings.cycleColor!=3
                                        defaultValue: 0
                                        from: 0
                                        to: 10000
                                        stepSize: 1
                                    }
                                    //渐变结束值
                                    P.SpinPreference {
                                        name: "cycleColorTo"
                                        label: qsTr("Color To")
                                        editable: true
                                        display: P.TextFieldPreference.ExpandLabel
                                        visible: enableColorAnimation.value&&colorGradient.value&&settings.cycleColor!=3
                                        defaultValue: 15
                                        from: 0
                                        to: 10000
                                        stepSize: 1
                                    }
                                }
                                //是否缓存
                                P.SwitchPreference {
                                    name: "enableColorAnimationCached"
                                    label: qsTr("Cached")
                                    visible: colorGradient.value
                                }
                                //TODO渐变次数
                            }
                        }
                    }
                }
            }
        //效果设置
            Item {
                //必须资源
                id: effects
                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: preferencesLayoutEffects.height
                    topMargin: 16
                    bottomMargin: 16
                    Column {
                        id: preferencesLayoutEffects
                        width: parent.width
                
                        P.ObjectPreferenceGroup {
                            defaultValue: thiz.settings
                            syncProperties: true
                            enabled: currentItem
                            width: parent.width
                            //必须资源
                        //模糊
                            //快速模糊
                            EffectPreferenceGroup {
                                id: fastBlurGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "fastBlur"
                                switchLabel: qsTr("Fast Blur")
                                EffectSpinPreference { owner: fastBlurGroup; name: "fastBlurRadius"; label: qsTr("Radius"); defaultValue: 5; from: 0; to: 500 }
                                EffectSwitchPreference { owner: fastBlurGroup; name: "fastBlurTransparentBorder"; label: qsTr("Transparent Border") }
                                EffectSwitchPreference { owner: fastBlurGroup; name: "fastBlurCached"; label: qsTr("Cached") }
                            }
                            //高斯模糊
                            EffectPreferenceGroup {
                                id: gaussianBlurGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "gaussianBlur"
                                switchLabel: qsTr("Gaussian Blur")
                                EffectSpinPreference { owner: gaussianBlurGroup; name: "gaussianBlurRadius"; label: qsTr("Radius"); defaultValue: 5; from: 0; to: 500 }
                                EffectSpinPreference { owner: gaussianBlurGroup; name: "gaussianBlurDeviation"; label: qsTr("Deviation"); defaultValue: 3; from: 0; to: 1000 }
                                EffectSpinPreference { owner: gaussianBlurGroup; name: "gaussianBlurSamples"; label: qsTr("Samples"); defaultValue: 5; from: 0; to: 100 }
                                // [修复] 原误写为 dropShadowTransparentBorder，与外阴影键相撞
                                EffectSwitchPreference { owner: gaussianBlurGroup; name: "gaussianBlurTransparentBorder"; label: qsTr("Transparent Border") }
                                EffectSwitchPreference { owner: gaussianBlurGroup; name: "gaussianBlurCached"; label: qsTr("Cached") }
                            }
                            //蒙版模糊
                            EffectPreferenceGroup {
                                id: maskedBlurGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "maskedBlur"
                                switchLabel: qsTr("Masked Blur")
                                //遮罩图片
                                P.ImagePreference {
                                    name: "maskedBlurMaskSource"
                                    label: qsTr("Mask Source")
                                    visible: maskedBlurGroup.switchValue && !blendMaskedBlurDataEnabled.value
                                }
                                EffectSpinPreference { owner: maskedBlurGroup; name: "maskedBlurRadius"; label: qsTr("Radius"); defaultValue: 0; from: 0; to: 100 }
                                EffectSpinPreference { owner: maskedBlurGroup; name: "maskedBlurSamples"; label: qsTr("Samples"); defaultValue: 9; from: 0; to: 100 }
                                //启用数据源
                                EffectSwitchPreference {
                                    id: blendMaskedBlurDataEnabled
                                    owner: maskedBlurGroup
                                    name: "blendDataEnabled"
                                    label: qsTr("Enable Data Source")
                                }
                                EffectSwitchPreference { owner: maskedBlurGroup; name: "maskedBlurCached"; label: qsTr("Cached") }
                            }
                            //递归模糊
                            EffectPreferenceGroup {
                                id: recursiveBlurGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "recursiveBlur"
                                switchLabel: qsTr("Recursive Blur")
                                EffectSpinPreference { owner: recursiveBlurGroup; name: "recursiveBlurRadius"; label: qsTr("Radius"); defaultValue: 0; from: 0; to: 160 }
                                EffectSpinPreference { owner: recursiveBlurGroup; name: "recursiveBlurLoops"; label: qsTr("Loops"); defaultValue: 0; from: 0; to: 10000 }
                                EffectSpinPreference { owner: recursiveBlurGroup; name: "recursiveBlurProgress"; label: qsTr("Progress"); defaultValue: 1; from: 0; to: 100 }
                                EffectSwitchPreference { owner: recursiveBlurGroup; name: "recursiveBlurTransparentBorder"; label: qsTr("Transparent Border") }
                                EffectSwitchPreference { owner: recursiveBlurGroup; name: "recursiveBlurCached"; label: qsTr("Cached") }
                            }
                            P.Separator{}
                        //动态模糊
                            //方向模糊
                            EffectPreferenceGroup {
                                id: directionalBlurGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "directionalBlur"
                                switchLabel: qsTr("Directional Blur")
                                EffectSpinPreference { owner: directionalBlurGroup; name: "directionalBlurLength"; label: qsTr("Length"); defaultValue: 0; from: 0; to: 1000 }
                                EffectSpinPreference { owner: directionalBlurGroup; name: "directionalBlurAngle"; label: qsTr("Angle"); defaultValue: 0; from: -180; to: 180 }
                                EffectSpinPreference { owner: directionalBlurGroup; name: "directionalBlurSamples"; label: qsTr("Samples"); defaultValue: 0; from: 0; to: 250 }
                                EffectSwitchPreference { owner: directionalBlurGroup; name: "directionalBlurTransparentBorder"; label: qsTr("Transparent Border") }
                                EffectSwitchPreference { owner: directionalBlurGroup; name: "directionalBlurCached"; label: qsTr("Cached") }
                            }
                            //径向模糊
                            EffectPreferenceGroup {
                                id: radialBlurGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
                                switchName: "radialBlur"
                                switchLabel: qsTr("Radial Blur")
                                EffectSpinPreference { owner: radialBlurGroup; name: "radialBlurHorizontalOffset"; label: qsTr("Horizontal Offset"); defaultValue: 0; from: 0; to: 1000 }
                                EffectSpinPreference { owner: radialBlurGroup; name: "radialBlurVerticalOffset"; label: qsTr("Vertical Offset"); defaultValue: 0; from: 0; to: 1000 }
                                EffectSpinPreference { owner: radialBlurGroup; name: "radialBlurAngle"; label: qsTr("Angle"); defaultValue: 0; from: 0; to: 360 }
                                EffectSpinPreference { owner: radialBlurGroup; name: "radialBlurSamples"; label: qsTr("Samples"); defaultValue: 0; from: 0; to: 250 }
                                EffectSwitchPreference { owner: radialBlurGroup; name: "radialBlurTransparentBorder"; label: qsTr("Transparent Border") }
                                EffectSwitchPreference { owner: radialBlurGroup; name: "radialBlurCached"; label: qsTr("Cached") }
                            }
                            //缩放模糊
                            EffectPreferenceGroup {
                                id: zoomBlurGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
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
                        //阴影
                            //外阴影
                            EffectPreferenceGroup {
                                id: dropShadowGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
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
                            //内阴影
                            EffectPreferenceGroup {
                                id: innerShadowGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
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
                        //发光效果
                            EffectPreferenceGroup {
                                id: glowGroup
                                settingsTarget: thiz.settings
                                groupEnabled: currentItem
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
                }
            }
        //遮罩和取代
            Item {
                //必须资源
                id: blend
                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: preferencesLayoutBlend.height
                    topMargin: 16
                    bottomMargin: 16
                    Column {
                        id: preferencesLayoutBlend
                        width: parent.width
                        P.ObjectPreferenceGroup {
                            defaultValue: thiz.settings
                            syncProperties: true
                            enabled: currentItem
                            width: parent.width
                            //必须资源
                        //遮罩
                            P.ObjectPreferenceGroup {
                                defaultValue: thiz.settings
                                syncProperties: true
                                enabled: currentItem
                                width: parent.width
                                data: PreferenceGroupIndicator { anchors.topMargin: enableBlend.height; visible: enableBlend.value }
                                P.SwitchPreference {
                                    id: enableBlend
                                    name: "enableBlend"
                                    label: qsTr("Blend")
                                }
                                //遮罩图像
                                P.ImagePreference {
                                    name: "blendSource"
                                    label: qsTr("Blend Image")
                                    visible: enableBlend.value&&!blendDataEnabled.value
                                }
                                //模式
                                P.SelectPreference {
                                    name: "blendMode"
                                    label: qsTr("Mode")
                                    defaultValue: 0
                                    model: [ qsTr("normal"), qsTr("addition"), qsTr("average"), qsTr("color"), qsTr("colorBurn"), qsTr("colorDodge"),qsTr("darken"),qsTr("darkerColor"),qsTr("difference"),qsTr("divide"),qsTr("exclusion"),qsTr("hardLight"),qsTr("hue"),qsTr("lighten"),qsTr("lighterColor"),qsTr("lightness"),qsTr("multiply"),qsTr("negation"),qsTr("saturation"),qsTr("screen"),qsTr("subtract"),qsTr("softLight")]
                                    visible: enableBlend.value
                                }
                                //启用数据源
                                P.SwitchPreference {
                                    id: blendDataEnabled
                                    name: "blendDataEnabled"
                                    label: qsTr("Enable Data Source")
                                    visible: enableBlend.value
                                }
                                //缓存
                                P.SwitchPreference {
                                    name: "enableBlendCached"
                                    label: qsTr("Cached")
                                    visible: enableBlend.value
                                }
                            }
                        //不透明遮罩
                            P.ObjectPreferenceGroup {
                                defaultValue: thiz.settings
                                syncProperties: true
                                enabled: currentItem
                                width: parent.width
                                data: PreferenceGroupIndicator { anchors.topMargin: enableOpacityMask.height; visible: enableOpacityMask.value }
                                P.SwitchPreference {
                                    id: enableOpacityMask
                                    name: "enableOpacityMask"
                                    label: qsTr("Opacity Mask")
                                }
                                //遮罩图像
                                P.ImagePreference {
                                    name: "opacityMaskSource"
                                    label: qsTr("Opacity Mask Image")
                                    visible: enableOpacityMask.value&&!opacityMaskDataEnabled.value
                                }
                                //反转
                                P.SwitchPreference {
                                    name: "opacityMaskInvert"
                                    label: qsTr("Invert")
                                    visible: enableOpacityMask.value
                                }
                                //启用数据源
                                P.SwitchPreference {
                                    id: opacityMaskDataEnabled
                                    name: "opacityMaskDataEnabled"
                                    label: qsTr("Enable Data Source")
                                    visible: enableOpacityMask.value
                                }
                                //缓存
                                P.SwitchPreference {
                                    name: "enableOpacityMaskCached"
                                    label: qsTr("Cached")
                                    visible: enableOpacityMask.value
                                }
                            }
                        //阈值遮罩
                            P.ObjectPreferenceGroup {
                                defaultValue: thiz.settings
                                syncProperties: true
                                enabled: currentItem
                                width: parent.width
                                data: PreferenceGroupIndicator { anchors.topMargin: enableThresholdMask.height; visible: enableThresholdMask.value }
                                P.SwitchPreference {
                                    id: enableThresholdMask
                                    name: "enableThresholdMask"
                                    label: qsTr("Threshold Mask")
                                }
                                //遮罩图像
                                P.ImagePreference {
                                    name: "thresholdMaskSource"
                                    label: qsTr("Threshold Mask Image")
                                    visible: enableThresholdMask.value&&!thresholdMaskDataEnabled.value
                                }
                                //强度(0~1)
                                P.SpinPreference {
                                    name: "thresholdMaskSpread"
                                    label: qsTr("Spread")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableThresholdMask.value
                                    defaultValue: 50
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                }
                                //阔值(0~1)
                                P.SpinPreference {
                                    name: "thresholdMaskSourceThreshold"
                                    label: qsTr("Threshold")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableThresholdMask.value
                                    defaultValue: 50
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                }
                                //启用数据源
                                P.SwitchPreference {
                                    id: thresholdMaskDataEnabled
                                    name: "thresholdMaskDataEnabled"
                                    label: qsTr("Enable Data Source")
                                    visible: enableThresholdMask.value
                                }
                                //缓存
                                P.SwitchPreference {
                                    name: "enableThresholdMaskCached"
                                    label: qsTr("Cached")
                                    visible: enableThresholdMask.value
                                }
                            }
                            P.Separator{}
                        //取代
                            P.ObjectPreferenceGroup {
                                defaultValue: thiz.settings
                                syncProperties: true
                                enabled: currentItem
                                width: parent.width
                                data: PreferenceGroupIndicator { anchors.topMargin: enableDisplace.height; visible: enableDisplace.value }
                                P.SwitchPreference {
                                    id: enableDisplace
                                    name: "enableDisplace"
                                    label: qsTr("Displace")
                                }
                                //取代图像
                                P.ImagePreference {
                                    name: "displacementSource"
                                    label: qsTr("Displace Image")
                                    visible: enableDisplace.value&&!displaceDataEnabled.value
                                }
                                //取代位移
                                P.SliderPreference {
                                    name: "displacement"
                                    label: qsTr("Displacement")
                                    visible:enableDisplace.value
                                    displayValue: value*100
                                    defaultValue: 0
                                    from: -1
                                    to: 1
                                    stepSize: 0.01
                                    live: true
                                }
                                //启用数据源
                                P.SwitchPreference {
                                    id: displaceDataEnabled
                                    name: "displaceDataEnabled"
                                    label: qsTr("Enable Data Source")
                                    visible: enableDisplace.value
                                }
                                //缓存
                                P.SwitchPreference {
                                    name: "enableDisplaceCached"
                                    label: qsTr("Cached")
                                    visible: enableDisplace.value
                                }
                            }
                        }
                    }
                }
            }
        }
    }
//
    NVG.ImageSource {
        id: imageSource
        anchors.fill: parent
        visible:Boolean(settings.showOriginal ?? true)&&!(settings.enableBlend&&settings.enableOpacityMask&&settings.enableThresholdMask&&settings.enableDisplace&&settings.colorOverlay)
        //TODO 镜像，其他源并不会开
        mirror : mirrorEnabled ?? false
        //平滑边缘
        antialiasing: thiz.settings.antialias ?? false
        fillMode: thiz.settings.fill ?? Image.PreserveAspectFit
        //透明度
        opacity: settings.enableOpacity ? settings.opacity/100 : 1
        playing: status === Image.Ready
        configuration: {
            if (dataEnabled)//启用数据源
                return output.result;
            if (thiz.itemPressed)
                return pressedImage;
            if (thiz.itemHovered)
                return hoveredImage;
            return normalImage;
        }
    }
//圆角
    // simple OpacityMask implementation
        layer.enabled: thiz.settings.radius ?? false
        layer.smooth: true
        layer.effect: ShaderEffect {
            property var maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: imageSource.width
                    height: imageSource.height
                    // adaptive radius unit
                    radius: thiz.settings.radius <= 50 ? thiz.settings.radius :
                                Math.min(width, height) * 0.005 * (thiz.settings.radius - 50)
                }
            }
            fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform highp float qt_Opacity;
            uniform lowp sampler2D source;
            uniform lowp sampler2D maskSource;
            void main(void) {
            gl_FragColor = texture2D(source, qt_TexCoord0.st) * (texture2D(maskSource, qt_TexCoord0.st).a) * qt_Opacity;
            }
            "
        }
//图形特效叠加层（已迁出至 ImageEffectStack.qml）
    ImageEffectStack {
        sourceItem: imageSource
        settings: thiz.settings
        dataSource: thiz.dataSource
        itemPressed: thiz.itemPressed
        itemHovered: thiz.itemHovered
        gradient: dynamicGradient
    }
//数据源
    NVG.DataSourceRawOutput {
        id: output
        source: dataEnabled ? thiz.dataSource : null
    }

//幻灯片部分
    readonly property string transitionType: settings.transition ?? "random"
    readonly property var imageUrls : {
        galleryfreshHelper;

        const path = settings.imageFolder;
        if(!settings.enableGalleryMode)
            return [];
        if (!path)
            return [ "../../Images/gallery-widget.png",
                     "../../Images/image-widget.png",
                     "../../Images/video-widget.png" ];

        const qDir = QtDir.construct();
        const basePath = NVG.Url.toLocalFile(Qt.resolvedUrl(path)); // handle UNC paths
        const baseUrl = (basePath.startsWith('/') ? "file://" : "file:///") + basePath;
        qDir.setPath(basePath);
        const entries = qDir.entryList(["*.jpg", "*.jpeg", "*.png", "*.webp"],
                                      QtDir.Files | QtDir.NoDotAndDotDot);
        return entries.map(function (entry) {
            return baseUrl + '/' + entry;
        });
    }
    readonly property var sampleSize: {
        if (frame.sizing)
            return undefined;

        const size = Math.max(shaderEffect.width, shaderEffect.height);
        return Qt.size(size, size);
    }
    readonly property Image fromImage: Image {
        fillMode: Image.PreserveAspectCrop
        sourceSize: sampleSize
        asynchronous: true
    }
    readonly property Image toImage: Image {
        fillMode: Image.PreserveAspectCrop
        sourceSize: sampleSize
        asynchronous: true
    }
    property bool playing: true
    property var imageFiles: []
    property int currentIndex: 0
    property bool galleryfreshHelper


    function startImageTransition() {
        const fromS = shaderEffect._fromS;
        shaderEffect._fromS = shaderEffect._toS;
        shaderEffect._toS = fromS;
        shaderEffect.progress = 0;

        if (imageFiles.length)
            fromS.source = imageFiles[currentIndex];
        else
            fromS.source = "";

        if (transitionType === "random")
            shaderEffect._transition = Math.floor(Math.random() * Shared.gl_transitions_count);

        if (fromS.status === Image.Loading)
            imageLoadConnections.target = fromS;
        else
            aniTransition.start();
    }
    function showNextImage() {
        if (++currentIndex >= imageFiles.length) currentIndex = 0;

        startImageTransition();
    }
    function showPrevImage() {
        if (--currentIndex < 0) currentIndex = imageFiles.length - 1;

        startImageTransition();
    }
    function playSlideshow() {
        playing = true;

        if (aniTransition.running)
            return;

        showNextImage();
    }
    function stopSlideshow() {
        playing = false;
        currentIndex = 0;

        if (aniTransition.running) {
            shaderEffect.progress = 1.0;
            aniTransition.stop();
        }
    }
    function toggleSlideshow() {
        if (aniTransition.running) {
            shaderEffect.progress = 1.0;
            aniTransition.stop();
            playing = false;
        } else {
            playing = true;
            showNextImage();
        }
    }
    function rollImage(forward) {
        if (imageFiles.length < 2)
            return;

        if (aniTransition.running) {
            shaderEffect.progress = 1.0;
            aniTransition.stop();
        }

        if (forward)
            showNextImage();
        else
            showPrevImage();
    }
    function refreshGallery() {
        galleryfreshHelper = !galleryfreshHelper;
    }

    onImageUrlsChanged: {
        if (aniTransition.running) {
            shaderEffect.progress = 1.0;
            aniTransition.stop();
        }

        if (settings.shuffle) {
            // shuffle array elements
            imageFiles = imageUrls.slice();
            for (let i = imageFiles.length - 1; i > 0; --i) {
                const j = Math.floor(Math.random() * (i + 1));
                const temp = imageFiles[i];
                imageFiles[i] = imageFiles[j];
                imageFiles[j] = temp;
            }
        } else {
            imageFiles = imageUrls;
        }

        currentIndex = 0;
        startImageTransition();
    }
    Connections {
        id: imageLoadConnections
        enabled: widget.NVG.View.exposed
        ignoreUnknownSignals: true
        onStatusChanged: {
            if (target.status === Image.Ready || target.status === Image.Error)
                aniTransition.start();
        }
    }
    SequentialAnimation {
        id: aniTransition
        running: imageLoadConnections.enabled

        onFinished: {
            // if (!widget.playing || imageFiles.length < 2)
            //     return;
            if (!settings.enableAutoPaly)//点击播放下一张
                return;
            showNextImage();
        }

        NumberAnimation {
            target: shaderEffect
            property: "progress"
            duration: settings.animateTime ?? 1000
            from: 0
            to: 1
        }

        PauseAnimation { duration: settings.stillTime ?? 5000 }
    }
    MouseArea {
        anchors.fill: settings.enableAction||settings.enableGalleryMode ? parent : undefined

        onClicked: {
            //选择了动作
            if (settings.action&&settings.enableAction) {
                actionSource.trigger(this);
                return;
            }
            //设置了点击事件
            switch(settings.onClick) {
                case 0: toggleSlideshow();return;
                case 1: playSlideshow();return;
                case 2: stopSlideshow();return;
                case 3: rollImage(true);return;
                case 4: rollImage(false);return;
                case 5: refreshGallery();return;
                case 6: return;
                return;
            }

            toggleSlideshow();
        }

        onWheel: rollImage(wheel.angleDelta.y < 0)

        Rectangle {
            anchors {
                fill: parent
                leftMargin: frameBackground.leftPadding
                rightMargin: frameBackground.rightPadding
                topMargin: frameBackground.topPadding
                bottomMargin: frameBackground.bottomPadding
            }

            color: settings.fillColor ?? "transparent"

            ShaderEffect {
                id: shaderEffect
                anchors.fill: settings.enableGalleryMode ? parent : undefined
                property Image _fromS: fromImage
                readonly property real _fromR: _fromS.implicitWidth / _fromS.implicitHeight
                property Image _toS: toImage
                readonly property real _toR: _toS.implicitWidth / _toS.implicitHeight
                property int _transition: 0
                property real progress: 0
                property real ratio: width / height
                fragmentShader: Shared.generateShader(transitionType, settings.galleryImageFillMode === 1)
            }
        }
        NVG.BackgroundSource {
            id: frameBackground
            anchors.fill: settings.enableGalleryMode ? parent : undefined
            configuration: settings.frame
            z: (settings.framePosition ?? true) ? 1 : -1
        }
        NVG.ActionSource {
            id: actionSource
            configuration: settings.action
        }
    }
}