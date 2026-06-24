#include <scene.glsl>

#define MAX_STEPS 400
#define HIT_PRECISION 0.001
#define MAX_DISTANCE 40.0

vec3 normal(vec3 p, float t) {

    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.004;
    return normalize(e.xyy * sdf(p + e.xyy, t).dist + e.yyx * sdf(p + e.yyx, t).dist +
        e.yxy * sdf(p + e.yxy, t).dist + e.xxx * sdf(p + e.xxx, t).dist);

}

float occlusion(vec3 pos, vec3 nor, float dist) {
    float occ = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++) {
        float hr = 0.02 + 0.025 * (i * i);
        vec3 p = pos + nor * hr;
        Hit hit = sdf(p, dist);

        occ += -(hit.dist - hr) * sca;
        sca *= 0.85;
    }
    return 1.0 - clamp(occ, 0.0, 1.0);
}

float shadow(Ray ray, float k, float dist) {
    float res = 1.0;

    float t = 0.01;

    for(int i = 0; i < 64; i++) {
        vec3 pos = ray.origin + ray.direction * t;
        float h = sdf(pos, dist).dist;

        res = min(res, k * (max(h, 0.0) / t));
        if(res < 0.0001) {
            break;
        }
        t += clamp(h, 0.01, 5.0);
    }

    return res;
}

Hit ray_march(Ray ray) {

    float t = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        if(t > MAX_DISTANCE) {
            break;
        }
        vec3 p = ray.origin + ray.direction * t;
        Hit h = sdf(p, t);

        if(h.dist < 0.001) {
            return Hit(t, h.material_index, h.color, true);
        }

        t += 0.6 * h.dist;
    }
    return Hit(t, 0, vec3(0), false);
}

vec3 fog2(
    in vec3 col,   // color of pixel
    in float t,    // distance to point
    in vec3 rd,    // camera to point
    in vec3 lig
)  // sun direction
{
    float fogAmount = 1.0 - exp(-t * 0.05) * 0.5;
    float sunAmount = max(dot(rd, lig), 0.0);
    vec3 fogColor = mix(vec3(0.5, 0.6, 0.6), // blue
    vec3(1.0, 0.9, 0.7), // yellow
    pow(sunAmount, 0.1));
    return mix(col, fogColor, fogAmount);
}

vec3 fog(vec3 col, float t) {
    float fo = 1.0 - exp(-pow(40. * t / 250, 1.5));
    vec3 fco = 0.65 * vec3(0.4, 0.65, 1.0);
    return mix(col, fco, fo);
}

vec3 path_trace(Ray ray, DirectionalLight d_light, vec3 res, vec3 sky, int bounce) {

    vec3 refl_col = vec3(0);
    float refl_roughness = -1.0;
    bool need_mix = false;

    Hit hit = ray_march(ray);

    if(hit.hit) {
        vec3 p = ray.origin + ray.direction * hit.dist;
        vec3 n = normal(p, hit.dist);

        vec3 light_dir = -d_light.direction;
        float occlusion = occlusion(p, n, hit.dist);
        float shadow = shadow(Ray(p + n * 0.0001, light_dir), 32, hit.dist);

        vec3 half_angle = normalize(-ray.direction + light_dir);

        Material material = materials[hit.material_index];
        float mat_specular = material.specular;
        float mat_shininess = material.shininess;

        vec3 col = hit.color;

        float shininess = pow(max(dot(n, half_angle), 0.), mat_shininess);

        float sun = clamp(dot(n, light_dir), 0.0, 1.0);
        float indirect = 0.2 * clamp(dot(n, normalize(light_dir * vec3(-1.0, 0.0, -1.0))), 0.0, 1.0);

        vec3 light = material.diffuse * sun * d_light.color * pow(vec3(shadow), vec3(1.3, 1.2, 1.5));

        light += sky * vec3(0.16, 0.20, 0.28) * occlusion;
        light += indirect * vec3(0.40, 0.28, 0.20) * occlusion;
        light += mat_specular * shininess * shadow;

        col *= light * d_light.intensity;

        //col = fog(col, hit.dist);
        res = clamp(col, 0.0, 1.0);
    }
    return res;
}

vec3 run(vec2 coord, vec2 screen, Camera camera) {
    vec2 p = (coord - 0.5 * screen) / screen.y;
    p.y = -p.y;

    Ray ray = Ray(camera.position, normalize(p.x * camera.uu + p.y * camera.vv + 1.5 * camera.ww));
    DirectionalLight d_light = DirectionalLight(normalize(vec3(-3., -1.5, -2.)), vec3(1., 0.85, 0.70), 1.0);

    vec3 sky = clamp(vec3(0.5, 0.8, 1.) - (0.7 * ray.direction.y), 0.0, 1.0);

    sky = mix(sky, vec3(0.5, 0.7, 0.9), exp(-10.0 * max(ray.direction.y, 0.0)));

    vec3 res = sky;

    float sundot = clamp(dot(ray.direction, -d_light.direction), 0.0, 1.0);

    res += 0.25 * vec3(1.0, 0.7, 0.4) * pow(sundot, 5.0);
    res += 0.25 * vec3(1.0, 0.6, 0.6) * pow(sundot, 64.0);
    res += 0.25 * vec3(1.0, 0.9, 0.6) * pow(sundot, 512.0);

    res = path_trace(ray, d_light, res, sky, 0);

    res = pow(res, vec3(0.4545));
    return res;
}