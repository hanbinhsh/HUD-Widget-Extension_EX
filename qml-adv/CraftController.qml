import QtQuick 2.12

import "CraftController.js" as Controller

Wireframe {
    id: controller

    property CraftDelegate target
    property var opMouse: Controller.MouseMove
    property int opKey: 0
    //挂件外框的颜色
    anchors.fill: target
    color: "#FF0000"//2196F3
    anchorsVisible: activeFocus
    visible: target

    onTargetChanged: {
        opMouse = Controller.MouseMove;
        opKey = 0;
    }

    Keys.onPressed: {
        if (!target || mouseArea.pressed)
            return;

        if (event.key >= Qt.Key_Left && event.key <= Qt.Key_Down) {
            const control = Controller.KeyMove;

            if (opKey !== event.key) {
                opKey = event.key;
                dragHelper.x = target.x;
                dragHelper.y = target.y;
                control.prepare(craftView, dragHelper, target);
            }

            switch (opKey) {
            case Qt.Key_Left:  --dragHelper.x; control.executeX(dragHelper, target); break;
            case Qt.Key_Right: ++dragHelper.x; control.executeX(dragHelper, target); break;
            case Qt.Key_Up:    --dragHelper.y; control.executeY(dragHelper, target); break;
            case Qt.Key_Down:  ++dragHelper.y; control.executeY(dragHelper, target); break;
            }

        }
    }

    Keys.onReleased: if (!event.isAutoRepeat) opKey = 0

    function opMouseFor(area, mouse) {
        if (mouse.x < 5) {
            if (mouse.y < 5)
                return Controller.SizeTopLeft;
            else if (area.height - mouse.y < 5)
                return Controller.SizeBottomLeft;
            else
                return Controller.SizeLeft;
        } else if (area.width - mouse.x < 5) {
            if (mouse.y < 5)
                return Controller.SizeTopRight;
            else if (area.height - mouse.y < 5)
                return Controller.SizeBottomRight;
            else
                return Controller.SizeRight;
        } else {
            if (mouse.y < 5)
                return Controller.SizeTop;
            else if (area.height - mouse.y < 5)
                return Controller.SizeBottom;
        }
        return Controller.MouseMove;
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -2

        hoverEnabled: true
        cursorShape: opMouse.cursorShape

        drag {
            target: dragHelper
            axis: Drag.XAndYAxis
            threshold: 2
        }

        onPositionChanged: {
            if (drag.active) {
                // note that the drag target may be not aligned to a pixel
                const pos = { x: Math.round(dragHelper.x), y: Math.round(dragHelper.y) };
                opMouse.execute(pos, target);
            }

            if (!mouse.buttons) {
                const type = opMouseFor(this, mouse);
                if (opMouse !== type)
                    opMouse = type;
            }
        }

        onPressed: {
            if (target) {
                controller.forceActiveFocus();

                dragHelper.x = Math.round(target.x);
                dragHelper.y = Math.round(target.y);
                opMouse.prepare(craftView, dragHelper, target);
            }
        }
    }
}


