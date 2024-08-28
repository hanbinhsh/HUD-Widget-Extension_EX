import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import NERvGear.Preferences 1.0

Preference {
    id: thiz

    property alias hint: input.placeholderText
    property alias validator: input.validator

    property var value

    horizontalPadding: 16
    topPadding: 8
    bottomPadding: 0

    load: function (newValue) { value = newValue; }
    save: function () { return value; }

    contentItem: RowLayout {
        spacing: thiz.spacing

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 3
            text: thiz.label
            wrapMode: Text.Wrap
        }

        GeometryEditorInput {
            id: input
            Layout.maximumWidth: 64
            topPadding: 2
            bottomPadding: 16

            valueText: thiz.value ?? ""
            onUpdateValue: { thiz.value = value; thiz.triggerPreferenceEdited(); }
        }
    }
}
