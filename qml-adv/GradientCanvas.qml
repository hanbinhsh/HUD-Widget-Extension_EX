import QtQuick 2.12
import QtQuick.Window 2.12

Canvas {
    id: canvas

    property var stopAt: ()=>{}
    property int stopCount: 0

    property color strokeColor

    renderStrategy: Canvas.Cooperative
    renderTarget: Canvas.FramebufferObject

    onPaint: {
        const ctx = getContext("2d");
        const grad = ctx.createLinearGradient(0, 0, width, 0);
        for (let i = 0; i < stopCount; ++i) {
            const stop = stopAt(i);
            if (stop)
                grad.addColorStop(stop.position, stop.color);
        }
        ctx.fillStyle = grad;
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 2;
        ctx.clearRect(0, 0, width, height);
        ctx.fillRect(0, 0, width, height);
        ctx.strokeRect(1, 1, width - 1, height - 1);
    }
}

