import QtQuick 2.12
import QtQuick.Controls 2.12

import NERvGear 1.0 as NVG
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."
import "../impl" as Impl
import "../utils.js" as Utils

DataSourceElement {
    id:  thiz
    // private: ref CraftElement, CraftDdialog

    readonly property string labelText: elementLabel || defaultLabel
    // export for CraftElement
    readonly property bool independentInteractionArea: settings.interactive === 2

    title: qsTranslate("utils", "Fusion")
    implicitWidth: 64
    implicitHeight: 64

    dataConfiguration: settings.data

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.SelectPreference {
            id: pInteractive
            name: "interactive"
            label: qsTr("Interactive Area")
            model: [ qsTr("<Default>"), qsTr("Item"), qsTr("Independent") ]
            defaultValue: 0
        }

        P.DataPreference {
            name: "data"
            label: qsTr("Data")
            environment: thiz.environment
        }

        P.ActionPreference {
            name: "action"
            label: qsTr("Action")
            enabled: pInteractive.value === 2
            environment: thiz.environment
        }

        ToolButton {
            flat: true
            leftPadding: 18
            text: qsTr("Edit Elements...")
            icon.name: "regular:\uf044"
            onClicked: {
                editor.active = true;
                editor.item.targetItem = craftElement;
                editor.item.targetData = thiz.dataSource;
                editor.item.targetText = thiz.labelText;
                const settings = Impl.Settings.duplicateMap(craftElement.settings, elementView.model);
                editor.item.targetSettings = settings;
                editor.item.craftSettings = widget.tempCraftSettings;
                editor.item.show();
            }
        }

        Loader {
            id: editor
            active: false
            sourceComponent: CraftDialog {
                fuseMode: true
                onAccepted: {
                    const oldSettings = craftElement.settings;
                    elementView.model.set(craftElement.index, targetSettings);
                    targetSettings = null;
                    try { // NOTE: old settings not always destructable
                        oldSettings.destroy();
                    } catch (err) {}
                }

                onClosed: {
                    if (targetSettings) {
                        const oldSettings = targetSettings;
                        targetSettings = null; // clear before destroy
                        oldSettings.destroy();
                    }
                }
            }
        }
    }

    Connections {
        target: craftElement
        enabled: independentInteractionArea && !ctx_widget.editing
        onPressed: {
            switch (widget.defaultSettings.feedback) {
            case 2: return; // never
            case 1: break;  // always
            case 0:         // auto
            default: if (!actionSource.status) return;
            }
            NVG.SystemCall.playSound(NVG.SFX.FeedbackClick);
        }
        onClicked: {
            if (actionSource.configuration)
                actionSource.trigger(thiz);
        }
    }

    NVG.ActionSource {
        id: actionSource
        text: thiz.elementLabel || this.title
        environment: thiz.environment
        configuration: thiz.settings.action
    }

    Repeater {
        model: NVG.Settings.makeList(craftElement.settings, "elements")
        delegate: CraftElement {
            itemSettings: craftElement.itemSettings
            itemBackground: craftElement.itemBackground
            itemArea: craftElement.itemArea
            itemData: craftElement.itemData
            defaultData: thiz.dataSource
            defaultText: thiz.labelText
            superArea: craftElement.interactionArea
            interactionArea: { // override
                if (this.interactionIndependent)
                    return this;
                switch (thiz.settings.interactive) {
                case 2: return craftElement;
                case 1: return craftElement.itemArea;
                default: break;
                }
                return craftElement.interactionArea;
            }
            interactionSource: modelData.interaction ?? ""
            interactionSettingsBase: modelData
            environment: Utils.elementEnvironment(this, thiz.environment)
            settings: modelData
            index: model.index
        }
    }
}
