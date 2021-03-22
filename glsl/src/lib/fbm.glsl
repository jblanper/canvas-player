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