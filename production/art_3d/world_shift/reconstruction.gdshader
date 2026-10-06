shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D color_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = false;
uniform float roughness_value = 0.8;
uniform float metallic_value = 0.0;
uniform vec3 glow_color : source_color = vec3(0.0);
uniform float progress = 0.0;
uniform float incoming = 0.0;
uniform float intensity = 0.0;
uniform float character = 0.0;
uniform float conceal = 0.0;
varying vec3 world_pos;
void vertex() {
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 // Sub-centimeter lateral reconstruction. Never moves character or physics.
 float cell=sin(floor(world_pos.x*4.0)*2.7+floor(world_pos.z*4.0)*1.9);
 VERTEX.x += cell*0.018*intensity*(1.0-character);
}
void fragment() {
 vec4 c=base_color;
 if(use_tex) c*=texture(color_tex,UV);
 if(c.a<0.35) discard;
 // Coherent world-space front shared by the paired interpretations.
 float field=clamp((world_pos.x+4.8)/10.0+0.055*sin(world_pos.y*4.0+world_pos.z*3.0),0.015,0.985);
 if(incoming>0.5 && field>progress) discard;
 if(incoming<0.5 && field<=progress) discard;
 // Only a foreground occluder uses a fixed fine stipple, never the character.
 float stipple=fract(dot(floor(FRAGCOORD.xy),vec2(0.754877,0.56984)));
 if(conceal>0.0 && stipple<conceal) discard;
 ALBEDO=c.rgb;
 ROUGHNESS=roughness_value;
 METALLIC=metallic_value;
 EMISSION=glow_color;
 float edge=1.0-smoothstep(0.0,0.018,abs(field-progress));
 EMISSION+=vec3(0.10,0.14,0.16)*edge*intensity*(1.0-character);
}
