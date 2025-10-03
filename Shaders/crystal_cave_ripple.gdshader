shader_type canvas_item;

// Ripple animation parameters
uniform float flow_speed : hint_range(0.05, 1.0) = 0.2;
uniform float film_variation : hint_range(0.1, 2.0) = 0.6;
uniform float color_bands : hint_range(1.0, 5.0) = 2.5;
uniform float ripple_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float turbulence : hint_range(0.0, 1.0) = 0.3;
uniform float wave_seed : hint_range(0.0, 1000.0) = 0.0;

// Crystal colors for iridescence
uniform vec3 crystal_bright : source_color = vec3(0.5, 0.9, 1.0);
uniform vec3 crystal_medium : source_color = vec3(0.3, 0.6, 0.9);
uniform vec3 crystal_secondary : source_color = vec3(0.9, 0.5, 0.7);

// Simple noise function (since we don't have a texture)
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Create flowing distortion field
vec2 flowField(vec2 pos, float t) {
    vec2 flow1 = vec2(
        noise(pos * 0.03 + vec2(t * flow_speed, 0.0)),
        noise(pos * 0.03 + vec2(0.0, t * flow_speed))
    ) - 0.5;
    
    vec2 flow2 = vec2(
        noise(pos * 0.05 + vec2(0.0, t * flow_speed * 0.8)),
        noise(pos * 0.05 + vec2(t * flow_speed * 0.8, 0.0))
    ) - 0.5;
    
    return (flow1 + flow2 * 0.5) * turbulence;
}

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

// Simulate thin-film interference pattern
float thinFilmInterference(vec2 world_pos, float t, float seed) {
    // Add flow distortion
    vec2 distortion = flowField(world_pos, t);
    vec2 distorted_pos = world_pos + distortion * 30.0;
    
    // Use seed to randomize wave directions and speeds
    float angle1 = seed * 3.14159 * 2.0;
    float angle2 = (seed + 0.333) * 3.14159 * 2.0;
    float angle3 = (seed + 0.666) * 3.14159 * 2.0;
    
    vec2 dir1 = vec2(cos(angle1), sin(angle1));
    vec2 dir2 = vec2(cos(angle2), sin(angle2));
    vec2 dir3 = vec2(cos(angle3), sin(angle3));
    
    // Create directional wave patterns
    float wave1 = sin(dot(distorted_pos, dir1) * 0.08 - t * (2.0 + seed * 0.5));
    float wave2 = sin(dot(distorted_pos, dir2) * 0.06 + t * (1.5 + seed * 0.3));
    float wave3 = cos(dot(distorted_pos, dir3) * 0.10 - t * (1.8 + seed * 0.4));
    
    // Angular variation for more interest
    float angle = atan(distorted_pos.y, distorted_pos.x);
    float wave4 = sin(angle * 3.0 + t * 0.5 + seed);
    
    // Combine with noise for organic variation
    float noise_pattern = noise(world_pos * 0.02 + vec2(t * 0.1));
    
    // Mix waves with varying weights
    float pattern = wave1 * 0.3 + wave2 * 0.25 + wave3 * 0.25 + wave4 * 0.2;
    pattern += (noise_pattern - 0.5) * film_variation;
    
    // Normalize and smooth
    pattern = pattern * 0.5 + 0.5;
    return smoothstep(0.2, 0.8, pattern);
}

void fragment() {
    // Sample the original tile texture
    vec4 original_color = texture(TEXTURE, UV);
    
    // Get screen position - this is in screen-space pixels
    // For world-anchored effect, we use SCREEN_UV * viewport size + unique offset per level
    vec2 screen_uv = SCREEN_UV * 2048.0; // Arbitrary large value for world scale
    
    // Add seed-based offset so each level section has different pattern
    vec2 world_pos = screen_uv + vec2(wave_seed * 100.0, wave_seed * 150.0);
    
    // Calculate interference pattern with seed
    float interference = thinFilmInterference(world_pos, TIME, fract(wave_seed * 0.1));
    
    // Generate iridescent colors from interference with smooth blending
    float hue_shift = interference * color_bands;
    
    // Smooth the hue transitions
    float h1 = fract(hue_shift + TIME * 0.05);
    float h2 = fract(hue_shift + TIME * 0.05 + 0.15);
    float blend_factor = smoothstep(0.3, 0.7, fract(hue_shift * 2.0));
    float h = mix(h1, h2, blend_factor);
    
    // Saturation varies with interference
    float s = 0.6 + 0.3 * interference;
    
    // Brightness varies subtly
    float v = 0.7 + 0.2 * interference;
    
    vec3 iridescent = hsv2rgb(vec3(h, s, v));
    
    // Only apply effect to non-black pixels (actual tiles)
    float brightness = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    
    if (brightness > 0.1) {
        // Add ripple highlight (brighter areas where wave peaks)
        float highlight = smoothstep(0.3, 0.7, interference);
        
        // Blend iridescent effect with original color
        vec3 final_color = mix(original_color.rgb, iridescent, ripple_intensity * highlight);
        
        // Add subtle shimmer on interference peaks
        float shimmer = smoothstep(0.8, 1.0, interference) * 0.2;
        final_color += crystal_bright * shimmer * ripple_intensity;
        
        COLOR = vec4(final_color, original_color.a);
    } else {
        // Keep background/black areas unchanged
        COLOR = original_color;
    }
}
