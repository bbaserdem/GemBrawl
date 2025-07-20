shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 gem_color : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform float transmission : hint_range(0.0, 1.0) = 0.95;
uniform float ior : hint_range(1.0, 3.0) = 2.4; // Ruby IOR
uniform float roughness : hint_range(0.0, 1.0) = 0.0;
uniform float rim_power : hint_range(0.0, 10.0) = 2.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.5;
uniform vec4 rim_color : source_color = vec4(1.0, 0.4, 0.4, 1.0);
uniform float specular_strength : hint_range(0.0, 2.0) = 1.5;
uniform float clearcoat : hint_range(0.0, 1.0) = 1.0;
uniform float clearcoat_roughness : hint_range(0.0, 1.0) = 0.0;
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.3;
uniform float inner_glow : hint_range(0.0, 1.0) = 0.2;

void vertex() {
    // Keep original vertex positions for faceted look
}

void fragment() {
    // Base color with slight transparency
    ALBEDO = gem_color.rgb;
    
    // Very low roughness for shiny gem
    ROUGHNESS = roughness;
    
    // No metallic (gems are dielectric)
    METALLIC = 0.0;
    
    // High specular for gem sparkle
    SPECULAR = specular_strength;
    
    // Calculate rim lighting for edge glow
    vec3 view_dir = normalize(VIEW);
    float fresnel = pow(1.0 - dot(NORMAL, view_dir), rim_power);
    vec3 rim_contribution = rim_color.rgb * rim_strength * fresnel;
    
    // Add inner glow to the fresnel effect
    float enhanced_fresnel = fresnel * (1.0 + fresnel_strength);
    
    // Add rim and inner glow to emission for edge highlight
    EMISSION = rim_contribution + (gem_color.rgb * inner_glow * enhanced_fresnel);
    
    // Handle refraction/transmission
    vec3 refracted_dir = refract(-view_dir, NORMAL, 1.0 / ior);
    
    // Sample screen texture for transmission effect
    vec2 screen_uv = SCREEN_UV;
    screen_uv += refracted_dir.xy * 0.05 * transmission;
    
    // Mix transmitted light with gem color
    vec3 transmitted = gem_color.rgb * transmission;
    
    // Apply clearcoat for extra shine
    CLEARCOAT = clearcoat;
    CLEARCOAT_ROUGHNESS = clearcoat_roughness;
    
    // Slight transparency to show internal reflections
    ALPHA = mix(1.0, 0.85, transmission * 0.3);
}