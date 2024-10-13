import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0

ItemPreference {
    id: thiz

    property var value

    // private

    readonly property var effectiveStops: Array.isArray(value) ? value :
                                          Array.isArray(defaultValue) ? defaultValue : []

    property var currentStopIndex // always notify when assigning
    property bool removeCurrentStop: false

    load: function (newValue) { value = newValue; }
    save: function () { return value; }

    select: function () {
        stopsModel.clear();

        effectiveStops.forEach(function (stop) {
            try {
                stopsModel.append({ position: stop.position, color: stop.color.toString() });
            } catch (err) { console.warn(err); }
        });

        if (!stopsModel.count) {
            stopsModel.append({ color: "black", position: 0 });
            stopsModel.append({ color: "white", position: 1 });
        }

        currentStopIndex = 0;

        dialog.open();
    }

    actionItem: Item {
        width: 40
        height: 32

        GradientCanvas {
            id: previewCanvas
            anchors.centerIn: parent

            width: 40
            height: 24

            strokeColor: thiz.Style.dividerColor
            stopCount: effectiveStops.length
            stopAt: (index)=>effectiveStops[index]
        }
    }

    onEffectiveStopsChanged: previewCanvas.requestPaint()
    onCurrentStopIndexChanged: pStopColor.load(stopsModel.get(currentStopIndex).color)

    ListModel { id: stopsModel }

    Dialog {
        id: dialog
        anchors.centerIn: parent

        modal: true
        parent: Overlay.overlay
        standardButtons: Dialog.Ok | Dialog.Reset
        title: thiz.label

        onReset: done(Dialog.Reset)
        onClosed: {
            if (result === Dialog.Accepted) {
                const stops = [];

                for (let i = 0; i < stopsModel.count; ++i) {
                    const stop = stopsModel.get(i);
                    stops.push({ position: stop.position, color: stop.color.toString() });
                }

                thiz.value = stops.sort((a, b)=>a.position - b.position);
                thiz.triggerPreferenceEdited();
            } else if (result === Dialog.Reset) {
                thiz.value = undefined;
                thiz.triggerPreferenceEdited();
            }
        }

        ColumnLayout {

            GradientCanvas {
                id: canvas
                Layout.fillWidth: true
                Layout.minimumHeight: 50
                Layout.topMargin: 48
                Layout.bottomMargin: 16
                Layout.leftMargin: 12
                Layout.rightMargin: 12

                implicitWidth: 320

                strokeColor: dialog.Style.dividerColor
                stopCount: stopsModel.count
                stopAt: function (index) {
                    if (index === currentStopIndex && removeCurrentStop)
                        return null;
                    return stopsModel.get(index);
                }

                Repeater {
                    model: stopsModel
                    delegate: MouseArea {
                        id: mouseArea
                        anchors.bottom: canvas.top
                        anchors.bottomMargin: 16

                        // 修改
                        acceptedButtons: Qt.AllButtons

                        x: model.position * canvas.width - colorCircle.radius
                        z: currentStopIndex === model.index ? 1 : 0
                        width: 22
                        height: 22

                        hoverEnabled: true
                        cursorShape: Qt.SizeAllCursor

                        drag {
                            target: dragHelper
                            axis: Drag.XAxis
                            threshold: 0
                            minimumX: 0
                            maximumX: canvas.width
                        }

                        onPositionChanged: {
                            if (!pressed)
                                return;

                            if (stopsModel.count > 1) {
                                colorCircle.visible = mouse.y > -height;
                                removeCurrentStop = !colorCircle.visible;
                            }

                            const pos = Math.round(dragHelper.x * 100 / canvas.width) / 100;
                            stopsModel.setProperty(index, "position", pos);
                            canvas.requestPaint();
                        }

                        // 修改
                        onPressed: {
                            if(mouse.button===Qt.LeftButton){
                                currentStopIndex = index;
                                dragHelper.x = x + colorCircle.radius;
                            }else if(mouse.button===Qt.RightButton){
                                if (stopsModel.count > 1) {
                                    currentStopIndex = 0;
                                    canvas.requestPaint();
                                    stopsModel.remove(index);
                                }
                            }
                        }

                        onReleased: {
                            if (removeCurrentStop) {
                                removeCurrentStop = false;
                                currentStopIndex = 0;
                                canvas.requestPaint();
                                stopsModel.remove(index);
                            }
                        }

                        onDoubleClicked: pStopColor.select()

                        Rectangle {
                            id: colorCircle
                            anchors.fill: parent

                            color: model.color
                            radius: width / 2

                            border {
                                width: 1
                                color: dialog.Style.frameColor
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -8
                                color: dialog.Style.rippleColor
                                radius: width / 2
                                visible: mouseArea.containsMouse
                            }

                            Label {
                                anchors.top: parent.bottom
                                anchors.topMargin: -9
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\uf0d7"
                                visible: currentStopIndex === index
                                font.bold: true
                                font.pixelSize: 19
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        const pos = Math.round(mouse.x * 100 / width) / 100;
                        stopsModel.append({ color: "black", position: pos });
                        currentStopIndex = stopsModel.count - 1;
                        canvas.requestPaint();
                    }
                }

                Item { id: dragHelper; width: 1; height: 1; visible: false }
            }

            ColorPreference {
                id: pStopColor
                Layout.fillWidth: true
                label: qsTr("Stop Color")
                onPreferenceEdited: {
                    stopsModel.setProperty(currentStopIndex, "color", save());
                    canvas.requestPaint();
                }
            }
        }
    }
}
