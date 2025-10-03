shader_type canvas_item;

uniform float seed : hint_range(0.0, 1000.0) = 0.0;
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;
uniform vec4 neon_pink : source_color;
uniform vec4 neon_blue : source_color;
uniform vec4 neon_green : source_color;
uniform vec4 neon_purple : source_color;
uniform vec4 club_black : source_color;
uniform vec4 club_shadow : source_color;
uniform vec4 mirror_sparkle : source_color;

// Hash function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

// Smooth noise
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

void fragment() {
    vec2 uv = UV;
    float time = TIME + time_offset + seed * 0.1;
    
    // Start with club darkness
    vec3 color = club_black.rgb;
    
    // Checkerboard floor pattern (fading with distance)
    if (uv.y > 0.6) {
        float checker_scale = 15.0;
        vec2 checker = floor(uv * checker_scale);
        float checker_pattern = mod(checker.x + checker.y, 2.0);
        
        // Fade checkerboard based on distance from bottom
        float fade = smoothstep(0.6, 1.0, uv.y);
        vec3 checker_dark = club_shadow.rgb;
        vec3 checker_light = club_shadow.rgb * 1.5;
        vec3 checker_color = mix(checker_dark, checker_light, checker_pattern);
        
        color = mix(color, checker_color, fade * 0.6);
    }
    
    // Radial spotlight beams from ceiling
    vec2 center = vec2(0.5, 0.0);
    float angle = atan(uv.y - center.y, uv.x - center.x);
    
    // Create rotating spotlight beams
    for (float i = 0.0; i < 4.0; i += 1.0) {
        float beam_angle = (time * 0.3 + i * 1.57 + seed) * (mod(i, 2.0) == 0.0 ? 1.0 : -1.0);
        float angle_diff = abs(mod(angle - beam_angle + 3.14159, 6.28318) - 3.14159);
        
        // Cone shape for spotlight
        float beam_width = 0.3;
        float beam = smoothstep(beam_width, 0.0, angle_diff);
        
        // Fade based on distance from top
        float dist_fade = 1.0 - smoothstep(0.0, 0.7, uv.y);
        beam *= dist_fade;
        
        // Choose color based on beam index
        vec3 beam_color;
        if (i == 0.0) beam_color = neon_pink.rgb;
        else if (i == 1.0) beam_color = neon_blue.rgb;
        else if (i == 2.0) beam_color = neon_green.rgb;
        else beam_color = neon_purple.rgb;
        
        // Add beam with low intensity
        color = mix(color, beam_color, beam * 0.15);
    }
    
    // Mirror ball reflections (scattered light spots)
    float mirror_ball_noise = noise(uv * 20.0 + vec2(time * 0.5, 0.0));
    if (mirror_ball_noise > 0.85) {
        // Twinkling effect
        float twinkle = sin(time * 3.0 + hash(floor(uv * 20.0)) * 6.28) * 0.5 + 0.5;
        color = mix(color, mirror_sparkle.rgb, twinkle * 0.4);
    }
    
    // Add more scattered light spots (smaller, more frequent)
    float light_spots = noise(uv * 50.0 + vec2(time * 1.0, time * 0.5));
    if (light_spots > 0.9) {
        // Random color for each spot
        float spot_hash = hash(floor(uv * 50.0));
        vec3 spot_color;
        if (spot_hash < 0.25) spot_color = neon_pink.rgb;
        else if (spot_hash < 0.5) spot_color = neon_blue.rgb;
        else if (spot_hash < 0.75) spot_color = neon_green.rgb;
        else spot_color = neon_purple.rgb;
        
        color = mix(color, spot_color, 0.3);
    }
    
    // Add vertical light strips on sides (club lighting)
    float strip1 = smoothstep(0.15, 0.12, abs(uv.x - 0.1));
    float strip2 = smoothstep(0.15, 0.12, abs(uv.x - 0.9));
    
    // Pulsing effect on strips
    float pulse = sin(time * 2.0 + seed) * 0.5 + 0.5;
    vec3 strip_color = mix(neon_purple.rgb, neon_pink.rgb, pulse);
    
    color = mix(color, strip_color, (strip1 + strip2) * 0.2 * (1.0 - uv.y * 0.5));
    
    // Add atmospheric haze
    float haze = noise(vec2(uv.x * 5.0, uv.y * 3.0 + time * 0.2));
    haze = smoothstep(0.3, 0.7, haze);
    color = mix(color, club_shadow.rgb * 1.5, haze * 0.1);
    
    COLOR = vec4(color, 1.0);
}
