shader_type spatial;
// PROPOSAL_ONLY: opaque surface color/roughness; no vertex displacement or alpha.
varying vec3 local_p;
varying vec3 local_n;
void vertex() { local_p = VERTEX; local_n = NORMAL; }
void fragment() {
    vec2 uv = abs(local_n.y) > 0.5 ? local_p.xz : (abs(local_n.x) > 0.5 ? local_p.zy : local_p.xy);
    float wave = abs(sin((uv.x + uv.y * 0.36) * 8.5 + sin(uv.y * 4.0) * 0.55));
    float coarse = 1.0 - smoothstep(0.18, 0.34, wave);
    ALBEDO = mix(vec3(0.23, 0.28, 0.33), vec3(0.48, 0.53, 0.55), coarse);
    ROUGHNESS = 0.94;
    METALLIC = 0.0;
}
