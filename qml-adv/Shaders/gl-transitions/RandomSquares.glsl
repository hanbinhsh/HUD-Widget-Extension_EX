// Author: gre
// License: MIT

ivec2 size_randomsquares = ivec2(10, 10);
float smoothness_randomsquares = 0.5;
 
float rand_randomsquares (vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 transition(vec2 p) {
  float r = rand_randomsquares(floor(vec2(size_randomsquares) * p));
  float m = smoothstep(0.0, -smoothness_randomsquares, r - (progress * (1.0 + smoothness_randomsquares)));
  return mix(getFromColor(p), getToColor(p), m);
}
