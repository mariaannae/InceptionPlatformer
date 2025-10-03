shader_type canvas_item;

// Disco light parameters
uniform float rotation_speed : hint_range(0.1, 5.0) = 0.3;
uniform float light_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float strobe_speed : hint_range(0.5, 5.0) = 0.8;

// Neon colors
uniform vec3 neon_pink : source_color = vec3(1.0, 0.0, 0.8);
uniform vec3 neon_blue : source_color = vec3(0.0, 0.5, 1.0);
uniform vec3 neon_green : source_color = vec3(0.0, 1.0, 0.5);
uniform vec3 neon_purple : source_color = vec3(0.8, 0.0, 1.0);

uniform float light_seed : hint_range(0.0, 1000.0) = 0.0;

// Simple hash for randomization
float hash(float n) {
    return fract(sin(n + light_seed) * 43758.5453);
}

// Rotating spotlight effect
vec3 spotlight(vec2 world_pos, float time, float angle_offset, vec3 color) {
    float angle = time * rotation_speed + angle_offset;
    vec2 light_dir = vec2(cos(angle), sin(angle));
    
    // Distance from spotlight beam
    float beam_dist = abs(dot(world_pos, vec2(-light_dir.y, light_dir.x)));
    
    // Spotlight cone
    float spotlight_intensity = smoothstep(150.0, 50.0, beam_dist);
    spotlight_intensity *= smoothstep(-200.0, 200.0, dot(world_pos, light_dir));
    
    return color * spotlight_intensity;
}

// Strobe light effect
float strobe(float time, float offset) {
    float strobe_time = time * strobe_speed + offset;
    return step(0.7, fract(strobe_time)) * 0.5;
}

void fragment() {
    // Sample the original tile texture
    vec4 original_color = texture(TEXTURE, UV);
    
    // Use VERTEX for actual world position in the TileMap's coordinate space
    vec2 world_pos = VERTEX;
    
    // Only apply effect to non-black pixels (actual tiles)
    float brightness = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    
    if (brightness > 0.1) {
        // Add iridescent shimmer to floor tiles (HSV-based like bubble shader)
        vec3 iridescent_effect = vec3(0.0);
        
        // Only apply iridescence to brighter tiles (the floor)
        if (brightness > 0.2) {
            // Create thin-film interference pattern
            float wave1 = sin(world_pos.x * 0.02 - TIME * 0.5 + world_pos.y * 0.015);
            float wave2 = sin(world_pos.x * 0.015 + TIME * 0.4 + world_pos.y * 0.02);
            float wave3 = cos(world_pos.x * 0.025 - TIME * 0.6 - world_pos.y * 0.01);
            
            // Combine waves
            float interference = wave1 * 0.35 + wave2 * 0.35 + wave3 * 0.3;
            interference = interference * 0.5 + 0.5;  // Normalize to 0-1
            interference = smoothstep(0.2, 0.8, interference);  // Smooth transitions
            
            // Convert to HSV for smooth color cycling
            float hue_shift = interference * 2.0;  // Color bands
            
            // Smooth hue transitions
            float h1 = fract(hue_shift + TIME * 0.05);
            float h2 = fract(hue_shift + TIME * 0.05 + 0.15);
            float blend_factor = smoothstep(0.3, 0.7, fract(hue_shift * 2.0));
            float h = mix(h1, h2, blend_factor);
            
            float s = 0.9;  // High saturation for vibrant colors
            float v = 0.85 + 0.15 * interference;  // Brightness varies with interference
            
            // HSV to RGB conversion
            vec3 p = abs(fract(vec3(h) + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
            vec3 iridescent_color = v * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), s);
            
            iridescent_effect = iridescent_color * 1.2;
        }
        
        // Create multiple rotating spotlights
        vec3 light1 = spotlight(world_pos, TIME, 0.0, neon_pink);
        vec3 light2 = spotlight(world_pos, TIME, 2.0944, neon_blue);  // 120 degrees
        vec3 light3 = spotlight(world_pos, TIME, 4.1888, neon_green);  // 240 degrees
        vec3 light4 = spotlight(world_pos, TIME, 1.5708, neon_purple); // 90 degrees
        
        // Combine iridescence and spotlights
        vec3 combined_lights = iridescent_effect + light1 + light2 + light3 + light4;
        
        // Add strobe effects at random positions
        float strobe1 = strobe(TIME, hash(1.0) * 10.0);
        float strobe2 = strobe(TIME, hash(2.0) * 10.0);
        float strobe3 = strobe(TIME, hash(3.0) * 10.0);
        
        // Strobe flashes across the whole floor
        vec3 strobe_color = (neon_pink + neon_blue + neon_green) / 3.0;
        combined_lights += strobe_color * (strobe1 + strobe2 + strobe3) * 0.3;
        
        // For floor tiles with iridescence, blend differently
        vec3 final_color;
        if (brightness > 0.2 && length(iridescent_effect) > 0.1) {
            // Replace floor color with iridescence, then add subtle spotlights
            final_color = mix(original_color.rgb, iridescent_effect, 0.85);
            final_color += (light1 + light2 + light3 + light4) * light_intensity;
            final_color += strobe_color * (strobe1 + strobe2 + strobe3) * light_intensity;
        } else {
            // Walls and platforms just get lights added
            final_color = original_color.rgb + combined_lights * light_intensity;
        }
        
        // Mirror ball sparkles disabled - let iridescence show
        
        COLOR = vec4(final_color, original_color.a);
    } else {
        // Keep background/black areas unchanged
        COLOR = original_color;
    }
}
