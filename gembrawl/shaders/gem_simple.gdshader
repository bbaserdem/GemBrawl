shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 gem_color : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float rim_power : hint_range(0.0, 10.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // Base color
    ALBEDO = gem_color.rgb;
    
    // Low roughness for shiny surface
    ROUGHNESS = roughness;
    
    // Non-metallic
    METALLIC = 0.0;
    
    // High specular
    SPECULAR = 1.0;
    
    // Simple rim lighting
    float rim = 1.0 - dot(NORMAL, VIEW);
    rim = pow(rim, rim_power);
    EMISSION = gem_color.rgb * rim * rim_strength;
    
    // Full opacity
    ALPHA = 1.0;
}