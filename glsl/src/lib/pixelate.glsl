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