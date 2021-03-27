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

float hash11 (in float n) {
  //htimeps://thebookofshaders.com/11/
  return fract(sin(n)*1e4);
}

float hash21 (in vec2 st) {
    // https://thebookofshaders.com/13/
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise11 (float x) {
  // htimeps://thebookofshaders.com/11/
  float i = floor(x);
  float f = fract(x);
  return mix(hash11(i), hash11(i+1.), smoothstep(0., 1., f));
}

float noise21 (in vec2 st) {
    // https://www.shadertoy.com/view/4dS3Wd
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float loopingNoise (vec2 uv, float loopLength, float transitionStart) {
  // http://connorbell.ca/2017/09/09/Generating-Looping-Noise.html
  float delta = mod(time, loopLength);

  float v1 = noise21(uv + delta);
  float v2 = noise21(uv + delta - loopLength);

  float transitionProgress = (delta-transitionStart)/(loopLength-transitionStart);
  float progress = clamp(transitionProgress, 0., 1.);

  return mix(v1, v2, progress);
}

float complexFbm(vec2 p, float lacunarity, float gain) {
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

float simpleFbm(in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;

    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise21(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

mat2 rotate (float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float smin (float a, float b, float k ) {
  float h = max( k-abs(a-b), 0.0 )/k;
  return min( a, b ) - h*h*h*k*(1.0/6.0);
}

float sphereSDF (vec3 p, vec3 c, float r) {
  return length(c - p) - r;
}

float cubeSDF (vec3 p, vec3 c, vec3 dimensions, float borderRoundness) {
  vec3 pos = abs(c - p) - dimensions;
  return length(max(pos, 0.)) - borderRoundness + min(max(pos.x, max(pos.y, pos.z)), 0.);
}

vec2 map (vec3 p) {
  // sea
  float c = p.y;
  c += simpleFbm(p.xz) * simpleFbm(vec2(simpleFbm(p.xz + tt - 5.), tt / 3.)) * 5.;
  c += noise11(p.y - simpleFbm(p.xz * tt)) * noise11(tt + p.y) * 3. + (tt * .2);
  vec2 t = vec2(c * .2, 1.);

  return t / 2.;
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
    vec2 e = vec2(EX, 0.);

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

    float shadow = getShadow(p, light) * .9;

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