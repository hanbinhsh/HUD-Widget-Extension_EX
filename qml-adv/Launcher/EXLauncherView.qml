import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.2
import QtGraphicalEffects 1.12 
import NERvGear 1.0 as NVG

import "."
import "../../../top.mashiros.widget.advp/qml/" as ADVP
import "../utils.js" as Utils
import ".."

NVG.View {
    id: eXLauncherView
    property bool isVisible: false  // 用于接收外部的 visible 状态
    property var itemGenerator: eXLItemView
    opacity: 0.0  // 初始 opacity 为 0
    z: eXLSettings.viewZ ?? 0
    y: eXLSettings.viewY ?? 0
    x: eXLSettings.viewX ?? 0
    width: eXLSettings.viewW ?? Screen.width
    height: eXLSettings.viewH ?? Screen.height
    color: eXLSettings.viewBGColor ?? "#777777"
    signal vChanged
    signal showItem(int i)
    signal hideItem(int i)
    signal toggleItem(int i)
    signal ready
    signal dialogClosing
    property NVG.SettingsMap eXLSettings: NVG.Settings.load("com.hanbinhsh.widget.hud_edit", "eXLSettings", eXLauncherView);
    readonly property var initialFont: ({ family: "Source Han Sans SC", pixelSize: 24 })
    Component.onCompleted: {
        init()
        ready()
    }
    function init(){
        const object = NVG.Settings.load("com.hanbinhsh.widget.hud_edit", "eXLSettings", eXLauncherView);
        if (object instanceof NVG.SettingsMap){
            eXLSettings = object;
        }else{
            eXLSettings = NVG.Settings.createMap(eXLauncherView)
            NVG.Settings.save(eXLSettings, "com.hanbinhsh.widget.hud_edit", "eXLSettings")
        }
    }
    function toggleSetting() {
        dialog.active = true
    }
    Loader {
        id: dialog
        active: false
        sourceComponent: EXLDialog{
            onClosing: {
                dialog.active = false
                dialogClosing()
            }
        }
    }
    QtObject { // Public API
        id: ctx_widget
        readonly property font defaultFont: Qt.font(initialFont)
        readonly property var defaultBackground: Utils.NormalBackground
        readonly property color defaultBackgroundColor:  "transparent"
        readonly property color defaultTextColor: "#BBFFFFFF"
        readonly property color defaultStyleColor: "#33FFFFFF"
        readonly property bool exposed: isVisible
        readonly property bool editing: isVisible
    }
    //////////////////////////////////Actions//////////////////////////////////
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onClicked: {
            if (mouse.button === Qt.LeftButton) {
                switch(eXLSettings.leftClickEvent ?? 3){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionL.configuration)
                            actionL.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
                switch(eXLSettings.leftClickEvent2 ?? 3){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionL.configuration)
                            actionL.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
            }
            if (mouse.button === Qt.RightButton) {
                switch(eXLSettings.rightClickEvent ?? 0){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionR.configuration)
                            actionR.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
                switch(eXLSettings.rightClickEvent2 ?? 3){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionR.configuration)
                            actionR.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
            }
            if (mouse.button === Qt.MiddleButton) {
                switch(eXLSettings.middleClickEvent ?? 1){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionM.configuration)
                            actionM.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
                switch(eXLSettings.middleClickEvent2 ?? 3){
                    case 0: {isVisible = false; break;}
                    case 1: {dialog.active = true; break;}
                    case 2: {
                        if (actionM.configuration)
                            actionM.trigger(eXLauncherView); break;
                    };
                    default: break;
                }
            }
        }
    }
    NVG.ActionSource {
        id: actionL
        configuration: eXLSettings.action_L
    }
    NVG.ActionSource {
        id: actionR
        configuration: eXLSettings.action_R
    }
    NVG.ActionSource {
        id: actionM
        configuration: eXLSettings.action_M
    }
    //////////////////////////////////Actions//////////////////////////////////
    //////////////////////////////////ADV//////////////////////////////////
    Connections {
        enabled: Boolean((eXLSettings.aDVConnection)&&isVisible)
        target: ADVP.Common
        onAudioDataUpdated: updatedAudioData(audioData)
    }
    function updatedAudioData(audioData) {
        let v = 0;
        let s = Math.pow(2,eXLSettings.eXLADVSample ?? 0)
        for (let i=0;i<128;i+=s) {
            v += audioData[i]
        }
        opaADV = v*5/(128/s)
    }
    property int opaADV: 0
    //////////////////////////////////ADV//////////////////////////////////
    //////////////////////////////////Generator//////////////////////////////////
    Component { // any items with settings property
        id: cScaleTransform
        ConfigurableScale { config: item.settings.scale ?? {} }
    }
    Component { // any items with settings property
        id: cRotateTransform
        ConfigurableRotation { config: item.settings.rotate ?? {} }
    }
    Component {
        id: cDataSource
        NVG.DataSource {}
    }
    Component {
        id: cDataRawOutput
        NVG.DataSourceRawOutput {
            source: NVG.DataSource {}
        }
    }
    NVG.DataSource {
        id: dataSource
        configuration: eXLSettings.data
    }
    
    CraftItem{
        id: eXLItemView
        anchors.fill: parent
        readonly property NVG.SettingsMap settings: eXLSettings
        model: NVG.Settings.makeList(eXLSettings, "items")
        signal copyRequest
        signal pasteRequest
        signal deleteRequest
        signal deselectRequest
        Shortcut {
            sequence: "Ctrl+C"
            autoRepeat: false
            onActivated: copyRequest()
        }

        Shortcut {
            sequence: "Ctrl+V"
            autoRepeat: false
            onActivated: pasteRequest()
        }

        delegate: LauncherItemTemplate{
            id: thiz
            index: model.index
            settings: modelData
            readonly property NVG.DataSource dataSource: dataSource
            view: eXLItemView
            
            Item {
                anchors.fill: parent
                ColorBackgroundSource {id: bgSource}
                parent: thiz
                Repeater {
                    model: NVG.Settings.makeList(modelData, "elements")
                    delegate: CraftElement {
                        itemSettings: thiz.settings
                        itemData: dataSource
                        itemBackground: bgSource
                        settings: modelData
                        index: model.index
                    }
                }
            }
        }
        Connections {
            enabled: true
            target: eXLauncherView
            onDialogClosing: {
                eXLItemView.currentTarget = null
            }
        }
    }
    //////////////////////////////////Generator//////////////////////////////////
    //////////////////////////////////Animations//////////////////////////////////
    // 当 isVisible 改变时触发动画
    onIsVisibleChanged: {
        vChanged()
        if (isVisible) {
            hideAnimation.stop()
            eXLauncherView.visible = true  // 仅当需要显示时将 visible 设为 true
            showAnimation.start()
        } else {
            showAnimation.stop()
            hideAnimation.start()
        }
    }
    SequentialAnimation {
        id: hideAnimation
        running: false
        PauseAnimation { duration: eXLSettings.hidePause ?? 0 }
        NumberAnimation { target: eXLauncherView; property: "opacity"; to: 0; duration: eXLSettings.showhideDuration ?? 300 }
        ScriptAction {
            script: {
                eXLauncherView.visible = false  // 当动画完成时隐藏组件
            }
        }
    }
    SequentialAnimation {
        id: showAnimation
        running: false
        PauseAnimation { duration: eXLSettings.showPause ?? 0 }
        NumberAnimation { target: eXLauncherView; property: "opacity"; to: eXLSettings.viewO ? eXLSettings.viewO/100.0 : 1.0; duration: eXLSettings.showhideDuration ?? 300 }
    }
    //////////////////////////////////Animations//////////////////////////////////
}

