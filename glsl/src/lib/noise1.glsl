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