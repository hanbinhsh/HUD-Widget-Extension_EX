// License: MIT
// Author: TimDonselaar
// ported by gre from https://gist.github.com/TimDonselaar/9bcd1c4b5934ba60087bdb55c2ea92e5

ivec2 size_gridflip = ivec2(4);
float pause = 0.1;
float dividerWidth = 0.05;
vec4 bgcolor_gridflip = vec4(0.0, 0.0, 0.0, 0.0);
float randomness = 0.1;
 
float rand_gridflip (vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float getDelta(vec2 p) {
  vec2 rectanglePos = floor(vec2(size_gridflip) * p);
  vec2 rectangleSize = vec2(1.0 / vec2(size_gridflip).x, 1.0 / vec2(size_gridflip).y);
  float top = rectangleSize.y * (rectanglePos.y + 1.0);
  float bottom = rectangleSize.y * rectanglePos.y;
  float left = rectangleSize.x * rectanglePos.x;
  float right = rectangleSize.x * (rectanglePos.x + 1.0);
  float minX = min(abs(p.x - left), abs(p.x - right));
  float minY = min(abs(p.y - top), abs(p.y - bottom));
  return min(minX, minY);
}

float getDividerSize() {
  vec2 rectangleSize = vec2(1.0 / vec2(size_gridflip).x, 1.0 / vec2(size_gridflip).y);
  return min(rectangleSize.x, rectangleSize.y) * dividerWidth;
}

vec4 transition(vec2 p) {
  if(progress < pause) {
    float currentProg = progress / pause;
    float a = 1.0;
    if(getDelta(p) < getDividerSize()) {
      a = 1.0 - currentProg;
    }
    return mix(bgcolor_gridflip, getFromColor(p), a);
  }
  else if(progress < 1.0 - pause){
    if(getDelta(p) < getDividerSize()) {
      return bgcolor_gridflip;
    } else {
      float currentProg = (progress - pause) / (1.0 - pause * 2.0);
      vec2 q = p;
      vec2 rectanglePos = floor(vec2(size_gridflip) * q);
      
      float r = rand_gridflip(rectanglePos) - randomness;
      float cp = smoothstep(0.0, 1.0 - r, currentProg);
    
      float rectangleSize = 1.0 / vec2(size_gridflip).x;
      float delta = rectanglePos.x * rectangleSize;
      float offset = rectangleSize / 2.0 + delta;
      
      p.x = (p.x - offset)/abs(cp - 0.5)*0.5 + offset;
      vec4 a = getFromColor(p);
      vec4 b = getToColor(p);
      
      float s = step(abs(vec2(size_gridflip).x * (q.x - delta) - 0.5), abs(cp - 0.5));
      return mix(bgcolor_gridflip, mix(b, a, step(cp, 0.5)), s);
    }
  }
  else {
    float currentProg = (progress - 1.0 + pause) / pause;
    float a = 1.0;
    if(getDelta(p) < getDividerSize()) {
      a = currentProg;
    }
    return mix(bgcolor_gridflip, getToColor(p), a);
  }
}
