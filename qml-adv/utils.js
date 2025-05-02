.pragma library

const TransformOriginNames = [
    qsTr("Top Left"),    qsTr("Top"),    qsTr("Top Right"),
    qsTr("Left"),        qsTr("Center"), qsTr("Right"),
    qsTr("Bottom Left"), qsTr("Bottom"), qsTr("Bottom Right")
];

// TODO: store value type?
const NormalBackground = Qt.resolvedUrl("../Images/background/GGO-Status.9.png")
const HoveredBackground = Qt.resolvedUrl("../Images/background/GGO-Status-hovered.9.png")
const PressedBackground = Qt.resolvedUrl("../Images/background/GGO-Status-pressed.9.png")

const names = [
    "Asuna","Egil","Kayaba","Kirito","Klein","Leafa","Rizbet","Sachi","Shinon","Silica","Sterben","Yui","Yuuki"
]

const elements = [

{ source: "icon", label: qsTr("Icon"), icon: "regular:\uf61f", component: Qt.createComponent("elements/IconElement.qml") },
{ source: "image", label: qsTr("Image"), icon: "regular:\uf03e", component: Qt.createComponent("elements/ImageElement.qml") },
{ source: "background", label: qsTr("Background"), icon: "regular:\uf51b", component: Qt.createComponent("elements/BackgroundElement.qml") },
{ source: "shape", label: qsTr("Rectangle"), icon: "regular:\uf2fa", component: Qt.createComponent("elements/ShapeElement.qml") },
{ source: "text", label: qsTr("Numeric or Text"), icon: "regular:\uf86f", component: Qt.createComponent("elements/TextElement.qml") },
{ source: "wordart", label: qsTr("Word Art"), icon: "regular:\uf031", component: Qt.createComponent("elements/WordArtElement.qml") },
{ source: "bar-gauge", label: qsTr("Bar Gauge"), icon: "regular:\uf547", component: Qt.createComponent("elements/BarGaugeElement.qml") },
{ source: "pointer-meter", label: qsTr("Pointer Meter"), icon: "regular:\uf627", component: Qt.createComponent("elements/PointerMeterElement.qml") },
{ source: "circle-graph", label: qsTr("Circle Graph"), icon: "regular:\uf64e", component: Qt.createComponent("elements/CircleGraphElement.qml") },
{ source: "line-chart", label: qsTr("Line Chart"), icon: "regular:\uf5f8", component: Qt.createComponent("elements/LineChartElement.qml") },
{ source: "histogram", label: qsTr("Histogram"), icon: "regular:\uf68f", component: Qt.createComponent("elements/HistogramElement.qml") }

];

const widgetInteractions = [

{ source: "mouse-track", label: qsTr("Mouse Track"), url: Qt.resolvedUrl("interactions/TrackInteraction.qml") }

];
const partInteractions = [

{ source: "state-transform", label: qsTr("State Transform"), url: Qt.resolvedUrl("interactions/TransformInteraction.qml") }

];

const interactions = widgetInteractions.concat(partInteractions);

function widgetEnvironment(widget) {
    const environment = {
        name: "com.gpbeta.widget.hud-adv",
        version: "0.1",
        widget: {
            name: widget.name,
            shared: {},
            get exposed() { return widget.exposed; },
            get hovered() { return widget.hovered; },
            get editing() { return widget.editing; }
        }
    };
    Object.freeze(environment.widget);
    return Object.freeze(environment);
}

function itemEnvironment(item, prototype) {
    const api = {
        shared: {},
        get label () { return item.defaultText },
        get state () { return item.interactionState },
        get width () { return item.width },
        get height () { return item.height }
    };
    Object.freeze(api);
    return Object.freeze(Object.create(prototype, { item: { value: api } } ));
}

function elementEnvironment(element, prototype) {
    // TODO: add element environment property
    return prototype;
}

function findElement(source) {
    return elements.find(element => element.source === source);
}

function resolveInteraction(source) {
    if (!source || source === "none")
        return null;
    return interactions.find(o => o.source === source)?.url ?? Qt.resolvedUrl(source);
}

function randomName() {
    return names[Math.floor(Math.random() * names.length)];
}

function makeObject(parent, enabled, comp, init, key) {
    if (enabled) {
        if (!parent[key]) {
            Object.defineProperty(parent, key, {
                                      value: comp.createObject(parent, init),
                                      configurable: true
                                  });
        }
        return parent[key];
    }

    // clean up element data source
    if (parent[key]) {
        parent[key].destroy();
        delete parent[key];
    }

    return null;
}

function toAxisAngle(pitch, yaw, roll) {
    const angle = Math.sqrt(pitch * pitch + yaw * yaw + roll * roll);
    return { x: pitch / angle, y: yaw / angle, z: roll / angle, w: angle };
}

function toPitchYawRoll(x, y, z, w) {
    return { pitch: x * w, yaw: y * w, roll: z * w }
}
