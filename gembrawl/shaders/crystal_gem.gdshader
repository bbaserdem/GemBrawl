shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx;

// Parameters for customization
uniform vec4 albedo_color : source_color = vec4(0.9, 0.15, 0.2, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 1.0;
uniform float rim_power : hint_range(0.0, 8.0) = 2.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.6;
uniform vec4 rim_color : source_color = vec4(1.0, 0.6, 0.6, 1.0);
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.0;
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.4;

// Flat shading - calculate normal per fragment from position derivatives
vec3 get_flat_normal(vec3 world_pos) {
    vec3 dx = dFdx(world_pos);
    vec3 dy = dFdy(world_pos);
    return normalize(cross(dy, dx));
}

void vertex() {
    // Standard vertex transformation
}

void fragment() {
    // Get flat shading normal for angular appearance
    vec3 flat_normal = get_flat_normal((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
    
    // Use the flat normal for all lighting calculations
    NORMAL = (VIEW_MATRIX * vec4(flat_normal, 0.0)).xyz;
    
    // Base color
    ALBEDO = albedo_color.rgb;
    
    // Material properties
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = specular;
    
    // Calculate view direction and rim lighting
    vec3 view_dir = normalize(VIEW);
    float rim = 1.0 - dot(view_dir, NORMAL);
    rim = pow(rim, rim_power);
    
    // Enhanced rim emission for edge definition
    EMISSION = rim_color.rgb * rim * rim_strength;
    
    // Fresnel effect for added crystalline appearance
    float fresnel = pow(1.0 - dot(view_dir, NORMAL), fresnel_power);
    ALBEDO = mix(ALBEDO, vec3(1.0), fresnel * fresnel_strength);
}