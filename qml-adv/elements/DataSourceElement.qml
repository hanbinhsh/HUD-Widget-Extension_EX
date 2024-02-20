import QtQuick 2.12

import NERvGear 1.0 as NVG

import com.gpbeta.common 1.0

HUDElementTemplate {
    id: thiz

    property var dataConfiguration

    // lazy data source creation
    readonly property NVG.DataSource dataSource: {
        // create element data source
        if (dataConfiguration) {
            if (this.elementDataSource_NB) {
                this.elementDataSource_NB.configuration = dataConfiguration;
            } else {
                const initProps = { configuration: dataConfiguration };
                Object.defineProperty(this, "elementDataSource_NB", {
                                          value: cDataSource.createObject(thiz, initProps),
                                          configurable: true
                                      });
            }
            return this.elementDataSource_NB;
        }

        // clean up element data source
        if (this.elementDataSource_NB) {
            this.elementDataSource_NB.destroy();
            delete this.elementDataSource_NB;
        }

        // use item data source
        return itemDataSource;
    }

}
