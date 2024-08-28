import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import ".."

DataSourceElement {
    id: thiz

    readonly property color barColor: settings.barColor ?? "transparent"
    readonly property color scaleColor: settings.scaleColor ?? "transparent"

    readonly property real barMinLength: settings.barMinimum ?? 0
    readonly property real barExtLength: width - barMinLength

    readonly property var metaBorder: {
        const border = barImage._metaData["NVG:PatchBorder"];
        if (typeof border === 'string') {
            const b = border.split(' ', 4).map(e => parseInt(e));
            switch (b.length) {
            case 4: return { top: b[0], right: b[1], bottom: b[2], left: b[3] };
            case 3: return { top: b[0], right: b[1], bottom: b[2], left: b[1] };
            case 2: return { top: b[0], right: b[1], bottom: b[0], left: b[1] };
            case 1: return { top: b[0], right: b[0], bottom: b[0], left: b[0] };
            }
        }
        return { left: 0, right: 0, top: 0, bottom: 0 };
    }

    title: qsTranslate("utils", "Bar Gauge")
    implicitWidth: barImage.implicitWidth
    implicitHeight: barImage.implicitHeight
    dataConfiguration: settings.data

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.DataPreference {
            name: "data"
            label: qsTr("Data")
        }

        P.SwitchPreference {
            name: "animation"
            label: qsTr("Animate Data Changes")
        }

        P.ImagePreference {
            name: "barImage"
            label: qsTr("Bar Image")
        }

        Control {
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
                    text: qsTr("Image Border")
                }

                GeometryEditorLabel {
                    Layout.minimumWidth: 64
                    Layout.alignment: Qt.AlignTop
                    text: qsTr("Top")
                }

                GeometryEditorInput {
                    Layout.maximumWidth: 64
                    valueText: thiz.settings.barTop ?? ""
                    placeholderText: metaBorder.top
                    onUpdateValue: thiz.settings.barTop = value
                }

                GeometryEditorLabel {
                    Layout.minimumWidth: 64
                    Layout.alignment: Qt.AlignTop
                    text: qsTr("Left")
                }

                GeometryEditorInput {
                    Layout.maximumWidth: 64
                    valueText: thiz.settings.barLeft ?? ""
                    placeholderText: metaBorder.left
                    onUpdateValue: thiz.settings.barLeft = value
                }

                GeometryEditorLabel {
                    Layout.minimumWidth: 64
                    Layout.alignment: Qt.AlignTop
                    text: qsTr("Bottom")
                }

                GeometryEditorInput {
                    Layout.maximumWidth: 64
                    valueText: thiz.settings.barBottom ?? ""
                    placeholderText: metaBorder.bottom
                    onUpdateValue: thiz.settings.barBottom = value
                }

                GeometryEditorLabel {
                    Layout.minimumWidth: 64
                    Layout.alignment: Qt.AlignTop
                    text: qsTr("Right")
                }

                GeometryEditorInput {
                    Layout.maximumWidth: 64
                    valueText: thiz.settings.barRight ?? ""
                    placeholderText: metaBorder.right
                    onUpdateValue: thiz.settings.barRight = value
                }
            }
        }

        P.SelectPreference {
            name: "barTileH"
            label: qsTr("Image Horizontal Tile")
            model: [ qsTr("Stretch"), qsTr("Repeat"), qsTr("Round") ]
            defaultValue: 0
        }

        P.SelectPreference {
            name: "barTileV"
            label: qsTr("Image Vertical Tile")
            model: [ qsTr("Stretch"), qsTr("Repeat"), qsTr("Round") ]
            defaultValue: 0
        }

        P.SpinPreference {
            name: "barMinimum"
            label: qsTr("Minimum Bar Length")
            defaultValue: 0
            from: 0
            to: 999
            stepSize: 1
            editable: true
            display: P.TextFieldPreference.ExpandLabel
        }

        NoDefaultColorPreference {
            name: "barColor"
            label: qsTr("Bar Color")
            defaultValue: "transparent"
        }

        P.SwitchPreference {
            id: pScale
            name: "scale"
            label: qsTr("Draw Scales")
            defaultValue: true
        }

        NoDefaultColorPreference {
            name: "scaleColor"
            label: qsTr("Scales Color")
            defaultValue: "transparent"
            enabled: pScale.value
        }
    }

    Loader {
        anchors.fill: parent
        active: thiz.settings.scale ?? true
        sourceComponent: Item {
            Image {
                anchors.verticalCenter: parent.verticalCenter
                x: 0
                source: "../../Images/bar-scale-l.png"
            }

            Image {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round((parent.width - implicitWidth * 2) / 4)
                source: "../../Images/bar-scale-s.png"
            }

            Image {
                anchors.centerIn: parent
                source: "../../Images/bar-scale-m.png"
            }

            Image {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round((parent.width * 3 - implicitWidth * 2) / 4)
                source: "../../Images/bar-scale-s.png"
            }

            Image {
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width - implicitWidth
                source: "../../Images/bar-scale-l.png"
            }

            BorderImage {
                anchors.centerIn: parent

                border { left: 5; right: 5; top: 3; bottom: 3 }

                width: parent.width

                source: "../../Images/bar-background.png"
            }

            layer.enabled: visible && scaleColor.a
            layer.effect: ColorOverlayEffect { color: scaleColor }
        }
    }

    BorderImage {
        id: barImage
        anchors.verticalCenter: parent.verticalCenter

        border {
            left: thiz.settings.barLeft ?? metaBorder.left
            right: thiz.settings.barRight ?? metaBorder.right
            top: thiz.settings.barTop ?? metaBorder.top
            bottom: thiz.settings.barBottom ?? metaBorder.bottom
        }

        x: 0
        width: barMinLength + barExtLength * output.result
        height: implicitHeight < 16 ? thiz.height - 16 + implicitHeight : thiz.height
        cache: false
        horizontalTileMode: thiz.settings.barTileH ?? BorderImage.Stretch
        verticalTileMode: thiz.settings.barTileV ?? BorderImage.Stretch
        source: Qt.resolvedUrl(thiz.settings.barImage ?? "../../Images/bar.png")

        Behavior on width {
            enabled: ctx_widget.exposed && Boolean(thiz.settings.animation)
            NumberAnimation { easing.type: Easing.OutQuad; duration: 250 }
        }

        layer.enabled: barColor.a
        layer.smooth: true
        layer.effect: ColorOverlayEffect { color: barColor }
    }

    NVG.DataSourceProgressOutput {
        id: output
        source: thiz.dataSource
    }
}
