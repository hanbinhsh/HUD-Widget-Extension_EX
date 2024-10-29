import QtQuick 2.12

Item {
    id: craftView

    property alias model: repeater.model
    property alias delegate: repeater.delegate
    property alias count: repeater.count

    property LauncherItemTemplate currentTarget
    property LauncherItemTemplate currentHighlight

    // property int gridSize: 10
    // property bool gridSnap: true
    // property bool gridGuide: true

    property bool interactive: false

    // signal deleteRequest
    // signal deselectRequest

    focus: true

    // force to complete current editing,
    // must be handled before any other bindings
    // onCurrentTargetChanged: controller.forceActiveFocus();

    function targetAt(index) {
        return repeater.itemAt(index);
    }

    // GridBackground {
    //     anchors.fill: parent
    //     z: -99
    //     spacing: gridSize
    //     visible: interactive && gridGuide
    // }

    // Wireframe {
    //     anchors.fill: currentHighlight
    //     z: 255
    //     color: "#E91E63"
    //     rotation: currentHighlight?.rotation ?? 0
    //     transform: currentHighlight?.transformArray ?? null
    //     visible: interactive && currentHighlight
    //     anchorsVisible: true
    // }

    // CraftController {
    //     id: controller
    //     z: 256
    //     target: interactive ? currentTarget : null

    //     Keys.onEscapePressed: deselectRequest()
    //     Keys.onDeletePressed: deleteRequest()
    // }

    // Item {
    //     id: dragHelper
    //     width: 1
    //     height: 1
    //     visible: false
    // }

    Repeater { id: repeater }
}

