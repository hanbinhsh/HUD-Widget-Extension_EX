import QtQuick 2.12

import NERvGear 1.0 as NVG

NVG.BackgroundSource {
   id: thiz

   property color color

   layer.enabled: color.a
   layer.smooth: true
   layer.effect: ColorOverlayEffect { color: thiz.color }
}
