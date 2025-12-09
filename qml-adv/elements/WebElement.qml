import QtQuick 2.12
import QtQuick.Controls 2.12
import NERvGear 1.0 as NVG
import NERvGear.Dialogs 1.0 as D
import NERvGear.Templates 1.0 as T
import NERvWebKit 1.0
import NERvGear.Preferences 1.0 as P


DataSourceElement {

    id:  thiz

    title: qsTranslate("utils", "Web Content")
    implicitWidth: 128
    implicitHeight: 128

    dataConfiguration: settings.data

    preference: P.ObjectPreferenceGroup {
        defaultValue: thiz.settings
        syncProperties: true

        P.TextAreaPreference {
            name: "url"
            label: qsTr("URL")
        }

        P.SwitchPreference {
            name: "allowPopupWindow"
            label: qsTr("Allow Popup Window")
        }
    }

    WebView {
        id: view
        anchors.fill: parent

        readonly property int widgetMenuAction: WebView.WebActionUserFirst + 1

        settings {
            backgroundColor: "transparent"
            localContentCanAccessFileUrls: true
            localContentCanAccessRemoteUrls: true
        }

        url: thiz.settings.url || "../../Images/default.png"

        onContextMenuRequested: {
            request.external = true;
            items.unshift({ type: "separator" });
            items.unshift({ type: "item",
                            text: qsTr("Widget Menu"),
                            icon: { name: "regular:\uf0c9" },
                            action: widgetMenuAction });
        }

        onNewViewRequested: {
            if (!thiz.settings.allowPopupWindow) {
                request.openIn(view);
                request.accepted = true;
            }
        }

        onUserActionTriggered: {
            if (action === widgetMenuAction)
                widget.popupMenu();
        }
    }
}