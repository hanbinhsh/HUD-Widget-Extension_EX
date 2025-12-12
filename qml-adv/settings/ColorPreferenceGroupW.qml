import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

import com.gpbeta.common 1.0

import ".."
import "./ColorPreferenceBase/"

P.PreferenceGroup {
    property var item: null

    ColorPreferenceBase{
        itemIn: item
    }
}