import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear.Controls 1.0
import NERvGear 1.0 as NVG

import com.gpbeta.common 1.0

import ".."
import "./PreferenceBase/"

// 一般设置
//必须资源
Flickable {
    property var item: null
    anchors.fill: parent
    contentWidth: width
    contentHeight: layoutColorSetting.height
    topMargin: 16
    bottomMargin: 16
    Column {
        id: layoutColorSetting
        width: parent.width
        ColorPreferenceBase{
            itemIn: item
        }
    }
}