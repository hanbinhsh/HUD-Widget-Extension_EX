
const NoOperation = {
    cursorShape: Qt.ArrowCursor,
    prepare: ()=>{},
    execute: ()=>{}
};

const KeyMove = {
    cursorShape: Qt.SizeAllCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
        context.grid = 1;
    },
    executeX: function (pos, target) {
        context.moveX(context.alignX(pos.x, target), target.width,  target.settings);
    },
    executeY: function (pos, target) {
        context.moveY(context.alignY(pos.y, target), target.height, target.settings);
    }
};

const MouseMove = {
    cursorShape: Qt.SizeAllCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.moveX(context.alignX(pos.x, target), target.width,  target.settings);
        context.moveY(context.alignY(pos.y, target), target.height, target.settings);
    }
};

const SizeTop = {
    cursorShape: Qt.SizeVerCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.sizeTop(pos, target);
    }
};

const SizeBottom = {
    cursorShape: Qt.SizeVerCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.sizeBottom(pos, target);
    }
};

const SizeLeft = {
    cursorShape: Qt.SizeHorCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.sizeLeft(pos, target);
    }
};

const SizeRight = {
    cursorShape: Qt.SizeHorCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.sizeRight(pos, target);
    }
};



const SizeTopLeft = {
    cursorShape: Qt.SizeFDiagCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.sizeTop(pos, target);
        context.sizeLeft(pos, target);
    }
};

const SizeBottomLeft = {
    cursorShape: Qt.SizeBDiagCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.sizeBottom(pos, target);
        context.sizeLeft(pos, target);
    }
};

const SizeTopRight = {
    cursorShape: Qt.SizeBDiagCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.sizeTop(pos, target);
        context.sizeRight(pos, target);
    }
};

const SizeBottomRight = {
    cursorShape: Qt.SizeFDiagCursor,
    prepare: function (view, pos, target) {
        context.initialize(view, pos, target);
    },
    execute: function (pos, target) {
        context.sizeBottom(pos, target);
        context.sizeRight(pos, target);
    }
};


// private

const context = {
    minimumWidth: 10,
    minimumHeight: 10,
    initialize: function (view, pos, target) {
        this.x = pos.x;
        this.y = pos.y;
        this.width = target.width;
        this.height = target.height;
        this.view = view;
        this.grid = view.gridSnap ? view.gridSize : 1;

        this.mutableWidth = false;
        this.mutableHeight = false;

        const align = target.settings.alignment;
        const alignH = align & Qt.AlignHorizontal_Mask;
        const alignV = align & Qt.AlignVertical_Mask;

        if (alignH === Qt.AlignLeft) {
            this.moveX = function (value, width, settings) {
                settings.left = value;
            }
        } else if (alignH === Qt.AlignRight) {
            this.moveX = function (value, width, settings) {
                settings.right = this.view.width - value - width;
            }
        } else if (alignH === (Qt.AlignLeft | Qt.AlignRight)) {
            this.mutableWidth = true;
            this.moveX = function (value, width, settings) {
                settings.right = this.view.width - value - width;
                settings.left = value; // notice order
            }
        } else { // horizontal center
            this.moveX = function (value, width, settings) {
                // NOTE: use distance to target to avoid rounding issues
                settings.horizon = (settings.horizon ?? 0) + value - target.x;
            }
        }

        if (alignV === Qt.AlignTop) {
            this.moveY = function (value, height, settings) {
                settings.top = value;
            }
        } else if (alignV === Qt.AlignBottom) {
            this.moveY = function (value, height, settings) {
                settings.bottom = this.view.height - value - height;
            }
        } else if (alignV === (Qt.AlignTop | Qt.AlignBottom)) {
            this.mutableHeight = true;
            this.moveY = function (value, height, settings) {
                settings.bottom = this.view.height - value - height;
                settings.top = value; // notice order
            }
        } else { // vertical center
            this.moveY = function (value, height, settings) {
                // NOTE: use distance to target to avoid rounding issues
                settings.vertical = (settings.vertical ?? 0) + value - target.y;
            }
        }
    },
    normalize: function (value) {
        return Math.round(value / this.grid) * this.grid;
    },
    alignX: function (value, target) {
        if (this.grid < 2)
            return value;

        const alignL = this.normalize(value);
        const alignR = this.normalize(value + target.width) - target.width + 1;

        if (Math.abs(target.x - alignL) < Math.abs(target.x - alignR))
            return alignL;

        return alignR;
    },
    alignY: function (value, target) {
        if (this.grid < 2)
            return value;

        const alignT = this.normalize(value);
        const alignB = this.normalize(value + target.height) - target.height + 1;

        if (Math.abs(target.y - alignT) < Math.abs(target.y - alignB))
            return alignT;

        return alignB;
    },
    sizeTop: function (pos, target) {
        const top = this.normalize(pos.y);
        const height = this.y + this.height - top;
        if (height < this.minimumHeight)
            return;
        this.moveY(top, height, target.settings);
        if (!this.mutableHeight)
            target.settings.height = height;
    },
    sizeBottom: function (pos, target) {
        const bottom = this.normalize(this.height + pos.y);
        const height = bottom - this.y;
        if (height < this.minimumHeight)
            return;
        this.moveY(bottom - height, height, target.settings);
        if (!this.mutableHeight)
            target.settings.height = height;
    },
    sizeLeft: function (pos, target) {
        const left = this.normalize(pos.x);
        const width = this.x + this.width - left;
        if (width < this.minimumWidth)
            return;
        this.moveX(left, width, target.settings);
        if (!this.mutableWidth)
            target.settings.width = width;
    },
    sizeRight: function (pos, target) {
        const right = this.normalize(this.width + pos.x);
        const width = right - this.x;
        if (width < this.minimumWidth)
            return;
        this.moveX(right - width, width, target.settings);
        if (!this.mutableWidth)
            target.settings.width = width;
    }
};
