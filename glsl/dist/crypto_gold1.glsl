precision mediump float;
uniform float time;
uniform vec2 resolution;
uniform float pixelation;

#define MAX_DEPTH 30.
#define MIN_DEPTH .001
#define MARCHING_STEPS 50
#define SHADOW_STEPS 8
#define OCTAVES 5

float tt;

float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float noise11(float x) {
  // https://thebookofshaders.com/11/
  float i = floor(x);
  float f = fract(x);
  return mix(hash11(i), hash11(i+1.), smoothstep(0., 1., f));
}

float noise21(vec2 p) {
    // value noise https://www.shadertoy.com/view/lsf3WH
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = smoothstep(0., 1., f);

    return mix(
        mix(hash21(i + vec2(0.)), hash21(i + vec2(1., 0.)), u.x),
        mix(hash21(i + vec2(0., 1.)), hash21(i + vec2(1.)), u.x), u.y);
}

float loopingNoise(vec2 uv, float loopLength, float transitionStart) {
    // http://connorbell.ca/2017/09/09/Generating-Looping-Noise.html
    float delta = mod(time, loopLength);

    float v1 = noise21(uv + delta);
    float v2 = noise21(uv + delta - loopLength);

    float transitionProgress = (delta-transitionStart)/(loopLength-transitionStart);
    float progress = clamp(transitionProgress, 0., 1.);

    return mix(v1, v2, progress);
}

float fbm(vec2 p, float lacunarity, float gain) {
    // fractal brownian motion https://thebookofshaders.com/13/
    float n = 0.;
    float amplitude = .5;
    float frequency = 1.;

    for (int i = 0; i < OCTAVES; i++) {
        n += amplitude * noise21(frequency * p);
        frequency *= lacunarity;
        amplitude *= gain;
    }
    return n;
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 map (vec3 p) {
    p.xy *= rotate(fbm(p.xy, noise11(tt * 1.2), noise21(p.yx + tt)));
    float c1 = p.z;
    float f = fbm(p.xy, 2.5 * noise11(tt), .8 * noise11(p.x - p.y - tt)) * 2.5;

    vec2 t = vec2(c1 + f * .3, 1.);

    return t / 3.;
}

vec2 trace (vec3 ro, vec3 rd) {
    vec2 h, t = vec2(.1);

    for (int i = 0; i < MARCHING_STEPS; i++) {
        h = map(ro + rd * t.x);
        if (h.x < MIN_DEPTH || t.x > MAX_DEPTH) break;
        t.x += h.x; t.y = h.y;
    }
    if (t.x > MAX_DEPTH) t.x = 0.;
    return t;
}

vec3 getNormal (vec3 p) {
    float d = map(p).x;
    vec2 e = vec2(.0001, 0.);

    return normalize(d - vec3(
        map(p - e.xyy).x,
        map(p - e.yxy).x,
        map(p - e.yyx).x));
}

float getShadow(vec3 p, vec3 lightDir) {
    if (SHADOW_STEPS == 0) return 1.;

    float shadow = 1.0;
    float t = 0.1;
    for (int i = 0; i < SHADOW_STEPS; ++i)
    {
        vec3 ray = p + lightDir * t;
        float d = map(ray).x;
        shadow = min(shadow, d / t);
        t += clamp(d, 0.0, 0.6);
    }
    return clamp(shadow * 2.0, 0.0, 1.0);
}

struct Material {
    float ambient;
    float diffuse;
    float specular;
};

float getLight (vec3 lightPos, vec3 p, vec3 rd, float lightOcclusion, Material material) {
    // https://www.shadertoy.com/view/ll2GW1
    vec3 light = normalize(lightPos - p);
    vec3 normal = getNormal(p);

    float shadow = getShadow(p, light);

    // phong reflection
    float ambient = clamp(.5 + .5 * normal.y, 0., 1.);
    float diffuse = clamp(dot(normal, light), 0., 1.) * shadow;
    vec3 half_way = normalize(-rd + light);
    float specular = pow(clamp(dot(half_way, normal), 0.0, 1.0), 32.) * (shadow + .5);

    return (ambient * material.ambient * lightOcclusion) +
    (diffuse * material.diffuse * lightOcclusion) +
    (diffuse * specular * material.specular * lightOcclusion);
}

vec3 getRayDirection (vec2 uv, vec3 rayOrigin, vec3 lookat, float zoom) {
    // https://www.youtube.com/watch?v=PBxuVlp7nuM
    vec3 forward = normalize(lookat - rayOrigin);
    vec3 right = normalize(cross(vec3(0., 1., 0.), forward));
    vec3 up = cross(forward, right);
    vec3 center = rayOrigin + forward * zoom;
    vec3 intersection = center + uv.x * right + uv.y * up;
    return normalize(intersection - rayOrigin);
}

vec2 pixelate(vec2 st) {
  // https://github.com/spite/Wagner/blob/master/fragment-shaders/pixelate-fs.glsl
  // resolution and pixelation must be define or be an uniform
  if (pixelation == 1.) return st;

  float amount = resolution.x / pixelation;
  float d = 1. / amount;
  float ar = resolution.x / resolution.y;
  st.x = floor(st.x / d) * d;
  d = ar / amount;
  st.y = floor(st.y / d) * d;

  return st;
}

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