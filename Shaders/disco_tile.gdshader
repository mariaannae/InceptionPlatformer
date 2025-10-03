shader_type canvas_item;

// Disco colors
uniform vec3 neon_pink : source_color = vec3(1.0, 0.0, 0.8);
uniform vec3 neon_blue : source_color = vec3(0.0, 0.5, 1.0);
uniform vec3 neon_green : source_color = vec3(0.0, 1.0, 0.5);
uniform vec3 neon_purple : source_color = vec3(0.8, 0.0, 1.0);
uniform vec3 floor_light : source_color = vec3(0.8, 0.2, 0.6);
uniform vec3 floor_medium : source_color = vec3(0.2, 0.6, 0.8);
uniform vec3 floor_dark : source_color = vec3(0.6, 0.2, 0.8);
uniform vec3 club_black : source_color = vec3(0.02, 0.02, 0.05);
uniform vec3 club_shadow : source_color = vec3(0.05, 0.05, 0.1);
uniform vec3 mirror_sparkle : source_color = vec3(1.0, 1.0, 1.0);

uniform float seed : hint_range(0.0, 1000.0) = 1.0;
uniform int tile_type : hint_range(0, 3) = 0;

float hash(vec2 p) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
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

// Checkered pattern for dance floor
float checkerboard(vec2 p, float size) {
    vec2 tile = floor(p / size);
    return mod(tile.x + tile.y, 2.0);
}

void fragment() {
    vec2 uv = UV;
    vec2 pos = uv * 32.0;
    
    vec3 final_color;
    
    if (tile_type == 3) { // ENDGOAL - disco ball effect with diffuse iridescence
        // Spinning disco ball pattern
        float angle = atan(uv.y - 0.5, uv.x - 0.5) + seed * 0.1;
        float dist = length(uv - vec2(0.5));
        
        // Softer, more diffuse iridescent pattern
        // Reduced frequency for gradual transitions
        float pattern1 = sin(angle * 3.0 + seed * 0.05) * 0.5 + 0.5;
        float pattern2 = sin(dist * 8.0 + seed * 0.08) * 0.5 + 0.5;
        
        // Combine patterns with smooth noise for organic feel
        float iridescent = pattern1 * 0.4 + pattern2 * 0.3 + noise(uv * 10.0 + seed * 0.01) * 0.3;
        iridescent = smoothstep(0.2, 0.8, iridescent); // Smooth gradient instead of hard edges
        
        // Gradual color transitions through multiple colors
        vec3 color1 = neon_pink;
        vec3 color2 = neon_purple;
        vec3 color3 = neon_blue;
        vec3 color4 = neon_green;
        
        // Create smooth gradient through all colors
        float color_phase = fract(iridescent + angle / (2.0 * 3.14159) + seed * 0.02);
        vec3 ball_color;
        if (color_phase < 0.25) {
            ball_color = mix(color1, color2, color_phase * 4.0);
        } else if (color_phase < 0.5) {
            ball_color = mix(color2, color3, (color_phase - 0.25) * 4.0);
        } else if (color_phase < 0.75) {
            ball_color = mix(color3, color4, (color_phase - 0.5) * 4.0);
        } else {
            ball_color = mix(color4, color1, (color_phase - 0.75) * 4.0);
        }
        
        // Subtle sparkle highlights (much softer than before)
        float sparkle = smoothstep(0.85, 0.95, pattern1 * pattern2);
        final_color = mix(ball_color, mirror_sparkle, sparkle * 0.3);
        
        // Pulsing glow
        float pulse = sin(seed * 0.2) * 0.2 + 0.8;
        final_color *= pulse;
    }
    else if (tile_type == 0) { // Ground tile - checkered dance floor on top only
        vec3 tile_color;
        
        // Surface depth (top 6 pixels are checkered)
        if (uv.y < 0.19) { // Top ~6 pixels out of 32
            // Top surface - checkered pattern
            float checker = checkerboard(pos, 16.0);
            tile_color = mix(floor_light, floor_dark, checker);
            
            // Edge highlights for depth
            float edge_x = smoothstep(0.0, 0.1, uv.x) * smoothstep(1.0, 0.9, uv.x);
            float edge = edge_x;
            tile_color *= (0.9 + edge * 0.1);
        } else {
            // Below surface - solid underground color
            tile_color = floor_dark * 0.8;
            
            // Add subtle texture
            float tex = noise(pos * 0.5) * 0.1;
            tile_color += vec3(tex);
        }
        
        final_color = tile_color;
    }
    else if (tile_type == 1) { // Wall tile - dark with neon strips
        // Dark nightclub wall
        vec3 wall_color = club_shadow;
        
        // Vertical neon strips
        float strip_pattern = sin(pos.x * 0.3) * sin(pos.y * 0.15);
        if (strip_pattern > 0.7) {
            // Choose neon color based on position
            float color_selector = hash(floor(pos * 0.1));
            vec3 neon_color;
            if (color_selector < 0.25) {
                neon_color = neon_pink;
            } else if (color_selector < 0.5) {
                neon_color = neon_blue;
            } else if (color_selector < 0.75) {
                neon_color = neon_green;
            } else {
                neon_color = neon_purple;
            }
            wall_color = mix(wall_color, neon_color, 0.6);
        }
        
        // Add some depth variation
        float depth = noise(pos * 0.2) * 0.2;
        wall_color += vec3(depth * 0.1);
        
        final_color = wall_color;
    }
    else { // Platform tile - checkered on top only
        vec3 platform_color;
        
        if (uv.y < 0.19) { // Top ~6 pixels
            // Top surface - checkered pattern
            float checker = checkerboard(pos, 8.0);
            platform_color = mix(floor_light, floor_dark, checker);
            
            // Slight edge glow
            float edge_x = smoothstep(0.0, 0.1, uv.x) * smoothstep(1.0, 0.9, uv.x);
            platform_color *= (0.9 + edge_x * 0.1);
        } else {
            // Below surface - solid color
            platform_color = floor_dark * 0.8;
        }
        
        final_color = platform_color;
    }
    
    COLOR = vec4(final_color, 1.0);
}
