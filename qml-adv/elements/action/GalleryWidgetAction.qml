import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0
import NERvGear.Templates 1.0 as T

T.Action {
    id: thiz

    readonly property var _actions: [
        { command: "pause", label: qsTr("Play / Pause"), execute: widget.toggleSlideshow },
        { command: "play", label: qsTr("Play"), execute: widget.playSlideshow },
        { command: "stop", label: qsTr("Stop"), execute: widget.stopSlideshow },
        { command: "next", label: qsTr("Next Image"), execute: ()=>widget.rollImage(true) },
        { command: "prev", label: qsTr("Previous Image"), execute: ()=>widget.rollImage(false) },
        { command: "refresh", label: qsTr("Refresh Gallery"), execute: ()=>widget.refreshGallery() },
    ]

    title: qsTr("Gallery Action")

    execute: function () {
        return new Promise(function (resolve, reject) {
            let action;
            let command;
            if (configuration) {
                command = configuration.command;
                action = _actions.find(item => item.command === command);
            }
            if (action) {
                action.execute();
                return resolve();
            } else { console.warn("invalid command:", command) }
            reject();
        });
    }

    preference: PreferenceGroup {
        SelectCommandPreference {
            model: _actions
        }
    }

}
