import QtQuick 2.12
import QtQuick.Shapes 1.12

Shape {
    id: shape

    property color color
    property bool anchorsVisible

    implicitWidth: 2
    implicitHeight: 2

    ShapePath { // frame
        fillColor: "transparent"
        strokeWidth: 1
        strokeColor: shape.color
        startX: .5
        startY: .5
        PathLine { relativeY: 0; relativeX: shape.width - .5 }
        PathLine { relativeX: 0; relativeY: shape.height - .5 }
        PathLine { relativeY: 0; relativeX: .5 - shape.width }
        PathLine { relativeX: 0; relativeY: .5 - shape.height }
    }

    Shape {
        anchors.fill: parent

        visible: anchorsVisible

        ShapePath { // top left
            fillColor: shape.color
            strokeWidth: 0
            strokeColor: "transparent"
            startX: -2
            startY: -2
            PathLine { relativeY: 0; relativeX: 5 }
            PathLine { relativeX: 0; relativeY: 5 }
            PathLine { relativeY: 0; relativeX: -5 }
        }

        ShapePath { // top right
            fillColor: shape.color
            strokeWidth: 0
            strokeColor: "transparent"
            startX: shape.width - 3
            startY: -2
            PathLine { relativeY: 0; relativeX: 5 }
            PathLine { relativeX: 0; relativeY: 5 }
            PathLine { relativeY: 0; relativeX: -5 }
        }

        ShapePath { // bottom right
            fillColor: shape.color
            strokeWidth: 0
            strokeColor: "transparent"
            startX: shape.width - 3
            startY: shape.height - 3
            PathLine { relativeY: 0; relativeX: 5 }
            PathLine { relativeX: 0; relativeY: 5 }
            PathLine { relativeY: 0; relativeX: -5 }
        }

        ShapePath { // bottom left
            fillColor: shape.color
            strokeWidth: 0
            strokeColor: "transparent"
            startX: -2
            startY: shape.height - 3
            PathLine { relativeY: 0; relativeX: 5 }
            PathLine { relativeX: 0; relativeY: 5 }
            PathLine { relativeY: 0; relativeX: -5 }
        }
    }


}
