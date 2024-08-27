import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Control {
    id: thiz

    readonly property alias xGeometryInput: xInput
    readonly property alias yGeometryInput: yInput
    readonly property alias zGeometryInput: zInput

    property string xGeometryLabel: "X"
    property string yGeometryLabel: "Y"
    property string zGeometryLabel: "Z"

    horizontalPadding: 16
    verticalPadding: 0

    contentItem: GridLayout {
        columns: 2

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            text: xGeometryLabel
        }

        GeometryEditorInput {
            id: xInput
            Layout.maximumWidth: 64
        }

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            text: yGeometryLabel
        }

        GeometryEditorInput {
            id: yInput
            Layout.maximumWidth: 64
        }

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            text: zGeometryLabel
        }

        GeometryEditorInput {
            id: zInput
            Layout.maximumWidth: 64
        }
    }
}
