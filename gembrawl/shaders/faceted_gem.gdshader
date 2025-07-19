shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_toon;

// Gem color and properties
uniform vec4 gem_color : source_color = vec4(0.9, 0.15, 0.2, 1.0);
uniform vec4 edge_color : source_color = vec4(0.3, 0.0, 0.05, 1.0);
uniform float edge_thickness : hint_range(0.0, 0.5) = 0.15;

// Toon shading levels
uniform float light_levels : hint_range(2.0, 8.0) = 3.0;
uniform float specular_size : hint_range(0.0, 1.0) = 0.3;
uniform float specular_intensity : hint_range(0.0, 2.0) = 1.5;

// Facet definition
uniform float facet_sharpness : hint_range(0.0, 10.0) = 5.0;
uniform float rim_light_power : hint_range(0.0, 5.0) = 2.0;
uniform float rim_light_intensity : hint_range(0.0, 2.0) = 1.0;

// Calculate flat normal from position
vec3 get_flat_normal() {
    vec3 pos_dx = dFdx(VERTEX);
    vec3 pos_dy = dFdy(VERTEX);
    return normalize(cross(pos_dy, pos_dx));
}

// Stepped/quantized lighting for faceted look
float toon_shading(float value, float levels) {
    return round(value * levels) / levels;
}

void vertex() {
    // Keep vertex position as-is
}

void fragment() {
    // Get the flat normal for this fragment
    vec3 flat_normal = get_flat_normal();
    NORMAL = flat_normal;
    
    // Calculate view-dependent edge detection
    vec3 view_dir = normalize(VIEW);
    float edge_detect = 1.0 - abs(dot(view_dir, flat_normal));
    edge_detect = smoothstep(1.0 - edge_thickness, 1.0, edge_detect);
    
    // Basic diffuse with toon shading
    float NdotL = dot(flat_normal, normalize(vec3(0.5, 0.7, 0.3)));
    NdotL = toon_shading(max(0.0, NdotL), light_levels);
    
    // Specular highlights with toon shading
    vec3 half_vector = normalize(view_dir + normalize(vec3(0.5, 0.7, 0.3)));
    float spec = pow(max(0.0, dot(flat_normal, half_vector)), facet_sharpness * 10.0);
    spec = step(1.0 - specular_size, spec) * specular_intensity;
    
    // Rim lighting for edge emphasis
    float rim = pow(1.0 - dot(view_dir, flat_normal), rim_light_power);
    rim = toon_shading(rim, 2.0) * rim_light_intensity;
    
    // Combine colors
    vec3 base_color = gem_color.rgb * NdotL;
    vec3 final_color = mix(base_color, edge_color.rgb, edge_detect);
    final_color += vec3(spec);
    final_color += gem_color.rgb * rim * 0.5;
    
    ALBEDO = final_color;
    ROUGHNESS = 0.1;
    METALLIC = 0.0;
    SPECULAR = 1.0;
}