import QtQuick 2.12
import QtQuick.Controls 2.12

import NERvGear.Controls 1.0
//HUD Custom edit 界面上半
Item {
    id: editor

    property QtObject target
    readonly property var settings: target?.settings ?? {}

    implicitWidth: 320
    implicitHeight: inputs.implicitHeight + 6

    Rectangle {
        id: anchorBox
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.top: inputs.top
        anchors.topMargin: 8
//HUD Custom edit 界面左中偏上框框的背景颜色及大小 原90
        width: 60
        height: 60
        color: "#00FFFFFF"

        border.width: 2
        border.color: dialog.Style.dividerColor

        ItemDelegate {
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.left
            anchors.horizontalCenterOffset: 2
            padding: 8
            width: 19

            contentItem: Rectangle {
                id: leftHighlight
                color: dialog.Style.accentColor
                visible: settings.alignment & Qt.AlignLeft
            }

            onClicked: {
                if (leftHighlight.visible) {
//                    if ((settings.alignment & Qt.AlignHorizontal_Mask) !== Qt.AlignLeft)
                    settings.alignment &= ~Qt.AlignLeft;
                } else {
                    settings.left = undefined;
                    settings.alignment = (settings.alignment & ~Qt.AlignHCenter) | Qt.AlignLeft;
                }
            }
        }

        ItemDelegate {
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.right
            anchors.horizontalCenterOffset: -2
            padding: 8
            width: 19

            contentItem: Rectangle {
                id: rightHighlight
                color: dialog.Style.accentColor
                visible: settings.alignment & Qt.AlignRight
            }

            onClicked: {
                if (rightHighlight.visible) {
                    settings.alignment &= ~Qt.AlignRight;
                } else {
                    settings.right = undefined;
                    settings.alignment = (settings.alignment & ~Qt.AlignHCenter) | Qt.AlignRight;
                }
            }
        }

        ItemDelegate {
            anchors.verticalCenter: parent.top
            anchors.verticalCenterOffset: 2
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            padding: 8
            height: 19

            contentItem: Rectangle {
                id: topHighlight
                color: dialog.Style.accentColor
                visible: settings.alignment & Qt.AlignTop
            }

            onClicked: {
                if (topHighlight.visible) {
                    settings.alignment &= ~Qt.AlignTop;
                } else {
                    settings.top = undefined;
                    settings.alignment = (settings.alignment & ~Qt.AlignVCenter) | Qt.AlignTop;
                }
            }
        }

        ItemDelegate {
            anchors.verticalCenter: parent.bottom
            anchors.verticalCenterOffset: -2
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            padding: 8
            height: 19

            contentItem: Rectangle {
                id: bottomHighlight
                color: dialog.Style.accentColor
                visible: settings.alignment & Qt.AlignBottom
            }

            onClicked: {
                if (bottomHighlight.visible) {
                    settings.alignment &= ~Qt.AlignBottom;
                } else {
                    settings.bottom = undefined;
                    settings.alignment = (settings.alignment & ~Qt.AlignVCenter) | Qt.AlignBottom;
                }
            }
        }
    }

    

    Row {
        id:centerButton
        anchors.top: anchorBox.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: anchorBox.horizontalCenter
//HUD Custom edit界面的纵向居中
        ToolButton {
            id: hCenterButton
            icon.name: "light:\uf89d"
            highlighted: {
                const align = settings.alignment;

                // default to horizontal center
                if (!(align & Qt.AlignHorizontal_Mask))
                    return true;

                return !(align & Qt.AlignLeft || align & Qt.AlignRight);
            }

            onClicked: {
                if (highlighted)
                    return;
                settings.horizon = undefined;
                settings.alignment = (settings.alignment & Qt.AlignVertical_Mask) | Qt.AlignHCenter;
            }
        }
//HUD Custom edit界面的横向居中
        ToolButton {
            id: vCenterButton
            icon.name: "light:\uf89c"
            highlighted: {
                const align = settings.alignment;

                // default to vertical center
                if (!(align & Qt.AlignVertical_Mask))
                    return true;

                return !(align & Qt.AlignTop || align & Qt.AlignBottom);
            }

            onClicked: {
                if (highlighted)
                    return;
                settings.vertical = undefined;
                settings.alignment = (settings.alignment & Qt.AlignHorizontal_Mask) | Qt.AlignVCenter;
            }
        }
        
    }
    Row {
        anchors.top: centerButton.bottom
        anchors.horizontalCenter: anchorBox.horizontalCenter
//Z
        GeometryEditorLabel {
            text: "Z"
            width:45
            }
        GeometryEditorInput {
            width:30
            placeholderText: "0"
            valueText: settings.z ?? ""
            minValue: -99
            maxValue: 99
            onUpdateValue: settings.z = value
        }
    }

    Grid {
        id: inputs
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 6

        columns: 2
        columnSpacing: 4
        flow: Grid.TopToBottom
        verticalItemAlignment: Grid.AlignBottom

        Column {
            enabled: !(leftHighlight.visible && rightHighlight.visible)
//宽度
            GeometryEditorLabel { text: qsTr("Width") }
            GeometryEditorInput {
                valueText: (enabled ? settings.width : target?.width) ?? ""
                placeholderText: target?.implicitWidth ?? ""
                minValue: 10
                onUpdateValue: settings.width = value
            }
        }
//高度
        Column {
            enabled: !(topHighlight.visible && bottomHighlight.visible)

            GeometryEditorLabel { text: qsTr("Height") }
            GeometryEditorInput {
                valueText: (enabled ? settings.height : target?.height) ?? ""
                placeholderText: target?.implicitHeight ?? ""
                minValue: 10
                onUpdateValue: settings.height = value
            }
        }

        Row {
            visible: hCenterButton.highlighted

            GeometryEditorLabel { text: qsTr("Horizon", "offset") }

            GeometryEditorInput {
                valueText: settings.horizon ?? ""
                placeholderText: "0"
                onUpdateValue: settings.horizon = value
            }
        }

        Grid {
            visible: !hCenterButton.highlighted
            columns: 2

            GeometryEditorLabel {
                enabled: leftHighlight.visible
                text: qsTr("Left", "margin")
            }

            GeometryEditorInput {
                enabled: leftHighlight.visible
                valueText: settings.left ?? ""
                placeholderText: "0"
                onUpdateValue: settings.left = value
            }

            GeometryEditorLabel {
                enabled: rightHighlight.visible
                text: qsTr("Right", "margin")
            }

            GeometryEditorInput {
                enabled: rightHighlight.visible
                valueText: settings.right ?? ""
                placeholderText: "0"
                onUpdateValue: settings.right = value
            }
        }

        Row {
            visible: vCenterButton.highlighted

            GeometryEditorLabel { text: qsTr("Vertical", "offset") }

            GeometryEditorInput {
                valueText: settings.vertical ?? ""
                placeholderText: "0"
                onUpdateValue: settings.vertical = value
            }
        }

        Grid {
            visible: !vCenterButton.highlighted
            columns: 2

            GeometryEditorLabel {
                enabled: topHighlight.visible
                text: qsTr("Top", "margin");
            }

            GeometryEditorInput {
                enabled: topHighlight.visible
                valueText: settings.top ?? ""
                placeholderText: "0"
                onUpdateValue: settings.top = value
            }

            GeometryEditorLabel {
                enabled: bottomHighlight.visible
                text: qsTr("Bottom", "margin")
            }

            GeometryEditorInput {
                enabled: bottomHighlight.visible
                valueText: settings.bottom ?? ""
                placeholderText: "0"
                onUpdateValue: settings.bottom = value
            }
        }
    }
}

