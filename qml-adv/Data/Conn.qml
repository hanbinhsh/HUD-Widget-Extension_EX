import QtQuick 2.12

import "../../../top.mashiros.widget.advp/qml/" as ADVP

Connections {
    // 仅当该 ADV 数据值真正被配置使用时才连接音频信号，且对 advv 做空值保护——
    // 避免在数据源的临时/元数据实例（上下文可能已失效）上评估，产生
    // "invalid context" / TypeError 警告，同时未使用时不做无谓计算。
    enabled: Boolean(advv && advv.update && advv.update.configuration)
    target: ADVP.Common
    onAudioDataUpdated: if (advv) advv.updatedAudioData(audioData) // 使用外部传入的 advdata
}
