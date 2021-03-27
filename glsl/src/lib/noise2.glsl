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