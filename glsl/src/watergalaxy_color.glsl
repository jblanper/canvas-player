precision mediump float;
uniform float time;
uniform vec2 resolution;
uniform float pixelation;

#include <lib/noise.glsl>

#include <lib/pixelate.glsl>

#define PI 3.141592

void main() {
  vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
  
  uv = pixelate(uv);

  vec3 color = vec3(0);

  float t = sin(time) * 2.2 + (1.3 * PI);
  float tt = loopingNoise(uv, 6.2832, 4.);
  float a = atan(uv.y, uv.x);
  float l = length(uv);

  vec2 rt = vec2(cos(t * .5), sin(t * .5)) * 3.5;
  vec2 p1 = vec2(cos(l * 200. + tt), sin(l * 80. + tt));
  vec2 p2 = vec2(cos(a + l * 10. * t), sin(a - l * 25. * tt)) * tt * 7.;

  vec2 st = uv * 20.;
  color += 1. / length(st + p1 + tt) * (t * .1); // spark

  color += 1.8 / dot(st + p2, st + p2) * (tt * 3.8) + vec3(st.y * .08, .1, st.x * .02); // spark
  
  color *= mix(color, vec3(abs(1. - uv.x)) * 1.8, smoothstep(.01, .1, 1. / dot(st + p2 * rt, st + p2 - rt) / tt)) * vec3(.3, .2, .8); // spark

  st += rt + pow(p1, vec2(7.));
  color += 1. / dot(st, st) * (t * 2.) * vec3(.1, .2, .4 + tt); // spark

  gl_FragColor = vec4(color * .8, 1.);
}