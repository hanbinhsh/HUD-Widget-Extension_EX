import QtQuick 2.12

Scale {
    property Item item
    property var config

    origin {
        x: {
            switch (config.origin) {
            case Item.Left:
            case Item.TopLeft:
            case Item.BottomLeft:
                return config.originX ?? 0;
            case Item.Right:
            case Item.TopRight:
            case Item.BottomRight:
                return item.width + (config.originX ?? 0);
            case Item.Center:
            default: break;
            }
            return item.width / 2 + (config.originX ?? 0);
        }
        y: {
            switch (config.origin) {
            case Item.Top:
            case Item.TopLeft:
            case Item.TopRight:
                return config.originY ?? 0;
            case Item.Bottom:
            case Item.BottomLeft:
            case Item.BottomRight:
                return item.height + (config.originY ?? 0);
            case Item.Center:
            default: break;
            }
            return item.height / 2 + (config.originY ?? 0);
        }
    }

    xScale: config.xScale ?? 1
    yScale: config.yScale ?? 1
}
