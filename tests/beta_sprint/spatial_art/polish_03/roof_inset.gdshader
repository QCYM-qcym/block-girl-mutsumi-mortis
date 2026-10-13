shader_type spatial;
// PROPOSAL_ONLY: all markings remain inside the existing opaque cube silhouette.
varying vec3 local_p;
varying vec3 local_n;
void vertex() { local_p = VERTEX; local_n = NORMAL; }
void fragment() {
    vec2 uv = (abs(local_n.y) > 0.5 ? local_p.xz : (abs(local_n.x) > 0.5 ? local_p.zy : local_p.xy)) + vec2(0.5);
    float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float rim = smoothstep(0.075, 0.095, edge) * (1.0 - smoothstep(0.135, 0.155, edge));
    float near_mid = min(abs(uv.x - 0.5), abs(uv.y - 0.5));
    float seal = (1.0 - smoothstep(0.035, 0.06, near_mid)) * smoothstep(0.045, 0.065, edge) * (1.0 - smoothstep(0.22, 0.25, edge));
    ALBEDO = mix(vec3(0.23, 0.28, 0.33), vec3(0.53, 0.57, 0.57), max(rim, seal));
    ROUGHNESS = 0.94;
    METALLIC = 0.0;
}
