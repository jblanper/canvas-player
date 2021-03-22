precision mediump float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float tt;

// random / noise functions
// htimeps://thebookofshaders.com/13/
float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float random (in float n) {
  //htimeps://thebookofshaders.com/11/
  return fract(sin(n)*1e4);
}

float noise (float x) {
  // htimeps://thebookofshaders.com/11/
  float i = floor(x);
  float f = fract(x);
  return mix(random(i), random(i+1.), smoothstep(0., 1., f));
}

// Based on Morgan McGuire @morgan3d
// htimeps://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 4
float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

// looping function
float getLoopingNoise (vec2 uv, float loopLength, float transitionStart) {
  // http://connorbell.ca/2017/09/09/Generating-Looping-Noise.html
  float delta = mod(time, loopLength);

  float v1 = noise(uv + delta);
  float v2 = noise(uv + delta - loopLength);

  float transitionProgress = (delta-transitionStart)/(loopLength-transitionStart);
  float progress = clamp(transitionProgress, 0., 1.);

  return mix(v1, v2, progress);
}

// 3d functions
mat2 rotate(float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float smin( float a, float b, float k ) {
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
  c += fbm(p.xz) * fbm(vec2(fbm(p.xz + tt - 5.), tt / 3.)) * 5.;
  c += noise(p.y - fbm(p.xz * tt)) * noise(tt + p.y) * 3. + (tt * .2);
  //c += noise(p.xy + length(tt * 2. - p.z) * 15.) * .8 + (tt );
  vec2 t = vec2(c * .2, 1.);

  return t / 2.;
}

vec2 trace (vec3 ro, vec3 rd) {
  const float MAX_DEPTH = 50.;
  vec2 h, t = vec2(.1);

  for (int i = 0; i < 150; i++) {
    h = map(ro + rd * t.x);
    if (h.x < .0001 || t.x > MAX_DEPTH) break;
    t.x += h.x; t.y = h.y;
  }
  if (t.x > MAX_DEPTH) t.x = 0.;
  return t;
}

vec3 getNormal (vec3 p) {
  float d = map(p).x;
  vec2 e = vec2(.01, 0.);

  return normalize(d - vec3(
    map(p - e.xyy).x,
    map(p - e.yxy).x,
    map(p - e.yyx).x));
}

float getShadow(vec3 p, vec3 lightDir) {
    float shadow = 1.0;
    float t = 0.1;
    for (int i = 0; i < 32; ++i)
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
  // htimeps://www.shadertoy.com/view/ll2GW1
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
  // htimeps://www.youtube.com/watch?v=PBxuVlp7nuM
  vec3 forward = normalize(lookat - rayOrigin);
  vec3 right = normalize(cross(vec3(0., 1., 0.), forward));
  vec3 up = cross(forward, right);
  vec3 center = rayOrigin + forward * zoom;
  vec3 intersection = center + uv.x * right + uv.y * up;
  return normalize(intersection - rayOrigin);
}

void main() {
  vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
  uv.x *= resolution.x / resolution.y;
  tt = getLoopingNoise(uv, 3., 2.);

  // camera
  // vec3 ro = vec3(0., 3. - (tt * .2), 9. - (tt * .2));
  vec3 ro = vec3(0., 5., 9.);
  vec3 rd = getRayDirection(uv, ro, vec3(0.), 3.);

  // color, fog and light direction
  // vec3 ld = normalize(vec3(0., 25., -35.));
  vec3 ld1 = vec3(0., 8., 10.);
  // vec3 ld2 = vec3(1.5, 1.5, 7.);
  vec3 fogColor = vec3(.8, .4, .2);
  // vec3 fog = fogColor * (.8 + (length(uv) - .1));
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
    // ld2.xz *= rotate(time * .5);
    // ld2.yz *= rotate(time * .2);
    // color *= getLight(ld2, p, rd, 3., Material(.1, .5, .2)) * vec3(.6, .6, .2);
    color += mix(color, vec3(.8, .6, .2) , getLight(ld1, p, rd, 1., Material(0., .6, .2))) * tt;
    color -= mix(color, albido, .8) * 1.;
    // color *= albido;

    color = mix(color, fog, 1. - exp(-.00002*t*t*t)); //gradient
  }

  gl_FragColor = vec4(pow(color, vec3(.45)), 1.);
}