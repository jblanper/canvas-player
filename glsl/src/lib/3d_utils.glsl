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