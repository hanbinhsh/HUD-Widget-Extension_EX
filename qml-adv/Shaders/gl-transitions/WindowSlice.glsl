// Author: gre
// License: MIT

float count = 10.0;
float smoothness_windowslice = 0.5;

vec4 transition (vec2 p) {
  float pr = smoothstep(-smoothness_windowslice, 0.0, p.x - progress * (1.0 + smoothness_windowslice));
  float s = step(pr, fract(count * p.x));
  return mix(getFromColor(p), getToColor(p), s);
}
