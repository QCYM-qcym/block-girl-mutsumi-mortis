shader_type spatial;
// STEP B2 ONLY. Original A1 diffuse model, stripe phase, scale and color ratios.
// No light(), emission, camera inputs, displacement, or silhouette changes.
varying vec3 local_p;
varying vec3 local_n;
void vertex() { local_p = VERTEX; local_n = NORMAL; }
void fragment() {
    vec2 uv = abs(local_n.y) > 0.5 ? local_p.xz : (abs(local_n.x) > 0.5 ? local_p.zy : local_p.xy);
    float wave = abs(sin((uv.x + uv.y * 0.36) * 8.5 + sin(uv.y * 4.0) * 0.55));
    float coarse = 1.0 - smoothstep(0.18, 0.34, wave);
    ALBEDO = mix(vec3(0.23, 0.28, 0.33), vec3(0.48, 0.53, 0.55), coarse) * 1.06;
    ROUGHNESS = 0.90;
    METALLIC = 0.0;
    SPECULAR = 0.15;
    // 1/32 local-unit detail; max tangent-vector length0.10, about5.71degrees.
    // Dimensionless normal perturbation, not Blender Bump Strength/Distance.
    float micro_x = sin(uv.x * 201.06193) * cos(uv.y * 201.06193) * 0.10;
    float micro_y = cos(uv.x * 201.06193) * sin(uv.y * 201.06193) * 0.10;
    NORMAL_MAP = normalize(vec3(micro_x, micro_y, 1.0)) * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = 1.0;
}
