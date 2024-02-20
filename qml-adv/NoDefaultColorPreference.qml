import NERvGear.Preferences 1.0

ColorPreference {
    readonly property color defaultColor: defaultValue
    // TODO: Preference.saveDefaultValue property?
    save: function () {
        if (defaultColor === value)
            return;
        return value.toString();
    }
}
