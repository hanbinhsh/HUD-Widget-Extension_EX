import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Control {
    id: thiz

    readonly property alias xGeometryInput: xInput
    readonly property alias yGeometryInput: yInput

    property string text
    property string xGeometryLabel: "X"
    property string yGeometryLabel: "Y"

    horizontalPadding: 16
    topPadding: 8
    bottomPadding: 0

    contentItem: GridLayout {
        columns: 4
        columnSpacing: 4

        Label {
            Layout.fillWidth: true
            Layout.columnSpan: 4
            Layout.bottomMargin: 8
            text: thiz.text
        }

        GeometryEditorLabel {
            Layout.minimumWidth: 64
            Layout.alignment: Qt.AlignTop
            text: xGeometryLabel
        }

        GeometryEditorInput {
            id: xInput
            Layout.maximumWidth: 64
        }

        GeometryEditorLabel {
            Layout.minimumWidth: 64
            Layout.alignment: Qt.AlignTop
            text: yGeometryLabel
        }

        GeometryEditorInput {
            id: yInput
            Layout.maximumWidth: 64
        }
    }
}
