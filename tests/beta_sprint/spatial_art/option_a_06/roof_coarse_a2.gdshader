shader_type spatial;
render_mode diffuse_lambert_wrap, specular_disabled;

// ISOLATED_PREVIEW_ONLY: coarse A stone, within the existing opaque silhouette.
// Wrapped diffuse uses the scene's real light and shadows on the dark WEST face.
varying vec3 local_p;
varying vec3 local_n;

void vertex() {
    local_p = VERTEX;
    local_n = NORMAL;
}

float stone_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 blend = fract(p);
    blend = blend * blend * (3.0 - 2.0 * blend);
    float a = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(cell + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
    float c = fract(sin(dot(cell + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
    float d = fract(sin(dot(cell + vec2(1.0), vec2(127.1, 311.7))) * 43758.5453);
    return mix(mix(a, b, blend.x), mix(c, d, blend.x), blend.y);
}

void fragment() {
    vec2 uv = abs(local_n.y) > 0.5 ? local_p.xz : (abs(local_n.x) > 0.5 ? local_p.zy : local_p.xy);

    // Uneven, interrupted strata retain A's direction without parallel bands.
    // Large mineral patches remain visible at the actual small on-screen size.
    float strata_noise = stone_noise(uv * 3.2 + vec2(4.1, 7.3));
    float warp = sin(uv.y * 13.0) * 0.045 + (strata_noise - 0.5) * 0.58;
    float phase = (uv.x + uv.y * 0.36) * 3.4 + warp;
    float distance_to_cut = abs(fract(phase + 0.5) - 0.5);
    float aa = max(fwidth(phase) * 0.65, 0.006);
    float cut_width = mix(0.04, 0.10, stone_noise(uv * 7.0 + vec2(8.4, 2.2)));
    float groove = 1.0 - smoothstep(cut_width - aa, cut_width + 0.045 + aa, distance_to_cut);
    float breaks = smoothstep(0.30, 0.54, stone_noise(uv * vec2(4.5, 8.0) + vec2(2.7, 9.1)));
    groove *= mix(0.12, 1.0, breaks);
    float rib = smoothstep(0.10 - aa, 0.26 + aa, distance_to_cut);

    float mineral = smoothstep(0.30, 0.68, stone_noise(uv * 7.5));
    float chips = smoothstep(0.32, 0.58, stone_noise(uv * 13.0 + vec2(3.7, 6.2)));
    vec3 stone = mix(vec3(0.29, 0.33, 0.35), vec3(0.44, 0.48, 0.50), rib);
    stone *= mix(0.63, 1.0, mineral);
    stone *= mix(0.84, 1.0, chips);
    ALBEDO = mix(stone, vec3(0.075, 0.095, 0.11), groove);
    ROUGHNESS = 0.96;
    METALLIC = 0.0;
    SPECULAR = 0.0;
}
