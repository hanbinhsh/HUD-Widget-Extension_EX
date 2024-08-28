import QtQuick 2.12
import NERvGear 1.0 as NVG
//动画必备
import QtGraphicalEffects 1.12 
import "utils.js" as Utils
//二级挂件属性
MouseArea {
    id: delegate

    property Item view // Note: CraftView type recusive
    property NVG.SettingsMap settings
    property int index

    property bool hidden

    property string interactionState: hidden ? "HIDDEN" :
                                      pressed ? "PRESSED" :
                                      containsMouse ? "HOVERED" : "NORMAL"
    property string interactionSource
    property NVG.SettingsMap interactionSettingsBase

    //增加
    //悬停移动动画
    property real animationX : 0
    property real animationY : 0
    //悬停缩放动画
    property real animationZoomX : 0
    property real animationZoomY : 0
    //悬停旋转动画
    property real animationSpin : 0
    //悬停闪烁动画
    property real animationGlimmerTarget : 1

    readonly property real rotationStep: (settings.rotationSpeed ?? 5) * 6 / (settings.rotationFPS ?? 20)
    readonly property bool rotationEnabled: Boolean(delegate.settings.rotationDisplay)
    readonly property bool rotationAnimationEnabled: Boolean(delegate.settings.enableAdvancedRotationAnimation)
    //动画变量
    readonly property real rotationAnimationStep: (settings.advancedRotationSpeed ?? 5) * 6 / (settings.advancedRotationFPS ?? 20)
    readonly property bool opacityAnimationEnabled: Boolean(settings.enableOpacityAnimation)

    anchors.top: settings.alignment & Qt.AlignTop ? parent.top : undefined
    anchors.topMargin: settings.top
    anchors.bottom: settings.alignment & Qt.AlignBottom ? parent.bottom : undefined
    anchors.bottomMargin: settings.bottom
    anchors.left: settings.alignment & Qt.AlignLeft ? parent.left : undefined
    anchors.leftMargin: settings.left
    anchors.right: settings.alignment & Qt.AlignRight ? parent.right : undefined
    anchors.rightMargin: settings.right

    anchors.verticalCenter: {
        const align = settings.alignment;

        // default to vertical center
        if (!(align & Qt.AlignVertical_Mask))
            return parent.verticalCenter;

        return align & Qt.AlignTop || align & Qt.AlignBottom ? undefined : parent.verticalCenter;
    }
    anchors.verticalCenterOffset: settings.vertical ?? 0
    anchors.horizontalCenter: {
        const align = settings.alignment;

        // default to horizontal center
        if (!(align & Qt.AlignHorizontal_Mask))
            return parent.horizontalCenter;

        return align & Qt.AlignLeft || align & Qt.AlignRight ? undefined : parent.horizontalCenter;
    }
    anchors.horizontalCenterOffset: settings.horizon ?? 0
    
    //挂件高度
    z: settings.z ?? 0
    //挂件旋转
    rotation: settings.rotation ?? 0+(animationSpin??0)
    transform:[
        Rotation {
            origin.x: settings.enableAdvancedRotation ? settings.advancedRotationOriginX ?? 0 : 0
            origin.y: settings.enableAdvancedRotation ? settings.advancedRotationOriginY ?? 0 : 0
            axis {
                x: settings.enableAdvancedRotation ? settings.advancedRotationAxisX ?? 0 : 0
                y: settings.enableAdvancedRotation ? settings.advancedRotationAxisY ?? 0 : 0
                z: settings.enableAdvancedRotation ? settings.advancedRotationAxisZ ?? 0 : 0
            }
            angle: settings.enableAdvancedRotation ? settings.advancedRotationAngle ?? 0 : 0
        },
        Scale {//变换中设置了缩放中心按变换设置的
            origin.x: settings.scaleSetting ? settings.scaleOriginX ?? 0 : 0 + (settings.zoomMouse_OriginX ?? 0)
            origin.y: settings.scaleSetting ? settings.scaleOriginY ?? 0 : 0 + (settings.zoomMouse_OriginY ?? 0)
            xScale: settings.scaleSetting ? (settings.scaleX ?? 1000) / 1000 + (animationZoomX ?? 0) / 1000 : 1 + (animationZoomX ?? 0) / 1000
            yScale: settings.scaleSetting ? (settings.scaleY ?? 1000) / 1000 + (animationZoomY ?? 0) / 1000 : 1 + (animationZoomY ?? 0) / 1000
        },
        Translate {
            x: settings.translateSetting ? (settings.translateX ?? 0) + (animationX ?? 0) ?? 0+(animationX ?? 0) : 0 + (animationX ?? 0)
            y: settings.translateSetting ? (settings.translateY ?? 0) + (animationY ?? 0) ?? 0+(animationY ?? 0) : 0 + (animationY ?? 0)
        }
    ]
    //旋转动画
    onRotationAnimationEnabledChanged: settings.advancedRotationAngle=0
        Timer {
            repeat: true
            interval: 1000 / (settings.advancedRotationFPS ?? 20)
            running: rotationAnimationEnabled&&widget.NVG.View.exposed
            onTriggered: settings.advancedRotationAngle = (settings.advancedRotationAngle + rotationAnimationStep) % 360
    }
    //透明度
    opacity: settings.opacity ?? 1
    //透明度动画
    onOpacityAnimationEnabledChanged: settings.opacity=1
    SequentialAnimation {
        running: opacityAnimationEnabled && widget.NVG.View.exposed
        loops:Animation.Infinite
        NumberAnimation {
            target: delegate
            property: "opacity"
            duration: settings.opacityAnimationSpeed ?? 500
            from: 0
            to: 1
        }
        NumberAnimation {
            target: delegate
            property: "opacity"
            duration: settings.opacityAnimationSpeed ?? 500
            from: 1
            to: 0
        }
    }
    //
    implicitWidth: 16
    implicitHeight: 16
    hoverEnabled: view
    acceptedButtons: view ? Qt.LeftButton : Qt.NoButton

    width: {
        const align = settings.alignment;
        return (align & Qt.AlignLeft && align & Qt.AlignRight) ?
                    undefined : settings.width
    }
    height: {
        const align = settings.alignment;
        return (align & Qt.AlignTop && align & Qt.AlignBottom) ?
                    undefined : settings.height
    }

    onEntered: if (view) view.currentHighlight = delegate
    onExited: if (view) view.currentHighlight = null
    onClicked: if (view) view.currentTarget = delegate
    //旋转重置
    onRotationEnabledChanged: settings.rotation=0
    //旋转
    Timer {
        repeat: true//重复定时
        interval: 1000 / (settings.rotationFPS ?? 20)//定时时间
        running: rotationEnabled&&widget.NVG.View.exposed//开始条件
        onTriggered: settings.rotation = (settings.rotation + rotationStep) % 360//触发语句
    }
}