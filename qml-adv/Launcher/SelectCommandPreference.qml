import NERvGear.Preferences 1.0

SelectPreference {
    name: "command"
    label: qsTr("Action")
    textRole: "label"
    defaultValue: 0

    load: function (newCommand) {
        let newValue = 0;

        if (newCommand !== undefined) {
            model.find(function (action, index) {
                if (action.command === newCommand) {
                    newValue = index;
                    return true;
                }
            });
        }

        value = newValue;
    }

    save: function () {
        return model[value]?.command;
    }
}
