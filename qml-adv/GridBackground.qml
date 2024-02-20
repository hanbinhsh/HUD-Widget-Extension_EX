import QtQuick 2.12

ShaderEffect {

    property real spacing: 9

    readonly property real vpw: width
    readonly property real vph: height

    fragmentShader: "
        precision mediump float;

        varying highp vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform lowp float spacing;
        uniform lowp float vpw;
        uniform lowp float vph;

        float markSize = 4.;
        float markRange = markSize * 2. + 1.;
        //网格线的颜色
        vec4 markColor = vec4(1.);
        vec4 lineColor = vec4(.3, .0, .0, .05);
        vec4 bgColor = vec4(.01, .01, .01, .01);

        void main() {
            float x = qt_TexCoord0.x * vpw;
            float y = qt_TexCoord0.y * vph;
            float xClamp = mod(x, spacing);
            float yClamp = mod(y, spacing);
            if (xClamp < 1. || yClamp < 1.) {
                float xRange = mod(x + markSize, spacing * 10.);
                float yRange = mod(y + markSize, spacing * 10.);
                if (xRange < markRange || yRange < markRange) {
                    if (xRange < markRange && yRange < markRange)
                        gl_FragColor = markColor * qt_Opacity; // lines
                    else
                        gl_FragColor = lineColor * qt_Opacity; // marks
                    return;
                } else {
                    if (mod(xClamp, 2.) < 1. && mod(yClamp, 2.) < 1.) {
                        gl_FragColor = lineColor * qt_Opacity; // dashes
                        return;
                    }
                }
            }

            gl_FragColor = bgColor;
        }
    "
}
