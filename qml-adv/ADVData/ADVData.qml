import NERvGear.Templates 1.0 as T
import NERvGear.Preferences 1.0 as P
import QtQml 2.3

import "../../../top.mashiros.widget.advp/qml/" as ADVP

T.Data {
    id: advdata

    title: qsTr("ADV Data")
    property int valADV: 0

    T.Value {
        id: advv
        name: "aDVData"
        title: qsTr("ADV Data")

        interval: 1000

        minimum: 0
        maximum: 100
        current: 0

        update.execute: function () {
            current = valADV;
            status = T.Value.Ready;
        }

        update.preference: P.PreferenceGroup {
            P.SelectPreference {
                name: "aDVSample"
                label: qsTr("Sample")
                model: [ qsTr("128"), qsTr("64"), qsTr("32"), qsTr("16"), qsTr("8"), qsTr("4") ]
                defaultValue: 0
            }
            P.SelectPreference {
                id: channel
                name: "channel"
                label: qsTr("Channel")
                model: [ qsTr("All"), qsTr("Left"), qsTr("Right"), qsTr("Custom") ]
                defaultValue: 0
            }
            P.SpinPreference {
                name: "left"
                label: qsTr("left")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: channel.value === 3
                defaultValue: 0
                from: 0
                to: 127
                stepSize: 1
            }
            P.SpinPreference {
                name: "right"
                label: qsTr("right")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                visible: channel.value === 3
                defaultValue: 127
                from: 0
                to: 127
                stepSize: 1
            }
            P.SpinPreference {
                name: "decrease"
                label: qsTr("Decrease")
                editable: true
                display: P.TextFieldPreference.ExpandLabel
                defaultValue: 1000
                from: 0
                to: 100000
                stepSize: 100
            }
        }

        readonly property var config: (advv.update.configuration instanceof Object) ? advv.update.configuration : {}

        function updatedAudioData(audioData) {
            let lc = 0;
            let rc = 128;
            switch(config?.channel ?? 0){
                case 0: lc = 0;rc = 128;break;
                case 2: lc = 0;rc = 64;break;
                case 1: lc = 64;rc = 128;break;
                case 3: 
                    if(config.left<config.right){
                        lc = config.left;
                        rc = config.right;
                    }else{
                        lc = config.right;
                        rc = config.left;
                    }
                    break;
                default: lc = 0;rc = 128;break;
            }
            let v = 0;
            let s = Math.pow(2, config?.aDVSample ?? 0)
            for (let i=lc;i<rc;i+=s) {
                v += audioData[i]
            }
            valADV = v*5/((rc-lc)/s)/((config?.decrease ?? 1000)/1000)
        }
    }

    Component.onCompleted: {
        // 创建并加载 Connections 对象
        var component = Qt.createComponent("Conn.qml");

        // 如果已经就绪，立即创建对象
        if (component.status === Component.Ready) {
            createConnectionObject(component);
        } 
        // 如果还未加载完毕，监听状态变化
        else if (component.status === Component.Loading) {
            component.statusChanged.connect(function() {
                if (component.status === Component.Ready) {
                    createConnectionObject(component);
                } else if (component.status === Component.Error) {
                    console.log("Error loading Conn.qml: " + component.errorString());
                }
            });
        } else {
            console.log("Error loading Conn.qml: " + component.errorString());
        }
    }

    function createConnectionObject(component) {
        var connectionHelper = component.createObject(advdata); // 使用 advdata 作为父对象
        if (connectionHelper === null) {
            console.log("Error creating Conn object");
        }
    }
}