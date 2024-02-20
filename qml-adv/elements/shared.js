.pragma library

.import NERvGear 1.0 as NVG
.import NERvExtras 1.0 as NVG

const gl_transitions = {};
var gl_transitions_random;
var gl_transitions_count = 0;

(function () {
    const qDir = NVG.QtDir.construct();
    const qFile = NVG.QtFile.construct();

    qDir.setPath(NVG.Url.toLocalFile(Qt.resolvedUrl("../Shaders/gl-transitions")));
    const entries = qDir.entryList(["*.glsl"], NVG.QtDir.Files | NVG.QtDir.NoDotAndDotDot);
    const basePath = qDir.absolutePath();
    entries.forEach(function (entry) {
        qFile.setFileName(basePath + '/' + entry);
        if (qFile.open(NVG.QtFile.ReadOnly)) {
            gl_transitions[entry] = qFile.readAll().toString();
            ++gl_transitions_count;
            qFile.close();
        } else { console.warn("cannot open transition shader:", entry); }
    });
})();

// TODO: check if running with OpenGL ES (ANGLE)
function generateShader(name, fit) {
    var shader = `
uniform lowp float qt_Opacity;
varying highp vec2 qt_TexCoord0;

uniform sampler2D _fromS;
uniform highp float _fromR;

uniform sampler2D _toS;
uniform highp float _toR;

uniform int _transition;

uniform lowp float progress;
uniform highp float ratio;

const highp float PI = 3.141592653589793;

precision mediump float;
`;
    if (fit) {
        shader += `
vec2 _fitRemap(vec2 uv, float r) {
    return .5 + (uv - .5) * vec2(max(ratio / r, 1.), max(r / ratio, 1.));
}

vec4 getFromColor(vec2 uv) {
    uv = _fitRemap(uv, _fromR);

    if (uv.x <= .0 || uv.x >= 1. || uv.y <= .0 || uv.y >= 1.)
        return vec4(.0);

    return texture2D(_fromS, uv);
}

vec4 getToColor(vec2 uv) {
    uv = _fitRemap(uv, _toR);

    if (uv.x <= .0 || uv.x >= 1. || uv.y <= .0 || uv.y >= 1.)
        return vec4(.0);

    return texture2D(_toS, uv);
}
`;
    } else {
        shader += `
vec2 _cropRemap(vec2 uv, float r) {
    return .5 + (uv - .5) * vec2(min(ratio / r, 1.), min(r / ratio, 1.));
}

vec4 getFromColor(vec2 uv) {
    return texture2D(_fromS, _cropRemap(uv, _fromR));
}

vec4 getToColor(vec2 uv) {
    return texture2D(_toS, _cropRemap(uv, _toR));
}
`;
    }



    if (name === "random") {
        let merged = gl_transitions_random;
        if (merged === undefined) {
            merged = "";
            let i = 0;
            for (const entry in gl_transitions) {
                const code = gl_transitions[entry];
                merged += code.replace(/vec4 transition\s*\(vec2/,
                                       "vec4 transition_" + i + "(vec2");
                merged += '\n';
                ++i;
            }
            merged += `
void main() {
    lowp vec4 tex;
    if (false) {}
`;

            for (let j = 0; j < i; ++j) {
                merged += `
    else if (_transition == ${j})
        tex = transition_${j}(qt_TexCoord0);`
            }

            merged += `
    gl_FragColor = tex * qt_Opacity;
}
`;
            gl_transitions_random = merged;
        }
        shader += merged;
    } else {
        const code = gl_transitions[name];
        if (code) {
            shader += code + `
void main() {
    lowp vec4 tex = transition(qt_TexCoord0);
    gl_FragColor = tex * qt_Opacity;
}
`
        } else {
            console.warn("transition shader not found:", name);
            return "";
        }
    }

    return shader;
}
