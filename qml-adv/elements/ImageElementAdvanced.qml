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
    preference: EffectPreferencePanel {
        id: prefPanel
        settingsTarget: thiz.settings
        groupEnabled: currentItem
        // Basic 作为前置页签，与共享面板的 Color/Effects/Blend/Gradient 拼成同一行扁平页签
        leadingTabs: [{ label: qsTr("Basic"), component: basicPageComp }]

        Component {
            id: basicPageComp
            Column {
                width: prefPanel.width
                topPadding: 16
                bottomPadding: 16

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
//颜色循环渐变驱动器（已迁出至 ColorCycleGradient.qml，与 CraftElement 共用）
    ColorCycleGradient {
        id: colorCycle
        settings: thiz.settings
        viewExposed: widget.NVG.View.exposed
    }
//图形特效叠加层（已迁出至 ImageEffectStack.qml）
    ImageEffectStack {
        sourceItem: imageSource
        settings: thiz.settings
        dataSource: thiz.dataSource
        itemPressed: thiz.itemPressed
        itemHovered: thiz.itemHovered
        gradient: colorCycle.gradient
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