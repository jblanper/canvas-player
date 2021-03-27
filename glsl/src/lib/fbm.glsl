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