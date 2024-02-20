// Author: gre
// License: MIT
// forked from https://gist.github.com/benraziel/c528607361d90a072e98

// minimum number of squares (when the effect is at its higher level)
ivec2 squaresMin = ivec2(20);
// zero disable the stepping
int steps_pixelize = 50;

float d = min(progress, 1.0 - progress);
float dist = steps_pixelize>0 ? ceil(d * float(steps_pixelize)) / float(steps_pixelize) : d;
vec2 squareSize = 2.0 * dist / vec2(squaresMin);

vec4 transition(vec2 uv) {
  vec2 p = dist>0.0 ? (floor(uv / squareSize) + 0.5) * squareSize : uv;
  return mix(getFromColor(p), getToColor(p), progress);
}
