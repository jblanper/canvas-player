precision highp float;
uniform float time;
uniform vec2 resolution;
uniform float pixelation;

#define MAX_DEPTH 50.
#define MIN_DEPTH .001 // .0001
#define MARCHING_STEPS 100 //150
#define SHADOW_STEPS 25 //32
#define OCTAVES 4
#define EX .01

float tt;

#include <lib/noise2.glsl>

#include <lib/fbm.glsl>

#include <lib/3d_utils.glsl>

vec2 map (vec3 p) {
  // sea
  float c = p.y;
  c += simpleFbm(p.xz) * simpleFbm(vec2(simpleFbm(p.xz + tt - 5.), tt / 3.)) * 5.;
  c += noise11(p.y - simpleFbm(p.xz * tt)) * noise11(tt + p.y) * 3. + (tt * .2);
  vec2 t = vec2(c * .2, 1.);

  return t / 2.;
}

#include <lib/raymarching.glsl>

#include <lib/pixelate.glsl>

void main() {
  vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
  uv.x *= resolution.x / resolution.y;
  uv = pixelate(uv);

  tt = loopingNoise(uv, 3., 2.);

  // camera
  vec3 ro = vec3(0., 5., 9.);
  vec3 rd = getRayDirection(uv, ro, vec3(0.), 3.);

  // color, fog and light direction
  vec3 ld1 = vec3(0., 8., 10.);
  vec3 fogColor = vec3(.8, .4, .2);
  vec3 fog = fogColor * (5. + (length(uv) + .1));
  vec3 color = fog;

  // scene
  vec2 sc = trace(ro, rd);
  float t = sc.x;

  if (t > 0.) {
    vec3 p = ro + rd * t;
    vec3 normal = getNormal(p);
    vec3 albido = vec3(.3 + (tt * .2) + p.z * .1, .2 + (tt * .1) - (p.x * .05), .8 + tt) + p.y * .4;
    if (sc.y == 2.) {
      albido = vec3(.4, .4, .5) + p.y;
    }

    color = getLight(ld1, p, rd, 1.5, Material(0., .5, .2)) * vec3(.2, .3, .6);
    color += mix(color, vec3(.8, .6, .2) , getLight(ld1, p, rd, 1., Material(0., .6, .2))) * tt;
    color -= mix(color, albido, .8) * 1.;

    color = mix(color, fog, 1. - exp(-.00002*t*t*t)); //gradient
  }

  gl_FragColor = vec4(pow(color, vec3(.45)), 1.);
}