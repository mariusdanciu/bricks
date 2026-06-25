#include <common.glsl>
#include <texture.glsl>

Hit sdf(vec3 p, float dist) {
    vec3 op = p;

    int material = 1;
    vec3 col = materials[material].color;

    float dBox = box_sdf(p, vec3(1.84, 0.62, 0.8), 0.0);

    float x_spacing = 0.61;
    float y_spacing = 0.18;
    vec3 pRep = p;

    float id_y = round(pRep.y / y_spacing);

    float shift = 0.5 * x_spacing;

    float isShifted = mod(abs(id_y), 2.0);

    pRep.x += isShifted * shift;

    float id_x = round(pRep.x / x_spacing);
    pRep.x -= x_spacing * id_x;

    float r = random(vec2(id_x, id_y)) * 0.1;
    pRep.y -= y_spacing * id_y;
    pRep.z -= r;

    col *= r * 4.1 + 0.1;
    float d1 = box_sdf(pRep, vec3(0.3 - r * 0.3, 0.1 - r * 0.4, 0.2), 0.02);
    float d2 = box_sdf(op + vec3(0., 0, -0.05), vec3(1.78, 0.55, 0.13), 0.0);

    bool isMortar = (d2 < d1);  

    float cell = id_x + id_y * 5.0;
    d1 += 0.02 * fbm_3d(pRep / 0.1, cell * 0.5);
    d2 += 0.03 * fbm_3d(op / 0.08, 0.0);

    float d3 = min(d2, d1);
    if (isMortar) {
        col = vec3(0.5, 0.5, 0.5);
    }

    float d = max(dBox, d3);
    return Hit(d, material, col, true);
}