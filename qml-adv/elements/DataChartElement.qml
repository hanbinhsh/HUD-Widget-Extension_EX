import QtQuick 2.12

import NERvGear 1.0 as NVG

DataSourceElement {
    id: thiz

    readonly property int maxValues: Math.round(width / valueStep) - 1
    readonly property alias outputResult: output.result

    property int valueStep: 1
    property var values: []
    property int valueCount: -1

    property Canvas drawCanvas
    property bool fullRedraw

    clip: true
    implicitWidth: 64
    implicitHeight: 64
    dataConfiguration: settings.data

    onWidthChanged: fullRedraw = true
    onHeightChanged: fullRedraw = true
    onValueStepChanged: fullRedraw = true

    onFullRedrawChanged: if (fullRedraw) drawCanvas?.requestPaint()
    onDataSourceChanged: resetValues()
    onMaxValuesChanged:  {
        const deleteCount = values.length - maxValues;
        if (deleteCount > 0) {
            values.lastRemoved = values[deleteCount - 1];
            values.splice(0, deleteCount);
        }
    }

    function resetValues() {
        values.lastRemoved = 0;
        values.length = 0;
        valueCount = -1;
        fullRedraw = true;
    }

    Connections {
        target: thiz.dataSource

        onConfigurationChanged: resetValues()

        onUpdated: {
            if (thiz.dataSource.value.status !== NVG.DataSource.Ready)
                return;

            values.push(output.result);

            // truncate values
            if (values.length > maxValues + 1)
                values.lastRemoved = values.shift();
            // drawing out of canvas
            if (++valueCount >= maxValues) {
                valueCount = 0;
                fullRedraw = true;
            }

            drawCanvas.requestPaint();
        }
    }

    NVG.DataSourceProgressOutput {
        id: output

        source: thiz.dataSource
        dynamic: Boolean(thiz.settings.dynamic)

        onRangeChanged: {
            for (var i = 0; i < values.length; ++i)
                values[i] *= ratio;
            fullRedraw = true;
        }
    }
}
