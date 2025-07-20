shader_type spatial;
render_mode cull_disabled, unshaded;

// Gem properties
uniform vec4 gem_color : source_color = vec4(0.9, 0.15, 0.2, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.5, 0.6, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.4, 0.05, 0.1, 1.0);
uniform vec4 outline_color : source_color = vec4(0.2, 0.0, 0.0, 1.0);

// Lighting control
uniform float light_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

// Store world position
varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    // Scale vertices slightly outward for outline effect
    vec4 clip_position = PROJECTION_MATRIX * (VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0));
    vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX) * NORMAL);
    
    vec2 offset = normalize(clip_normal.xy) * outline_width * clip_position.w;
    clip_position.xy += offset;
    
    POSITION = clip_position;
}

// Calculate flat normal from world position
vec3 get_flat_normal() {
    vec3 pos_dx = dFdx(world_pos);
    vec3 pos_dy = dFdy(world_pos);
    return normalize(cross(pos_dy, pos_dx));
}

void fragment() {
    // Get flat normal for faceted appearance
    vec3 flat_normal = get_flat_normal();
    
    // Simple directional light calculation
    vec3 light_dir = normalize(vec3(0.5, 0.7, 0.3));
    float NdotL = dot(flat_normal, light_dir);
    
    // Three-tone shading
    vec3 color;
    if (NdotL > light_threshold) {
        color = highlight_color.rgb;
    } else if (NdotL > shadow_threshold) {
        color = gem_color.rgb;
    } else {
        color = shadow_color.rgb;
    }
    
    // Edge detection for outline
    vec3 view_dir = normalize(VIEW);
    float edge = 1.0 - abs(dot(view_dir, flat_normal));
    
    // Apply outline
    if (edge > 0.8) {
        color = mix(color, outline_color.rgb, smoothstep(0.8, 0.95, edge));
    }
    
    ALBEDO = color;
}