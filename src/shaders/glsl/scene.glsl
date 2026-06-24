#include <common.glsl>
#include <texture.glsl>

Hit sdf(vec3 p, float dist) {
    vec3 op = p;

    int material = 1;
    vec3 col = materials[material].color;

    float dBox = box_sdf(p, vec3(1.82, 0.52, 0.8), 0.0);
    
    float x_spacing = 0.61;
    float y_spacing = 0.21;
    vec3 pRep = p;

    float id_y = round(pRep.y / y_spacing);

    float shift = 0.5 * x_spacing;

    float isShifted = mod(abs(id_y), 2.0);

    pRep.x += isShifted * shift;

    float id_x = round(pRep.x / x_spacing);
    pRep.x -= x_spacing * id_x;

    float r = random(vec2(id_x, id_y))*0.1;
    pRep.y -= y_spacing * id_y;
    pRep.z -= r;

    float d1 = box_sdf(pRep, vec3(0.3 - r*0.3, 0.1 - r*0.4, 0.2), 0.02);

    //float d1 = sphere_sdf(p - vec3(-0.5, 2.0, 5.5), 0.3);

    float cell = id_x + id_y * 5.0;
    d1 += 0.02 * fbm_3d(pRep / 0.1, cell * 0.5);

    float d = max(dBox, d1);
    return Hit(d, material, col, true);
}