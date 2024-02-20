import QtQuick 2.12
import QtQuick.Controls 2.12

TextField {

    property int minValue: -65535
    property int maxValue: 65535
    property string valueText

    signal updateValue(var value)

    // unbreakable binding
    Binding on text { value: valueText }

    width: 64
    topPadding: 0
    bottomPadding: 18
    horizontalAlignment: Label.AlignHCenter
    validator: IntValidator { bottom: minValue; top: maxValue }

    onFocusChanged: {
        if (!focus) {
            if (acceptableInput) {
                updateValue(Number(text));
            } else {
                if (text)
                    text = valueText;
                else // reset
                    updateValue(undefined);
            }
        }
    }

    onEditingFinished: focus = false
    Keys.onReturnPressed: focus = false
    Keys.onEscapePressed: focus = false
}

