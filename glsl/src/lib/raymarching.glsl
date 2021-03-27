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