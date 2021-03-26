precision mediump float;
uniform float time;
uniform vec2 resolution;
uniform float pixelation;

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