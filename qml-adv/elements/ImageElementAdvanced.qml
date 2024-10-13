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
                        //打开幻灯片模式
                            P.SwitchPreference {
                                id: enableGalleryMode
                                name: "enableGalleryMode"
                                label: qsTr("Enable Gallery Mode")
                                defaultValue: false
                            }
                            //图片目录
                            P.FolderPreference {
                                name: "imageFolder"
                                label: " --- " + qsTr("Image Folder")
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
                                label: " --- " + qsTr("Background Color")
                                defaultValue: "transparent"
                                visible: enableGalleryMode.value
                            }
                            //相框
                            P.BackgroundPreference {
                                name: "frame"
                                label: " --- " + qsTr("Frame")
                                preferableFilter: NVG.ResourceFilter {
                                    packagePattern: /com.gpbeta.media/
                                }
                                visible: enableGalleryMode.value
                            }
                            //相框在图片前
                            P.SwitchPreference {
                                name: "framePosition"
                                label: " --- " + qsTr("Frame Above Image")
                                defaultValue: true
                                visible: enableGalleryMode.value
                            }
                            //随机播放
                            P.SwitchPreference {
                                name: "shuffle"
                                label: " --- " + qsTr("Shuffle Playback")
                                defaultValue: false
                                onPreferenceEdited: Qt.callLater(thiz.imageUrlsChanged)
                                visible: enableGalleryMode.value
                            }
                            //动画
                            P.SelectPreference {
                                name: "transition"
                                label: " --- " + qsTr("Transition Animation")
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
                                label: " --- " + qsTr("Animation Speed")
                                displayValue: value
                                defaultValue: 500
                                from: 0
                                to: 9999
                                stepSize: 1
                                live: true
                                onPreferenceEdited: Qt.callLater(aniTransition.restart)
                                visible: enableGalleryMode.value
                            }
                            P.SwitchPreference {
                                id: enableAutoPaly
                                name: "enableAutoPaly"
                                label: " --- " + qsTr("Enable Auto Paly")
                                defaultValue: false
                                visible: enableGalleryMode.value
                            }
                            //持续时间
                            P.SelectPreference {
                                name: "stillTime"
                                label: " --- --- " + qsTr("Change Image Every")
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
                            //点击事件 播放/暂停 播放 停止 下一张 上一张 刷新图库 无事发生
                            P.SelectPreference {
                                name: "onClick"
                                label: " --- " + qsTr("On Click")
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
                        //图片设置
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
                            P.SwitchPreference {
                                id: colorOverlay
                                name: "colorOverlay"
                                label: qsTr("Color Overlay")
                                // visible: !(changeBrightnessContrast.value || colorize.value || desaturate.value || gammaAdjust.value || hueSaturation.value || levelAdjust.value)
                            }
                            NoDefaultColorPreference {
                                name: "color"
                                label: " --- " + qsTr("Color")
                                defaultValue: "transparent"
                                visible:colorOverlay.value
                            }
                            //悬停
                            NoDefaultColorPreference {
                                name: "hoveredColor"
                                label: " --- " + qsTr("Hovered Color")
                                defaultValue: "transparent"
                                visible:colorOverlay.value
                            }
                            //按下
                            NoDefaultColorPreference {
                                name: "pressedColor"
                                label: " --- " + qsTr("Pressed Color")
                                defaultValue: "transparent"
                                visible:colorOverlay.value
                            }
                        //亮度对比度 -1~1(/100)
                            //开关
                            P.SwitchPreference {
                                id: changeBrightnessContrast
                                name: "changeBrightnessContrast"
                                label: qsTr("Brightness Contrast")
                                //visible: !(colorOverlay.value || colorize.value || desaturate.value || gammaAdjust.value || hueSaturation.value || levelAdjust.value)
                            }
                            P.SliderPreference {
                                name: "brightness"
                                label: " --- " + qsTr("Brightness")
                                visible:changeBrightnessContrast.value
                                displayValue: value
                                defaultValue: 0
                                from: -100
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            P.SliderPreference {
                                name: "contrast"
                                label: " --- " + qsTr("Contrast")
                                visible:changeBrightnessContrast.value
                                displayValue: value
                                defaultValue: 0
                                from: -100
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            P.SwitchPreference {
                                visible:changeBrightnessContrast.value
                                name: "brightnessContrastCached"
                                label: " --- " + qsTr("Cached")
                            }
                        //着色
                            P.SwitchPreference {
                                id: colorize 
                                name: "colorize"
                                label: qsTr("Colorize")
                                //visible: !(colorOverlay.value || changeBrightnessContrast.value || desaturate.value || gammaAdjust.value || hueSaturation.value || levelAdjust.value)
                            }
                            //色调 /100
                            P.SliderPreference {
                                name: "colorizeHue"
                                label: " --- " + qsTr("HUE")
                                visible:colorize.value
                                displayValue: value
                                defaultValue: 0
                                from: 0
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            //亮度 /100
                            P.SliderPreference {
                                name: "colorizeLightness"
                                label: " --- " + qsTr("Lightness")
                                visible:colorize.value
                                displayValue: value
                                defaultValue: 0
                                from: -100
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            //饱和度 /100
                            P.SliderPreference {
                                name: "colorizeSaturation"
                                label: " --- " + qsTr("Saturation")
                                visible:colorize.value
                                displayValue: value
                                defaultValue: 100
                                from: 0
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            P.SwitchPreference {
                                visible:colorize.value
                                name: "colorizeCached"
                                label: " --- " + qsTr("Cached")
                            }
                        //去饱和
                            P.SwitchPreference {
                                id: desaturate 
                                name: "desaturate"
                                label: qsTr("Desaturate")
                                //visible: !(colorOverlay.value || changeBrightnessContrast.value || colorize.value || gammaAdjust.value || hueSaturation.value || levelAdjust.value)
                            }
                            P.SliderPreference {
                                name: "desaturation"
                                label: " --- " + qsTr("Desaturation")
                                visible:desaturate.value
                                displayValue: value
                                defaultValue: 0
                                from: 0
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            P.SwitchPreference {
                                visible:desaturate.value
                                name: "desaturateCached"
                                label: " --- " + qsTr("Cached")
                            }
                        //伽马调节
                            P.SwitchPreference {
                                id: gammaAdjust 
                                name: "gammaAdjust"
                                label: qsTr("Gamma Adjust")
                                //visible: !(colorOverlay.value || changeBrightnessContrast.value || colorize.value || desaturate.value || hueSaturation.value || levelAdjust.value)
                            }
                            P.SliderPreference {
                                name: "gamma"
                                label: " --- " + qsTr("Gamma")
                                visible:gammaAdjust.value
                                displayValue: value
                                defaultValue: 1000
                                from: 0
                                to: 100000
                                stepSize: 1
                                live: true
                            }
                            P.SwitchPreference {
                                visible:gammaAdjust.value
                                name: "gammaCached"
                                label: " --- " + qsTr("Cached")
                            }
                        //色相饱和度
                            P.SwitchPreference {
                                id: hueSaturation 
                                name: "hueSaturation"
                                label: qsTr("Hue Saturation")
                                //visible: !(colorOverlay.value || changeBrightnessContrast.value || colorize.value || desaturate.value || gammaAdjust.value || levelAdjust.value)
                            }
                            //色调 /100
                            P.SliderPreference {
                                name: "hueSaturationHue"
                                label: " --- " + qsTr("HUE")
                                visible:hueSaturation.value
                                displayValue: value
                                defaultValue: 0
                                from: -100
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            //亮度 /100
                            P.SliderPreference {
                                name: "hueSaturationLightness"
                                label: " --- " + qsTr("Lightness")
                                visible:hueSaturation.value
                                displayValue: value
                                defaultValue: 0
                                from: -100
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            //饱和度 /100
                            P.SliderPreference {
                                name: "hueSaturationSaturation"
                                label: " --- " + qsTr("Saturation")
                                visible:hueSaturation.value
                                displayValue: value
                                defaultValue: 0
                                from: -100
                                to: 100
                                stepSize: 1
                                live: true
                            }
                            P.SwitchPreference {
                                visible:hueSaturation.value
                                name: "hueSaturationCached"
                                label: " --- " + qsTr("Cached")
                            }
                        //电平调节
                            P.SwitchPreference {
                                id: levelAdjust 
                                name: "levelAdjust"
                                label: qsTr("Level Adjust")
                                //visible: !(colorOverlay.value || changeBrightnessContrast.value || colorize.value || desaturate.value || gammaAdjust.value || hueSaturation.value)
                            }
                            //伽马x
                            P.SliderPreference {
                                name: "levelAdjustGammaX"
                                label: " --- " + qsTr("Gamma X")
                                visible:levelAdjust.value
                                displayValue: value/100
                                defaultValue: 100
                                from: -10000
                                to: 10000
                                stepSize: 1
                                live: true
                            }
                            //伽马y
                            P.SliderPreference {
                                name: "levelAdjustGammaY"
                                label: " --- " + qsTr("Gamma Y")
                                visible:levelAdjust.value
                                displayValue: value/100
                                defaultValue: 100
                                from: -100000
                                to: 100000
                                stepSize: 1
                                live: true
                            }
                            //伽马z
                            P.SliderPreference {
                                name: "levelAdjustGammaZ"
                                label: " --- " + qsTr("Gamma Z")
                                visible:levelAdjust.value
                                displayValue: value/100
                                defaultValue: 100
                                from: -10000
                                to: 10000
                                stepSize: 1
                                live: true
                            }
                            NoDefaultColorPreference {
                                name: "maximumInputColor"
                                label: " --- " + qsTr("Max Input Color")
                                defaultValue: "#ffffffff"
                                visible:levelAdjust.value
                            }
                            NoDefaultColorPreference {
                                name: "maximumOutputColor"
                                label: " --- " + qsTr("Max Output Color")
                                defaultValue: "#ffffffff"
                                visible:levelAdjust.value
                            }
                            NoDefaultColorPreference {
                                name: "minimumInputColor"
                                label: " --- " + qsTr("Min Input Color")
                                defaultValue: "transparent"
                                visible:levelAdjust.value
                            }
                            NoDefaultColorPreference {
                                name: "minimumOutputColor"
                                label: " --- " + qsTr("Min Output Color")
                                defaultValue: "transparent"
                                visible:levelAdjust.value
                            }
                            P.SwitchPreference {
                                visible:levelAdjust.value
                                name: "levelAdjustCached"
                                label: " --- " + qsTr("Cached")
                            }
                        //颜色渐变
                            //开启颜色渐变
                            P.SwitchPreference {
                                id: colorGradient
                                name: "colorGradient"
                                label: qsTr("Color Gradient")
                            }
                            //渐变方向
                            P.SelectPreference {
                                id:animationDirect
                                name: "animationDirect"
                                label: " --- " + qsTr("Animation Direct")
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
                                label: " --- --- " + qsTr("Horizontal")
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
                                label: " --- --- " + qsTr("Vertical")
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
                                label: " --- --- " + qsTr("Angle")
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
                                label: " --- --- " + qsTr("Horizontal Radius")
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
                                label: " --- --- " + qsTr("Vertical Radius")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: settings.animationDirect==4&&colorGradient.value
                                defaultValue: 50
                                from: -10000
                                to: 10000
                                stepSize: 5
                            }
                            //渐变颜色
                            P.SelectPreference {
                                id:cycleColor
                                name: "cycleColor"
                                label: " --- " + qsTr("Cycle Color")
                                defaultValue: 0
                                //彩虹
                                model: [ qsTr("Rainbow") ,qsTr("Custom")+"Ⅰ", qsTr("Custom")+"Ⅱ"]
                                visible: colorGradient.value
                            }
                            //自定义颜色 1
                            //开始颜色
                            P.SpinPreference {
                                name: "cycleColorCustomStart"
                                label: " --- " + qsTr("Color Start")
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
                                label: " --- " + qsTr("Color End")
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
                            //饱和度
                            P.SpinPreference {
                                name: "cycleSaturation"
                                label: " --- " + qsTr("Saturation")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: colorGradient.value&&settings.cycleColor!=2
                                defaultValue: 100
                                from: 0
                                to: 100
                                stepSize: 1
                            }
                            //亮度
                            P.SpinPreference {
                                name: "cycleValue"
                                label: " --- " + qsTr("Value")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: colorGradient.value&&settings.cycleColor!=2
                                defaultValue: 100
                                from: 0
                                to: 100
                                stepSize: 1
                            }
                            //透明度
                            P.SpinPreference {
                                name: "cycleOpacity"
                                label: " --- " + qsTr("Opacity")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: colorGradient.value&&settings.cycleColor!=2
                                defaultValue: 100
                                from: 0
                                to: 100
                                stepSize: 1
                            }
                            //渐变动画
                            P.SwitchPreference {
                                id: enableColorAnimation
                                name: "enableColorAnimation"
                                label: " --- " + qsTr("Color Animation")
                                visible: colorGradient.value
                            }
                            //循环时间
                            // BUG 更改之后无法立刻看到预览
                            P.SpinPreference {
                                name: "cycleTime"
                                label: " --- --- " + qsTr("Cycle Time")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: enableColorAnimation.value&&colorGradient.value
                                defaultValue: 500
                                from: 0
                                to: 5000
                                stepSize: 100
                            }
                            P.SpinPreference {
                                name: "pauseColorAnimationTime"
                                label: " --- --- " + qsTr("Pause Time")
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
                                label: " --- " + qsTr("Color From")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: enableColorAnimation.value&&colorGradient.value
                                defaultValue: 0
                                from: 0
                                to: 10000
                                stepSize: 1
                            }
                            //渐变结束值
                            P.SpinPreference {
                                name: "cycleColorTo"
                                label: " --- " + qsTr("Color To")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: enableColorAnimation.value&&colorGradient.value
                                defaultValue: 15
                                from: 0
                                to: 10000
                                stepSize: 1
                            }
                            //是否缓存
                            P.SwitchPreference {
                                name: "enableColorAnimationCached"
                                label: " --- " + qsTr("Cached")
                                visible: colorGradient.value
                            }
                            //TODO渐变次数
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
                        //模糊
                            //快速模糊
                                P.SwitchPreference {
                                    id: fastBlur
                                    name: "fastBlur"
                                    label: qsTr("Fast Blur")
                                }
                                //半径
                                P.SpinPreference {
                                    name: "fastBlurRadius"
                                    label: " --- " + qsTr("Radius")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: fastBlur.value
                                    defaultValue: 5
                                    from: 0
                                    to: 500
                                    stepSize: 1
                                }
                                //透明边框
                                P.SwitchPreference {
                                    name: "fastBlurTransparentBorder"
                                    label: " --- " + qsTr("Transparent Border")
                                    visible: fastBlur.value
                                }
                                //缓存
                                P.SwitchPreference {
                                    name: "fastBlurCached"
                                    label: " --- " + qsTr("Cached")
                                    visible: fastBlur.value
                                }
                            //高斯模糊
                                P.SwitchPreference {
                                    id: gaussianBlur
                                    name: "gaussianBlur"
                                    label: qsTr("Gaussian Blur")
                                }
                                //半径
                                P.SpinPreference {
                                    name: "gaussianBlurRadius"
                                    label: " --- " + qsTr("Radius")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: gaussianBlur.value
                                    defaultValue: 5
                                    from: 0
                                    to: 500
                                    stepSize: 1
                                }
                                //偏差值
                                P.SpinPreference {
                                    name: "gaussianBlurDeviation"
                                    label: " --- " + qsTr("Deviation")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: gaussianBlur.value
                                    defaultValue: 3
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                }
                                //样本数
                                P.SpinPreference {
                                    name: "gaussianBlurSamples"
                                    label: " --- " + qsTr("Samples")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: gaussianBlur.value
                                    defaultValue: 5
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                }
                                //透明边框
                                P.SwitchPreference {
                                    name: "dropShadowTransparentBorder"
                                    label: " --- " + qsTr("Transparent Border")
                                    visible: gaussianBlur.value
                                }
                                //缓存
                                P.SwitchPreference {
                                    name: "gaussianBlurCached"
                                    label: " --- " + qsTr("Cached")
                                    visible: gaussianBlur.value
                                }
                            //蒙版模糊
                                P.SwitchPreference {
                                    id: maskedBlur
                                    name: "maskedBlur"
                                    label: qsTr("Masked Blur")
                                }
                                //遮罩图片
                                P.ImagePreference {
                                    name: "maskedBlurMaskSource"
                                    label: " --- " + qsTr("Mask Source")
                                    visible:maskedBlur.value&&!blendMaskedBlurDataEnabled.value
                                }
                                //半径
                                P.SpinPreference {
                                    name: "maskedBlurRadius"
                                    label: " --- " + qsTr("Radius")
                                    visible:maskedBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                    editable: true
                                }
                                //采样数
                                P.SpinPreference {
                                    name: "maskedBlurSamples"
                                    label: " --- " + qsTr("Samples")
                                    visible:maskedBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 9
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                    editable: true
                                }
                                //缓存
                                P.SwitchPreference {
                                    visible:maskedBlur.value
                                    name: "maskedBlurCached"
                                    label: " --- " + qsTr("Cached")
                                }
                                //启用数据源
                                P.SwitchPreference {
                                    id: blendMaskedBlurDataEnabled
                                    name: "blendDataEnabled"
                                    label: " --- " + qsTr("Enable Data Source")
                                    visible: maskedBlur.value
                                }
                            //递归模糊
                                P.SwitchPreference {
                                    id: recursiveBlur
                                    name: "recursiveBlur"
                                    label: qsTr("Recursive Blur")
                                }
                                //半径
                                P.SpinPreference {
                                name: "recursiveBlurRadius"
                                label: " --- " + qsTr("Radius")
                                visible:recursiveBlur.value
                                display: P.TextFieldPreference.ExpandLabel
                                defaultValue: 0
                                from: 0
                                to: 160
                                stepSize: 1
                                editable: true
                                }
                                //循环次数
                                P.SpinPreference {
                                    name: "recursiveBlurLoops"
                                    label: " --- " + qsTr("Loops")
                                    visible:recursiveBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 10000
                                    stepSize: 1
                                    editable: true
                                }
                                //进度
                                P.SpinPreference {
                                    name: "recursiveBlurProgress"
                                    label: " --- " + qsTr("Progress")
                                    visible:recursiveBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 1
                                    from: 0
                                    to: 100
                                    stepSize: 1
                                    editable: true
                                }
                                //透明边框
                                P.SwitchPreference {
                                    visible:recursiveBlur.value
                                    name: "recursiveBlurTransparentBorder"
                                    label: " --- " + qsTr("Transparent Border")
                                }
                                //缓存
                                P.SwitchPreference {
                                    visible:recursiveBlur.value
                                    name: "recursiveBlurCached"
                                    label: " --- " + qsTr("Cached")
                                }
                        //动态模糊
                            //方向模糊
                                P.SwitchPreference {
                                    id: directionalBlur
                                    name: "directionalBlur"
                                    label: qsTr("Directional Blur")
                                }
                                //长度
                                P.SpinPreference {
                                name: "directionalBlurLength"
                                label: " --- " + qsTr("Length")
                                visible:directionalBlur.value
                                display: P.TextFieldPreference.ExpandLabel
                                defaultValue: 0
                                from: 0
                                to: 1000
                                stepSize: 1
                                editable: true
                                }
                                //角度
                                P.SpinPreference {
                                    name: "directionalBlurAngle"
                                    label: " --- " + qsTr("Angle")
                                    visible:directionalBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: -180
                                    to: 180
                                    stepSize: 1
                                    editable: true
                                }
                                //采样
                                P.SpinPreference {
                                    name: "directionalBlurSamples"
                                    label: " --- " + qsTr("Samples")
                                    visible:directionalBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 250
                                    stepSize: 1
                                    editable: true
                                }
                                P.SwitchPreference {
                                    name: "directionalBlurTransparentBorder"
                                    label: " --- " + qsTr("Transparent Border")
                                    visible:directionalBlur.value
                                }
                                P.SwitchPreference {
                                    name: "directionalBlurCached"
                                    label: " --- " + qsTr("Cached")
                                    visible:directionalBlur.value
                                }
                            //径向模糊
                                P.SwitchPreference {
                                    id: radialBlur
                                    name: "radialBlur"
                                    label: qsTr("Radial Blur")
                                }
                                //水平偏移
                                P.SpinPreference {
                                    name: "radialBlurHorizontalOffset"
                                    label: " --- " + qsTr("Horizontal Offset")
                                    visible: radialBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                    editable: true
                                }
                                //垂直偏移
                                P.SpinPreference {
                                    name: "radialBlurVerticalOffset"
                                    label: " --- " + qsTr("Vertical Offset")
                                    visible: radialBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                    editable: true
                                }
                                //角度
                                P.SpinPreference {
                                    name: "radialBlurAngle"
                                    label: " --- " + qsTr("Angle")
                                    visible: radialBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 360
                                    stepSize: 1
                                    editable: true
                                }
                                //采样
                                P.SpinPreference {
                                    name: "radialBlurSamples"
                                    label: " --- " + qsTr("Samples")
                                    visible: radialBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 250
                                    stepSize: 1
                                    editable: true
                                }
                                P.SwitchPreference {
                                    name: "radialBlurTransparentBorder"
                                    label: " --- " + qsTr("Transparent Border")
                                    visible: radialBlur.value
                                }
                                P.SwitchPreference {
                                    name: "radialBlurCached"
                                    label: " --- " + qsTr("Cached")
                                    visible: radialBlur.value
                                }
                            //缩放模糊
                                P.SwitchPreference {
                                    id: zoomBlur
                                    name: "zoomBlur"
                                    label: qsTr("Zoom Blur")
                                }
                                //水平偏移
                                P.SpinPreference {
                                    name: "zoomBlurHorizontalOffset"
                                    label: " --- " + qsTr("Horizontal Offset")
                                    visible: zoomBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                    editable: true
                                }
                                //垂直偏移
                                P.SpinPreference {
                                    name: "zoomBlurVerticalOffset"
                                    label: " --- " + qsTr("Vertical Offset")
                                    visible: zoomBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                    editable: true
                                }
                                //长度
                                P.SpinPreference {
                                    name: "zoomBlurrLength"
                                    label: " --- " + qsTr("Length")
                                    visible: zoomBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                    editable: true
                                }
                                //采样
                                P.SpinPreference {
                                    name: "zoomBlurSamples"
                                    label: " --- " + qsTr("Samples")
                                    visible: zoomBlur.value
                                    display: P.TextFieldPreference.ExpandLabel
                                    defaultValue: 0
                                    from: 0
                                    to: 250
                                    stepSize: 1
                                    editable: true
                                }
                                P.SwitchPreference {
                                    name: "zoomBlurTransparentBorder"
                                    label: " --- " + qsTr("Transparent Border")
                                    visible: zoomBlur.value
                                }
                                P.SwitchPreference {
                                    name: "zoomBlurCached"
                                    label: " --- " + qsTr("Cached")
                                    visible: zoomBlur.value
                                }
                        //阴影
                            //外
                                P.SwitchPreference {
                                        id: enableDropShadow
                                        name: "enableDropShadow"
                                        label: qsTr("Drop Shadow")
                                }
                                //颜色
                                NoDefaultColorPreference {
                                    name: "dropShadowColor"
                                    label: " --- " + qsTr("Color")
                                    defaultValue: "white"
                                    visible: enableDropShadow.value
                                }
                                //半径
                                P.SpinPreference {
                                    name: "dropShadowRadius"
                                    label: " --- " + qsTr("Radius")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableDropShadow.value
                                    defaultValue: 5
                                    from: 0
                                    to: 500
                                    stepSize: 1
                                }
                                //采样率
                                P.SpinPreference {
                                    name: "dropShadowSamples"
                                    label: " --- " + qsTr("Samples")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableDropShadow.value
                                    defaultValue: 5
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                }
                                //水平位移
                                P.SpinPreference {
                                    name: "dropShadowHorizontalOffset"
                                    label: " --- " + qsTr("Horizontal Offset")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableDropShadow.value
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                }
                                //垂直位移
                                P.SpinPreference {
                                    name: "dropShadowVerticalOffset"
                                    label: " --- " + qsTr("Vertical Offset")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableDropShadow.value
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                }
                                //透明边框
                                P.SwitchPreference {
                                    name: "dropShadowTransparentBorder"
                                    label: " --- " + qsTr("Transparent Border")
                                    visible: enableDropShadow.value
                                }
                                //缓存
                                P.SwitchPreference {
                                    name: "dropShadowCache"
                                    label: " --- " + qsTr("Cached")
                                    visible: enableDropShadow.value
                                } 

                            //内    
                                P.SwitchPreference {
                                        id: enableInnerShadow
                                        name: "enableInnerShadow"
                                        label: qsTr("Inner Shadow")
                                }
                                //颜色
                                NoDefaultColorPreference {
                                    name: "innerShadowColor"
                                    label: " --- " + qsTr("Color")
                                    defaultValue: "white"
                                    visible: enableInnerShadow.value
                                }
                                //半径
                                P.SpinPreference {
                                    name: "innerShadowRadius"
                                    label: " --- " + qsTr("Radius")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableInnerShadow.value
                                    defaultValue: 5
                                    from: 0
                                    to: 500
                                    stepSize: 1
                                }
                                //采样率
                                P.SpinPreference {
                                    name: "innerShadowSamples"
                                    label: " --- " + qsTr("Samples")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableInnerShadow.value
                                    defaultValue: 5
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                }
                                //水平位移
                                P.SpinPreference {
                                    name: "innerShadowHorizontalOffset"
                                    label: " --- " + qsTr("Horizontal Offset")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableInnerShadow.value
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                }
                                //垂直位移
                                P.SpinPreference {
                                    name: "innerShadowVerticalOffset"
                                    label: " --- " + qsTr("Vertical Offset")
                                    editable: true
                                    display: P.TextFieldPreference.ExpandLabel
                                    visible: enableInnerShadow.value
                                    defaultValue: 0
                                    from: 0
                                    to: 1000
                                    stepSize: 1
                                }
                                //快速渲染
                                P.SwitchPreference {
                                    name: "innerShadowFastAlgorithm"
                                    label: " --- " + qsTr("Fast Algorithm")
                                    visible: enableInnerShadow.value
                                }
                                //缓存
                                P.SwitchPreference {
                                    name: "innerShadowCache"
                                    label: " --- " + qsTr("Cached")
                                    visible: enableInnerShadow.value
                                }
                        //发光效果
                            P.SwitchPreference {
                                id: enableGlow
                                name: "enableGlow"
                                label: qsTr("Glow")
                            }
                            //颜色
                            NoDefaultColorPreference {
                                name: "glowColor"
                                label: " --- " + qsTr("Color")
                                defaultValue: "white"
                                visible: enableGlow.value
                            }
                            //作用范围(半径)
                            P.SpinPreference {
                                name: "glowRadius"
                                label: " --- " + qsTr("Radius")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: enableGlow.value
                                defaultValue: 5
                                from: 0
                                to: 500
                                stepSize: 1
                            }
                            //强度  范围0~1  值除以100
                            P.SpinPreference {
                                name: "glowSpread"
                                label: " --- " + qsTr("Spread")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: enableGlow.value
                                defaultValue: 50
                                from: 0
                                to: 100
                                stepSize: 1
                            }
                            //采样率
                            P.SpinPreference {
                                name: "glowSamples"
                                label: " --- " + qsTr("Samples")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: enableGlow.value
                                defaultValue: 5
                                from: 0
                                to: 1000
                                stepSize: 1
                            }
                            //透明边框
                            P.SwitchPreference {
                                name: "glowTransparentBorder"
                                label: " --- " + qsTr("Transparent Border")
                                visible: enableGlow.value
                            }
                            //缓存
                            P.SwitchPreference {
                                name: "glowCache"
                                label: " --- " + qsTr("Cached")
                                visible: enableGlow.value
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
                            P.SwitchPreference {
                                id: enableBlend
                                name: "enableBlend"
                                label: qsTr("Blend")
                            }
                            //遮罩图像
                            P.ImagePreference {
                                name: "blendSource"
                                label: " --- " + qsTr("Blend Image")
                                visible: enableBlend.value&&!blendDataEnabled.value
                            }
                            //模式
                            P.SelectPreference {
                                name: "blendMode"
                                label: " --- " + qsTr("Mode")
                                defaultValue: 0
                                model: [ qsTr("normal"), qsTr("addition"), qsTr("average"), qsTr("color"), qsTr("colorBurn"), qsTr("colorDodge"),qsTr("darken"),qsTr("darkerColor"),qsTr("difference"),qsTr("divide"),qsTr("exclusion"),qsTr("hardLight"),qsTr("hue"),qsTr("lighten"),qsTr("lighterColor"),qsTr("lightness"),qsTr("multiply"),qsTr("negation"),qsTr("saturation"),qsTr("screen"),qsTr("subtract"),qsTr("softLight")]
                                visible: enableBlend.value
                            }
                            //缓存
                            P.SwitchPreference {
                                name: "enableBlendCached"
                                label: " --- " + qsTr("Cached")
                                visible: enableBlend.value
                            }
                            //启用数据源
                            P.SwitchPreference {
                                id: blendDataEnabled
                                name: "blendDataEnabled"
                                label: " --- " + qsTr("Enable Data Source")
                                visible: enableBlend.value
                            }
                        //不透明遮罩
                            P.SwitchPreference {
                                id: enableOpacityMask
                                name: "enableOpacityMask"
                                label: qsTr("Opacity Mask")
                            }
                            //遮罩图像
                            P.ImagePreference {
                                name: "opacityMaskSource"
                                label: " --- " + qsTr("Opacity Mask Image")
                                visible: enableOpacityMask.value&&!opacityMaskDataEnabled.value
                            }
                            //反转
                            P.SwitchPreference {
                                name: "opacityMaskInvert"
                                label: " --- " + qsTr("Invert")
                                visible: enableOpacityMask.value
                            }
                            //缓存
                            P.SwitchPreference {
                                name: "enableOpacityMaskCached"
                                label: " --- " + qsTr("Cached")
                                visible: enableOpacityMask.value
                            }
                            //启用数据源
                            P.SwitchPreference {
                                id: opacityMaskDataEnabled
                                name: "opacityMaskDataEnabled"
                                label: " --- " + qsTr("Enable Data Source")
                                visible: enableOpacityMask.value
                            }
                        //覆盖遮罩
                            P.SwitchPreference {
                                id: enableThresholdMask
                                name: "enableThresholdMask"
                                label: qsTr("Threshold Mask")
                            }
                            //遮罩图像
                            P.ImagePreference {
                                name: "thresholdMaskSource"
                                label: " --- " + qsTr("Threshold Mask Image")
                                visible: enableThresholdMask.value&&!thresholdMaskDataEnabled.value
                            }
                            //强度(0~1)
                            P.SpinPreference {
                                name: "thresholdMaskSpread"
                                label: " --- " + qsTr("Spread")
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
                                label: " --- " + qsTr("Threshold")
                                editable: true
                                display: P.TextFieldPreference.ExpandLabel
                                visible: enableThresholdMask.value
                                defaultValue: 50
                                from: 0
                                to: 100
                                stepSize: 1
                            }
                            //缓存
                            P.SwitchPreference {
                                name: "enableThresholdMaskCached"
                                label: " --- " + qsTr("Cached")
                                visible: enableThresholdMask.value
                            }
                            //启用数据源
                            P.SwitchPreference {
                                id: thresholdMaskDataEnabled
                                name: "thresholdMaskDataEnabled"
                                label: " --- " + qsTr("Enable Data Source")
                                visible: enableThresholdMask.value
                            }
                        //取代
                            P.SwitchPreference {
                                id: enableDisplace
                                name: "enableDisplace"
                                label: qsTr("Displace")
                            }
                            //取代图像
                            P.ImagePreference {
                                name: "displacementSource"
                                label: " --- " + qsTr("Displace Image")
                                visible: enableDisplace.value&&!displaceDataEnabled.value
                            }
                            //取代位移
                            P.SliderPreference {
                                name: "displacement"
                                label: " --- " + qsTr("Displacement")
                                visible:enableDisplace.value
                                displayValue: value*100
                                defaultValue: 0
                                from: -1
                                to: 1
                                stepSize: 0.01
                                live: true
                            }
                            //缓存
                            P.SwitchPreference {
                                name: "enableDisplaceCached"
                                label: " --- " + qsTr("Cached")
                                visible: enableDisplace.value
                            }
                            //启用数据源
                            P.SwitchPreference {
                                id: displaceDataEnabled
                                name: "displaceDataEnabled"
                                label: " --- " + qsTr("Enable Data Source")
                                visible: enableDisplace.value
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
//颜色
    //颜色
    ColorOverlay{
        visible:settings.colorOverlay ?? false
        anchors.fill: imageSource
        source: settings.colorOverlay ? imageSource : null
        color: {
        if (thiz.itemPressed && pressedColor.a)
            return pressedColor;
        if (thiz.itemHovered && hoveredColor.a)
            return hoveredColor;
        return normalColor;
        }
    }
    //亮度对比度
    BrightnessContrast {
        anchors.fill: imageSource
        source: settings.changeBrightnessContrast ? imageSource : null
        visible: settings.changeBrightnessContrast ?? false
        brightness: (settings.brightness ?? 0)/100//亮度
        contrast: (settings.contrast ?? 0)/100//对比度
        cached:settings.brightnessContrastCached ?? false//缓存
    }
    //着色
    Colorize {
        anchors.fill: imageSource
        source: settings.colorize ? imageSource : null
        visible: settings.colorize ?? false
        hue: (settings.colorizeHue ?? 0)/100
        saturation: (settings.colorizeSaturation ?? 100)/100
        lightness: (settings.colorizeLightness ?? 0)/100
        cached:settings.brightnessContrastCached ?? false
    }
    //去饱和
    Desaturate {
        anchors.fill: imageSource
        source: settings.desaturate ? imageSource : null
        visible: settings.desaturate ?? false
        desaturation: (settings.desaturation ?? 0)/100
        cached: settings.desaturateCached ?? false
    }
    //伽马调节
    GammaAdjust {
        anchors.fill: imageSource
        source: settings.gammaAdjust ? imageSource : null
        visible: settings.gammaAdjust ?? false
        gamma: (settings.gamma ?? 1000)/1000
        cached: settings.gammaCached ?? false
    }
    //色相饱和度
    HueSaturation {
        anchors.fill: imageSource
        source: settings.hueSaturation ? imageSource : null
        visible: settings.hueSaturation ?? false
        hue: (settings.hueSaturationHue ?? 0)/100
        saturation: (settings.hueSaturationSaturation ?? 0)/100
        lightness: (settings.hueSaturationLightness ?? 0)/100
        cached: settings.hueSaturationCached ?? false
    }
    //电平调节
    LevelAdjust {
        anchors.fill: imageSource
        source: settings.levelAdjust ? imageSource : null
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
            anchors.fill: imageSource
            cached:settings.enableColorAnimationCached ?? false
            source: (enableColorGradient&&(settings.animationDirect>=0&&settings.animationDirect<=3||settings.animationDirect==6)) ? imageSource : null
            visible: (enableColorGradient&&(settings.animationDirect>=0&&settings.animationDirect<=3||settings.animationDirect==6))
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
                    case 0 : return Qt.point(imageSource.width, 0); break;//1.横向渐变
                    case 1 : return Qt.point(0, imageSource.height); break;//2.竖向渐变
                    case 2 : return Qt.point(imageSource.width, imageSource.height); break;//3.斜向渐变
                    case 3 : return Qt.point(0, 0); break;// All
                    case 6 : return Qt.point(settings.animationAdvancedEndX ?? 100, settings.animationAdvancedEndY ?? 100); break;
                    default: return Qt.point(imageSource.width, 0); break; 
                }
                return Qt.point(imageSource.width, 0);
            }
            gradient: gradientRainbow
        }
        //颜色动画选项4
        RadialGradient {
            anchors.fill: imageSource
            //可调节的角度,x,y,x半径,y半径
            angle: settings.animationAngle ?? 0
            cached:settings.enableColorAnimationCached ?? false
            horizontalOffset: settings.animationHorizontal ?? 0
            verticalOffset: settings.animationVertical ?? 0
            horizontalRadius:settings.animationHorizontalRadius ?? 50
            verticalRadius:settings.animationVerticalRadius ?? 50
            source: (enableColorGradient&&(settings.animationDirect==4)) ? imageSource : null
            visible: (enableColorGradient&&(settings.animationDirect==4))
            gradient: gradientRainbow
        }
        //颜色动画选项5
        ConicalGradient {
            anchors.fill: imageSource
            cached:settings.enableColorAnimationCached ?? false
            //可调节的角度,x,y值
            angle: settings.animationAngle ?? 0
            horizontalOffset: settings.animationHorizontal ?? 0
            verticalOffset: settings.animationVertical ?? 0
            source: (enableColorGradient&&(settings.animationDirect==5)) ? imageSource : null
            visible: (enableColorGradient&&(settings.animationDirect==5))
            gradient: gradientRainbow
        }
        //动画颜色
        Gradient {
            id: gradientRainbow
            GradientStop { position: 0.000; color: getColor(15) }
            GradientStop { position: 0.067; color: getColor(14) }
            GradientStop { position: 0.133; color: getColor(13) }
            GradientStop { position: 0.200; color: getColor(12) }
            GradientStop { position: 0.267; color: getColor(11) }
            GradientStop { position: 0.333; color: getColor(10) }
            GradientStop { position: 0.400; color: getColor(9) }
            GradientStop { position: 0.467; color: getColor(8) }
            GradientStop { position: 0.533; color: getColor(7) }
            GradientStop { position: 0.600; color: getColor(6) }
            GradientStop { position: 0.667; color: getColor(5) }
            GradientStop { position: 0.733; color: getColor(4) }
            GradientStop { position: 0.800; color: getColor(3) }
            GradientStop { position: 0.867; color: getColor(2) }
            GradientStop { position: 0.933; color: getColor(1) }
            GradientStop { position: 1.000; color: getColor(0) }
        }
        //颜色渐变动画
        //TODO 需要重新开关来启用效果
        // readonly property real cf: Number(thiz.cycleColorFrom)
        // onCfChanged: settings.cycleColorFrom=cf
        SequentialAnimation {
            running: enableColorGradientAnimation && widget.NVG.View.exposed  // 默认启动
            loops:Animation.Infinite  // 无限循环
            PauseAnimation { duration: settings.pauseColorAnimationTime ?? 0 }
            NumberAnimation {
                target: thiz  // 目标对象
                property: "idxx" // 目标对象中的属性
                duration: settings.cycleTime ?? 500 // 变化时间
                from: settings.cycleColorFrom ?? 0
                to: settings.cycleColorTo ?? 15// 目标值
            }
        }
//发光
    Glow {
        anchors.fill: imageSource
        source: settings.enableGlow ? imageSource : null
        visible: settings.enableGlow ?? false
        cached: settings.glowCache ?? false//缓存
        radius: settings.glowRadius ?? 5//作用范围
        samples: settings.glowSamples ?? 50//采样数
        spread: (settings.glowSpread ?? 50)/100//强度
        color: settings.glowColor ?? "white"//颜色
        transparentBorder: allowGlowTransparentBorder ?? false//透明边框 bool
    }
//阴影
    //外阴影
    DropShadow {
        anchors.fill: imageSource
        source: settings.enableDropShadow ? imageSource : null
        visible: settings.enableDropShadow ?? false
        color: settings.dropShadowColor ?? "white"//颜色
        radius: settings.dropShadowRadius ?? 5//半径
        samples: settings.dropShadowSamples ?? 50//样本数
        horizontalOffset: settings.dropShadowHorizontalOffset ?? 0//水平位移
        verticalOffset: settings.dropShadowVerticalOffset ?? 0//垂直位移
        transparentBorder: settings.dropShadowTransparentBorder ?? false//透明边框
        cached: settings.dropShadowCache ?? false//缓存
    }
    //内阴影
    InnerShadow {
        anchors.fill: imageSource
        source: settings.enableInnerShadow ? imageSource : null
        visible: settings.enableInnerShadow ?? false
        color: settings.innerShadowColor ?? "white"//颜色
        radius: settings.innerShadowRadius ?? 5//半径
        samples: settings.innerShadowSamples ?? 50//样本数
        horizontalOffset: settings.innerShadowHorizontalOffset ?? 0//水平位移
        verticalOffset: settings.innerShadowVerticalOffset ?? 0//垂直位移
        fast: settings.innerShadowFastAlgorithm ?? false//快速渲染
        cached: settings.innerShadowCache ?? false//缓存
    }

//模糊
    //快速模糊
        FastBlur {
            anchors.fill: imageSource
            source: settings.fastBlur ? imageSource : null
            visible: settings.fastBlur ?? false
            radius: settings.fastBlurRadius ?? 5//半径
            transparentBorder: settings.fastBlurTransparentBorder ?? false//透明边框
            cached: settings.fastBlurCached ?? false//缓存
        }
    //高斯模糊
        GaussianBlur {
            anchors.fill: imageSource
            source: settings.gaussianBlur ? imageSource : null
            visible: settings.gaussianBlur ?? false
            radius: settings.gaussianBlurRadius ?? 5//半径
            deviation: settings.gaussianBlurDeviation ?? 3//偏差值
            samples: settings.gaussianBlurSamples ?? 5//样本数
            transparentBorder: settings.dropShadowTransparentBorder ?? false//透明边框
            cached: settings.gaussianBlurCached ?? false//缓存
        }
    //蒙版模糊
        NVG.ImageSource {
            visible: settings.maskedBlur ?? false
            id: maskedBlurIamge
            anchors.fill: parent
            fillMode: thiz.settings.fill ?? Image.PreserveAspectFit
            playing: status === Image.Ready
            configuration: {
                if (blendMaskedBlurDataEnabled)//启用数据源
                    return maskedBluroutput.result;
                return maskedBlurIamge;
            }
        }
        MaskedBlur {
            anchors.fill: imageSource
            source: settings.maskedBlur ? imageSource : null
            visible: settings.maskedBlur ?? false
            maskSource: maskedBlurIamge//遮罩源
            radius: settings.maskedBlurRadius ?? 0
            samples: settings.maskedBlurSamples ?? 9
            cached: settings.maskedBlurCached ?? false
        }
    //递归模糊
        RecursiveBlur {
            anchors.fill: imageSource
            source: settings.recursiveBlur ? imageSource : null
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
            anchors.fill: imageSource
            source : settings.directionalBlur ? imageSource : null
            visible: settings.directionalBlur ?? false
            angle : settings.directionalBlurAngle ?? 0//角度
            length : settings.directionalBlurLength ?? 0//长度 
            samples : settings.directionalBlurSamples ?? 0//采样数
            transparentBorder : settings.directionalBlurTransparentBorder ?? false
            cached : settings.directionalBlurCached ?? false
        }
    //径向模糊
        RadialBlur {
            anchors.fill: imageSource
            source: settings.radialBlur ? imageSource : null
            visible: settings.radialBlur ?? false
            angle: settings.radialBlurAngle ?? 0
            horizontalOffset: settings.radialBlurHorizontalOffset ?? 0
            verticalOffset: settings.radialBlurVerticalOffset ?? 0
            samples: settings.radialBlurSamples ?? 0
            transparentBorder: settings.radialBlurTransparentBorder ?? false
            cached: settings.radialBlurCached ?? 0
        }
    //缩放模糊
        ZoomBlur {
            anchors.fill: imageSource
            source: settings.zoomBlur ? imageSource : null
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
        fillMode: thiz.settings.fill ?? Image.PreserveAspectFit
        playing: status === Image.Ready
        configuration: {
            if (blendDataEnabled)//启用数据源
                return blendOutput.result;
            return blendImage;
        }
    }
    Blend {
        anchors.fill: imageSource
        source: settings.enableBlend ? imageSource : null
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
        fillMode: thiz.settings.fill ?? Image.PreserveAspectFit
        playing: status === Image.Ready
        configuration: {
            if (opacityMaskDataEnabled)//启用数据源
                return opacityMaskOutput.result;
            return opacityMaskImage;
        }
    }
    OpacityMask {
        anchors.fill: imageSource
        source: settings.enableOpacityMask ? imageSource : null
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
        fillMode: thiz.settings.fill ?? Image.PreserveAspectFit
        playing: status === Image.Ready
        configuration: {
            if (thresholdMaskDataEnabled)//启用数据源
                return thresholdMaskOutput.result;
            return thresholdMaskImage;
        }
    }
    ThresholdMask {
        anchors.fill: imageSource
        source: settings.enableThresholdMask ? imageSource : null
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
        fillMode: thiz.settings.fill ?? Image.PreserveAspectFit
        playing: status === Image.Ready
        configuration: {
            if (displaceDataEnabled)//启用数据源
                return displaceOutput.result;
            return displaceImage;
        }
    }
    Displace {
        anchors.fill: imageSource
        source: settings.enableDisplace ? imageSource : null
        visible: settings.enableDisplace ?? false
        displacementSource: displaceImageSource
        displacement: settings.displacement ?? 50
        cached: settings.enableDisplaceCached ?? false
    }
//数据源
    NVG.DataSourceRawOutput {
        id: output
        source: dataEnabled ? thiz.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: maskedBluroutput
        source: blendMaskedBlurDataEnabled ? thiz.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: blendOutput
        source: blendDataEnabled ? thiz.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: opacityMaskOutput
        source: opacityMaskDataEnabled ? thiz.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: thresholdMaskOutput
        source: thresholdMaskDataEnabled ? thiz.dataSource : null
    }
    NVG.DataSourceRawOutput {
        id: displaceOutput
        source: displaceDataEnabled ? thiz.dataSource : null
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