precision highp float;
uniform float time;
uniform vec2 resolution;
uniform float pixelation;

#define MAX_DEPTH 30.
#define MIN_DEPTH .001
#define MARCHING_STEPS 50
#define SHADOW_STEPS 8
#define OCTAVES 5
#define EX .0001

float tt;

#include <lib/noise1.glsl>

#include <lib/fbm.glsl>

#include <lib/3d_utils.glsl>

vec2 map (vec3 p) {
    p.xy *= rotate(complexFbm(p.xy, noise11(tt * 1.2), noise21(p.yx + tt)));
    float c1 = p.z;
    float f = complexFbm(p.xy, 2.5 * noise11(tt), .8 * noise11(p.x - p.y - tt)) * 2.5;

    vec2 t = vec2(c1 + f * .3, 1.);

    return t / 3.;
}

#include <lib/raymarching.glsl>

#include <lib/pixelate.glsl>

void main() {
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    uv = pixelate(uv);

    tt = loopingNoise(uv, 3., 2.);

    // camera
    vec3 ro = vec3(0., 0. + (sin(tt) * .5 - .5) * 15., 15. + sin(tt) * .5 + .5);
    vec3 rd = getRayDirection(uv, ro, vec3(0.), 2.);

    // color, fog and light direction
    vec3 ld1 = vec3(5., 12., 35.);
    vec3 ld2 = vec3(0., 4., 5.);
    vec3 fogColor = vec3(.8, .4, .2) * .1;
    vec3 fog = fogColor * (.5 + (length(uv) - .2));
    vec3 color = fog;

    // scene
    vec2 sc = trace(ro, rd);
    float t = sc.x;

    if (t > 0.) {
        vec3 p = ro + rd * t;
        vec3 normal = getNormal(p);
        vec3 albido = vec3(.5);

        color = getLight(ld1, p, rd, 2.5, Material(.2, .6, 2.2)) * vec3(.7, .5, .2);
        color *= getLight(ld2, p, rd, 1.2, Material(.3, .8, 1.7)) * vec3(.7, .5, .2);
        color *= albido; 


        color = mix(color, fog, 1. - exp(-.00005*t*t*t)); //gradient
    }

    gl_FragColor = vec4(pow(color, vec3(.45)), 1.);
}