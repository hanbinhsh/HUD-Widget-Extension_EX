import QtQuick 2.12

import "../../../top.mashiros.widget.advp/qml/" as ADVP

Connections {
    enabled: true
    target: ADVP.Common
    onAudioDataUpdated: advv.updatedAudioData(audioData) // 使用外部传入的 advdata
}