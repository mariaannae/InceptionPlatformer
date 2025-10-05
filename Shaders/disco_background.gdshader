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
    
    // Start with very dark background - almost black with slight purple/blue tint
    vec3 base_dark = vec3(0.02, 0.01, 0.05); // Very dark purple-blue
    vec3 color = base_dark;
    
    // Add subtle dark gradient (slightly lighter at bottom)
    float gradient = smoothstep(0.0, 1.0, uv.y);
    color = mix(color, vec3(0.03, 0.02, 0.08), gradient * 0.3);
    
    // STROBE LIGHT EFFECT - Subtle nightclub strobe
    // Strobe flashes at ~1Hz (once per second)
    float strobe_speed = 1.0;
    float strobe_time = time * strobe_speed;
    
    // Create quick flash pattern: on for 0.05 seconds, off for the rest
    float strobe_cycle = fract(strobe_time);
    float strobe_flash = step(strobe_cycle, 0.1); // Flash for 10% of cycle
    
    // Make the flash subtle
    float strobe_intensity = strobe_flash * smoothstep(0.0, 0.03, strobe_cycle) * smoothstep(0.1, 0.07, strobe_cycle);
    
    // Strobe color (dimmer white with slight purple tint)
    vec3 strobe_color = vec3(0.4, 0.35, 0.45);
    
    // Apply subtle strobe light to entire scene
    color = mix(color, strobe_color, strobe_intensity * 0.25);
    
    // Add subtle floor indication with strobe-lit effect
    if (uv.y > 0.7) {
        float floor_fade = smoothstep(0.7, 1.0, uv.y);
        vec3 floor_color = vec3(0.05, 0.03, 0.1);
        
        // Floor gets subtly lit during strobe
        floor_color = mix(floor_color, vec3(0.2, 0.15, 0.25), strobe_intensity);
        
        color = mix(color, floor_color, floor_fade * 0.4);
    }
    
    // Add very subtle atmospheric depth with noise
    float atmosphere = noise(vec2(uv.x * 3.0, uv.y * 2.0 + time * 0.1));
    atmosphere = smoothstep(0.4, 0.6, atmosphere);
    color = mix(color, vec3(0.04, 0.02, 0.08), atmosphere * 0.1);
    
    COLOR = vec4(color, 1.0);
}
