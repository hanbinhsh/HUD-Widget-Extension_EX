// Author: Gaëtan Renaudeau
// License: MIT

vec4 transition (vec2 uv) {
  vec2 direction = ratio > 1. ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec2 p = uv + progress * direction;
  vec2 f = fract(p);
  return mix(
    getToColor(f),
    getFromColor(f),
    step(0.0, p.y) * step(p.y, 1.0) * step(0.0, p.x) * step(p.x, 1.0)
  );
}
