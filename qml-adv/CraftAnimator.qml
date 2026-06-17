import QtQuick 2.12
import NERvGear 1.0 as NVG

// 可复用动画控制器。
//
// 集中 CraftDelegate 派生项（item 级的 HUDWidget 内联 delegate / element 级的 CraftElement）
// 原本逐字重复的悬停/点击/数据驱动动画对象与触发逻辑，消除两处重复。
//
// 职责边界：本组件只负责"动画"。涉及涟漪、音效、Action 触发、启动器开关、编辑态判断、
// currentTarget 设置等"功能性副作用"仍保留在各使用点自身的 MouseArea 处理器里——
// 它们各级行为不同，不属于可共享部分。
//
// 用法：
//   CraftAnimator {
//       id: animator
//       target: craftElement            // 被驱动的 CraftDelegate
//       settings: craftElement.settings // 设置表
//       viewExposed: craftElement.NVG.View.exposed
//   }
//   // 在 MouseArea 处理器中：animator.hoverEnter() / hoverExit() /
//   //   clickZoomSpinPress() / clickZoomSpinRelease() / clickMove()
//
// 说明：原代码用 `NumberAnimation on <prop>`（值源写法）作用于自身属性；移入控制器后
// 改用显式 `target/property` 写法驱动 target 上的同名属性，行为等价。
Item {
    id: animator

    // 被驱动的 CraftDelegate（需具备 animationX/Y、animationZoomX/Y、animationSpin、
    // moveDataX/Y、spinDataA、clickAnimationX/Y、clickMoveStatus、opacity 等属性，
    // 这些均由 CraftDelegate 基类声明）
    property Item target
    // 设置表（= target.settings / modelData）
    property var settings
    // 视图是否可见，作为数据动画 Timer 的运行门控（调用方绑定 <item>.NVG.View.exposed）
    property bool viewExposed: true

    // 点击移动进行中标志（原先在各使用点各自声明为 isAnimationRunning）
    property bool clickMoveActive: false

    width: 0; height: 0
    visible: false

    // ===== 悬停移动 =====
    NumberAnimation {
        id: moveAnimationX
        target: animator.target; property: "animationX"
        running: false
        duration: settings.moveHover_Duration ?? 300
        easing.type: settings.moveOnHover_Easing ?? 3
    }
    NumberAnimation {
        id: moveAnimationY
        target: animator.target; property: "animationY"
        running: false
        duration: settings.moveHover_Duration ?? 300
        easing.type: settings.moveOnHover_Easing ?? 3
    }

    // ===== 数据移动 =====
    NVG.DataSource {
        id: distanceDataSource
        configuration: (settings.dataAnimation && settings.dataAnimation_move && settings.moveData_Distance_data) ? settings.distanceData : null
    }
    NVG.DataSource {
        id: directionDataSource
        configuration: (settings.dataAnimation && settings.dataAnimation_move && settings.moveData_Direction_data) ? settings.directionData : null
    }
    NVG.DataSourceRawOutput {
        id: distanceData
        source: distanceDataSource
    }
    NVG.DataSourceRawOutput {
        id: directionData
        source: directionDataSource
    }
    NumberAnimation {
        id: moveDataX
        target: animator.target; property: "moveDataX"
        running: false
        duration: settings.moveData_Duration ?? 300
        easing.type: settings.moveData_Easing ?? 3
    }
    NumberAnimation {
        id: moveDataY
        target: animator.target; property: "moveDataY"
        running: false
        duration: settings.moveData_Duration ?? 300
        easing.type: settings.moveData_Easing ?? 3
    }
    Timer {
        repeat: true
        interval: settings.moveData_Trigger ?? 300
        running: Boolean(settings.dataAnimation && settings.dataAnimation_move) && animator.viewExposed
        onTriggered: {
            moveDataX.stop()
            moveDataX.to = Number(settings.moveData_Distance_data ? distanceData.result??0 : settings.moveData_Distance ?? 10)
            * Math.cos(Number(settings.moveData_Direction_data ? directionData.result??0 : settings.moveData_Direction ?? 0) * Math.PI / 180)
            moveDataX.start()
        }
    }
    Timer {
        repeat: true
        interval: settings.moveData_Trigger ?? 300
        running: Boolean(settings.dataAnimation && settings.dataAnimation_move) && animator.viewExposed
        onTriggered: {
            moveDataY.stop()
            moveDataY.to = -Number(settings.moveData_Distance_data ? distanceData.result??0 : settings.moveData_Distance ?? 10)
            * Math.sin(Number(settings.moveData_Direction_data ? directionData.result??0 : settings.moveData_Direction ?? 0) * Math.PI / 180)
            moveDataY.start()
        }
    }

    // ===== 数据旋转 =====
    NVG.DataSource {
        id: spinDataSource
        configuration: (settings.dataAnimation && settings.dataAnimation_spin) ? settings.spinData : null
    }
    NVG.DataSourceRawOutput {
        id: spinData
        source: spinDataSource
    }
    NumberAnimation {
        id: spinDataAnimation
        target: animator.target; property: "spinDataA"
        running: false
        duration: settings.spinData_Duration ?? 300
        easing.type: settings.spinData_Easing ?? 3
    }
    Timer {
        repeat: true
        interval: settings.spinData_Trigger ?? 300
        running: Boolean(settings.dataAnimation && settings.dataAnimation_spin) && animator.viewExposed
        onTriggered: {
            spinDataAnimation.stop()
            spinDataAnimation.to = spinData.result ?? 0
            spinDataAnimation.start()
        }
    }

    // ===== 点击移动 =====
    NumberAnimation {
        id: moveClickAnimationX
        target: animator.target; property: "clickAnimationX"
        running: false
        duration: settings.moveClick_Duration ?? 300
        easing.type: settings.moveClick_Easing ?? 3
    }
    NumberAnimation {
        id: moveClickAnimationY
        target: animator.target; property: "clickAnimationY"
        running: false
        duration: settings.moveClick_Duration ?? 300
        easing.type: settings.moveClick_Easing ?? 3
    }
    Connections {
        target: moveClickAnimationX
        onStopped: {
            if(!settings.moveBackAfterClick && animator.clickMoveActive) {
                animator.clickMoveActive = false
                moveClickAnimationX.stop()
                moveClickAnimationY.stop()
                moveClickAnimationX.to = 0
                moveClickAnimationY.to = 0
                moveClickAnimationX.running = true
                moveClickAnimationY.running = true
            }
            animator.clickMoveActive = false
        }
    }

    // ===== 缩放（悬停 + 点击）=====
    NumberAnimation {
        id: animationZoomX
        target: animator.target; property: "animationZoomX"
        running: false
        duration: settings.zoomHover_Duration ?? 300
        easing.type: settings.zoomHover_Easing ?? 3
    }
    NumberAnimation {
        id: animationZoomY
        target: animator.target; property: "animationZoomY"
        running: false
        duration: settings.zoomHover_Duration ?? 300
        easing.type: settings.zoomHover_Easing ?? 3
    }
    NumberAnimation {
        id: animationZoomX_Click
        target: animator.target; property: "animationZoomX"
        running: false
        duration: settings.zoomClick_Duration ?? 300
        easing.type: settings.zoomHover_Easing ?? 3
    }
    NumberAnimation {
        id: animationZoomY_Click
        target: animator.target; property: "animationZoomY"
        running: false
        duration: settings.zoomClick_Duration ?? 300
        easing.type: settings.zoomHover_Easing ?? 3
    }

    // ===== 旋转（悬停 + 点击）=====
    NumberAnimation {
        id: animationSpin_Normal
        target: animator.target; property: "animationSpin"
        running: false
        duration: settings.spinHover_Duration ?? 300
        easing.type: settings.spinHover_Easing ?? 3
    }
    NumberAnimation {
        id: animationSpin_Click
        target: animator.target; property: "animationSpin"
        running: false
        duration: settings.spinClick_Duration ?? 300
        easing.type: settings.spinClick_Easing ?? 3
    }

    // ===== 闪烁 =====
    SequentialAnimation {
        id: animationGlimmer
        running: false
        loops: Animation.Infinite
        NumberAnimation {
            target: animator.target
            property: "opacity"
            from: 1
            to: (settings.glimmerHover_MinOpacity ?? 0)/100
            duration: settings.glimmerHover_Duration ?? 300
            easing.type: settings.glimmerHover_Easing ?? 3
        }
        NumberAnimation {
            target: animator.target
            property: "opacity"
            from: (settings.glimmerHover_MinOpacity ?? 0)/100
            to: 1
            duration: settings.glimmerHover_Duration ?? 300
            easing.type: settings.glimmerHover_Easing ?? 3
        }
    }
    NumberAnimation {
        id: recoverOpacity
        target: animator.target
        property: "opacity"
        running: false
        from: animator.target ? animator.target.opacity : 1
        to: 1
        duration: 100
        easing.type: settings.glimmerHover_Easing ?? 3
    }

    // ===== 触发函数 =====
    // 悬停进入
    function hoverEnter() {
        if(settings.moveOnHover){
            moveAnimationX.stop(); moveAnimationY.stop()
            moveAnimationX.to =  Number(settings.moveHover_Distance??10) * Math.cos(Number(settings.moveHover_Direction??0) * Math.PI / 180)
            moveAnimationY.to = -Number(settings.moveHover_Distance??10) * Math.sin(Number(settings.moveHover_Direction??0) * Math.PI / 180)
            moveAnimationX.running = true; moveAnimationY.running = true
        }
        if(settings.zoomOnHover){
            animationZoomX.stop(); animationZoomY.stop()
            animationZoomX.to = Number(settings.zoomHover_XSize??100)
            animationZoomY.to = Number(settings.zoomHover_YSize??100)
            animationZoomX.running = true; animationZoomY.running = true
        }
        if(settings.spinOnHover){
            animationSpin_Normal.stop()
            animationSpin_Normal.to = Number(settings.spinHover_Direction??360)
            animationSpin_Normal.running = true
        }
        if(settings.glimmerOnHover){
            animationGlimmer.running = true
        }
    }
    // 悬停退出
    function hoverExit() {
        if(settings.moveOnHover){
            moveAnimationX.stop(); moveAnimationY.stop()
            moveAnimationX.to = 0; moveAnimationY.to = 0
            moveAnimationX.running = true; moveAnimationY.running = true
        }
        if(settings.zoomOnHover){
            animationZoomX.stop(); animationZoomY.stop()
            animationZoomX.to = 0; animationZoomY.to = 0
            animationZoomX.running = true; animationZoomY.running = true
        }
        if(settings.spinOnHover){
            animationSpin_Normal.stop()
            animationSpin_Normal.to = 0
            animationSpin_Normal.running = true
        }
        if(settings.glimmerOnHover){
            animationGlimmer.running = false
            recoverOpacity.start()
        }
    }
    // 点击按下：缩放 + 旋转
    function clickZoomSpinPress() {
        if(settings.zoomOnClick){
            animationZoomX_Click.stop(); animationZoomY_Click.stop()
            animationZoomX_Click.to = Number(settings.zoomClick_XSize ?? 100)
            animationZoomY_Click.to = Number(settings.zoomClick_YSize ?? 100)
            animationZoomX_Click.running = true; animationZoomY_Click.running = true
        }
        if(settings.spinOnClick){
            animationSpin_Click.stop()
            animationSpin_Click.to += Number(settings.spinClick_Direction??360)
            animationSpin_Click.running = true
        }
    }
    // 点击释放：恢复缩放 + 旋转
    function clickZoomSpinRelease() {
        if(settings.zoomOnClick){
            animationZoomX_Click.stop(); animationZoomY_Click.stop()
            animationZoomX_Click.to = settings.zoomOnHover ? Number(settings.zoomHover_XSize ?? 100) : 0
            animationZoomY_Click.to = settings.zoomOnHover ? Number(settings.zoomHover_YSize ?? 100) : 0
            animationZoomX_Click.running = true; animationZoomY_Click.running = true
        }
        if(settings.spinOnClick && !settings.spinOnClickInstantRecuvery){
            animationSpin_Click.stop()
            animationSpin_Click.to = 0
            animationSpin_Click.running = true
        }
    }
    // 点击移动
    function clickMove() {
        if(settings.moveOnClick && !animator.clickMoveActive){
            animator.clickMoveActive = true
            if(settings.moveBackAfterClick) {
                animator.target.clickMoveStatus = !animator.target.clickMoveStatus
            }
            moveClickAnimationX.stop(); moveClickAnimationY.stop()
            var distance = Number(settings.moveClick_Distance ?? 10)
            var direction = Number(settings.moveClick_Direction ?? 0)
            moveClickAnimationX.to = distance * Math.cos(direction * Math.PI / 180)
            moveClickAnimationY.to = -distance * Math.sin(direction * Math.PI / 180)
            moveClickAnimationX.running = true
            moveClickAnimationY.running = true
            if(settings.moveBackAfterClick && !animator.target.clickMoveStatus){
                moveClickAnimationX.stop(); moveClickAnimationY.stop()
                moveClickAnimationX.to = 0
                moveClickAnimationY.to = 0
                moveClickAnimationX.running = true
                moveClickAnimationY.running = true
            }
        }
    }
}
