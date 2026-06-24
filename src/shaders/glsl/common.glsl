struct Camera {
    vec3 position;
    vec3 uu;
    vec3 vv;
    vec3 ww;
};

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Hit {
    float dist;
    uint material_index;
    vec3 color;
    bool hit;
};

struct DirectionalLight {
    vec3 direction;
    vec3 color;
    float intensity;
};

struct Material {
    float specular;
    float shininess;
    float roughness;
    float diffuse;
    vec3 color;
};

Material[3] materials;
uint time;

float sphere_sdf(vec3 p, float r) {
    return length(p) - r;
}

float box_sdf(vec3 p, vec3 dimension, float corner_radius) {
    vec3 q = abs(p) - dimension + corner_radius;
    return length(max(vec3(0), q)) + min(max(q.x, max(q.y, q.z)), 0.0) - corner_radius;
}

float cylinder_sdf(vec3 p, float radius, float height, float corner_radius) {
    vec2 d = vec2(p.xz.length(), abs(p.y)) - vec2(radius, height * 0.5) + corner_radius;
    return (max(d, vec2(0))).length() + min(max(d.x, d.y), 0.0) - corner_radius;
}

float line_sdf(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = min(1.0, max(0.0, dot(pa, ba) / dot(ba, ba)));
    return (pa - h * ba).length() - r;
}

float bounded_plane_sdf(vec3 p, vec3 boxDimensions) {
    vec3 d = abs(p) - boxDimensions;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float smooth_min(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0., 1.);
    return mix(d2, d1, h) - k * h * (1. - h);
}

vec3 smooth_min_vec4(vec4 d1, vec4 d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2.w - d1.w) / k, 0., 1.);
    return mix(d2.xyz, d1.xyz, h) - k * h * (1. - h);
}

vec3 repeat_xz(vec3 p, float s, float lima, float limb) {
    return vec3(p.x - s * clamp(round(p.x / s), lima, limb), p.y, p.z - s * clamp(round(p.z / s), lima, limb));
}

float random_f(in float f) {
    return fract(sin(f * 12.9898) *
        43758.5453123);
}

float random(in vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) *
        43758.5453123);
}

float random_3d(in vec3 p) {
    p += 1000.;
    return fract(123.0 * sin(p.x * 21.3) * sin(p.y * 43.11) * sin(p.z * 14.77) *
        43758.5453123);
}

float noise(in vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = random(i + vec2(0., 0.));
    float b = random(i + vec2(1., 0.));
    float c = random(i + vec2(0., 1.));
    float d = random(i + vec2(1., 1.));

    vec2 u = smoothstep(0., 1., f);

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float noise_3d(in vec3 p) {
    vec3 ip = floor(p);
    vec3 fp = fract(p);

    float a = random_3d(ip + vec3(0., 0., 0.));
    float b = random_3d(ip + vec3(1., 0., 0.));
    float c = random_3d(ip + vec3(0., 1., 0.));
    float d = random_3d(ip + vec3(1., 1., 0.));

    float e = random_3d(ip + vec3(0., 0., 1.));
    float f = random_3d(ip + vec3(1., 0., 1.));
    float g = random_3d(ip + vec3(0., 1., 1.));
    float h = random_3d(ip + vec3(1., 1., 1.));

    fp = smoothstep(0., 1.0, fp);

    return mix(mix(mix(a, b, fp.x), mix(c, d, fp.x), fp.y), mix(mix(e, f, fp.x), mix(g, h, fp.x), fp.y), fp.z);
}

float fbm(in vec2 uv, float dist) {
    float value = 0.;
    float amplitude = 1.;
    float freq = 0.8;

    int octaves = int(mix(8.0, 2.0, clamp(dist / 20.0, 0.0, 1.0)));

    for(int i = 0; i < octaves; i++) {
        float n = noise(uv * freq);
        value += n * amplitude;
        amplitude *= .37;
        freq *= 2.;
    }

    return value;
}

float fbm_3d(in vec3 p, float cell) {
    float v = 0.;
    float amplitude = 0.5;

    v += 1.000 * noise_3d(p + cell);
    p *= 2.02;
    v += 0.5 * noise_3d(p + cell);
    p *= 2.05;
    v += 0.250 * noise_3d(p + cell);
    p *= 2.07;
    v += 0.12 * noise_3d(p + cell);
    p *= 3.02;
    v += 0.06 * noise_3d(p + cell);

    return v;
}
