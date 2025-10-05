shader_type canvas_item;

// Adjustable parameters
uniform float iridescent_speed : hint_range(0.1, 5.0) = 1.0;
uniform float facet_scale : hint_range(5.0, 30.0) = 10.0;
uniform float brightness : hint_range(0.0, 2.0) = 0.8;
uniform float color_shift_range : hint_range(0.0, 2.0) = 1.0;
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;
uniform bool strobe_sync = true;
uniform float shine_speed : hint_range(0.1, 5.0) = 1.5;
uniform float shine_width : hint_range(0.05, 0.5) = 0.3;
uniform float shine_intensity : hint_range(0.0, 5.0) = 3.5;

// Hash function for randomness
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Convert HSV to RGB for rainbow colors
vec3 hsv_to_rgb(vec3 hsv) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
}

void fragment() {
    // Get base texture (the white disco ball PNG)
    vec4 tex = texture(TEXTURE, UV);
    
    // Only apply effect to non-transparent areas
    if (tex.a < 0.1) {
        discard;
    }
    
    float time = TIME + time_offset;
    vec2 uv = UV;
    
    // Create faceted mirror ball effect
    vec2 facet_uv = floor(uv * facet_scale) / facet_scale;
    float facet_id = hash(facet_uv);
    
    // Create sphere-like normal mapping
    vec2 sphere_uv = (uv - 0.5) * 2.0;
    float radius = length(sphere_uv);
    
    // Iridescent color shift based on position and time
    float hue = fract(facet_id * color_shift_range + time * iridescent_speed * 0.5);
    vec3 base_color = hsv_to_rgb(vec3(hue, 0.8, 1.0)) * brightness;
    
    // Darken edges for spherical appearance
    float edge_darkening = smoothstep(1.0, 0.6, radius);
    base_color *= edge_darkening;
    
    // Add sweeping iridescent shine effect
    float shine_angle = time * shine_speed;
    
    // Rotate UV coordinates to create sweeping motion
    float cos_a = cos(shine_angle);
    float sin_a = sin(shine_angle);
    float rotated_x = sphere_uv.x * cos_a - sphere_uv.y * sin_a;
    
    // Create a vertical band that sweeps across
    float band_pos = rotated_x;
    
    // Add sphere curvature - the band should curve with the ball
    float sphere_depth = sqrt(max(0.0, 1.0 - radius * radius));
    float curved_band = band_pos * (0.8 + sphere_depth * 0.2);
    
    // Create the shine band with smooth falloff
    float shine_factor = 1.0 - abs(curved_band / shine_width);
    shine_factor = max(0.0, shine_factor);
    shine_factor *= sphere_depth; // Brighter in center, fades at edges
    shine_factor *= smoothstep(0.9, 0.4, radius); // Fade at sphere edges
    
    // Iridescent color for the shine
    float shine_hue = fract(shine_angle / 6.28318 + sphere_uv.y * 0.3);
    vec3 shine_color = hsv_to_rgb(vec3(shine_hue, 0.9, 1.0));
    
    // Combine base color with shine
    vec3 final_color = base_color + (shine_color * shine_factor * shine_intensity);
    
    COLOR = vec4(final_color, tex.a);
}
