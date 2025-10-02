shader_type canvas_item;

// Style parameters
uniform vec3 color1 : source_color = vec3(0.1, 0.1, 0.2);
uniform vec3 color2 : source_color = vec3(0.3, 0.4, 0.5);
uniform vec3 color3 : source_color = vec3(0.6, 0.7, 0.8);
uniform float seed : hint_range(0.0, 1000.0) = 1.0;
uniform int tile_type : hint_range(0, 2) = 0; // 0=ground, 1=wall, 2=platform

// Hash function for pseudo-random values
float hash(vec2 p) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

// Dither pattern (Bayer matrix 4x4)
float dither4x4(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    
    float bayer[16] = float[](
        0.0, 8.0, 2.0, 10.0,
        12.0, 4.0, 14.0, 6.0,
        3.0, 11.0, 1.0, 9.0,
        15.0, 7.0, 13.0, 5.0
    );
    
    return bayer[x + y * 4] / 16.0;
}

void fragment() {
    vec2 uv = UV * 32.0; // Scale to 32x32 tile
    vec2 pixel_pos = floor(uv);
    
    // Generate base noise pattern
    float noise1 = hash(pixel_pos * 0.5);
    float noise2 = hash(pixel_pos * 0.25 + vec2(100.0, 50.0));
    
    // Create pattern based on tile type
    float pattern_value = 0.0;
    
    if (tile_type == 0) { // Ground tile
        // Rocky/blocky pattern with dithering
        float blocks = step(0.6, hash(floor(pixel_pos * 0.25)));
        pattern_value = blocks * 0.5 + noise1 * 0.3;
    } else if (tile_type == 1) { // Wall tile
        // Brick-like pattern
        float brick_x = floor(pixel_pos.x * 0.25);
        float brick_y = floor(pixel_pos.y * 0.25);
        float offset = mod(brick_y, 2.0) * 2.0;
        float brick_pattern = step(0.8, fract((brick_x + offset) * 0.5));
        pattern_value = brick_pattern * 0.4 + noise1 * 0.4;
    } else { // Platform tile
        // Simpler checkered pattern
        float checker = mod(floor(pixel_pos.x * 0.5) + floor(pixel_pos.y * 0.5), 2.0);
        pattern_value = checker * 0.5 + 0.25;
    }
    
    // Apply dithering for pixel art effect
    float dither = dither4x4(pixel_pos);
    pattern_value += (dither - 0.5) * 0.2;
    
    // Quantize to limited palette (3 colors)
    vec3 final_color;
    if (pattern_value < 0.33) {
        final_color = color1;
    } else if (pattern_value < 0.66) {
        final_color = color2;
    } else {
        final_color = color3;
    }
    
    // Add crisp outline on tile edges for pixel art look
    float edge_x = step(uv.x, 1.0) + step(31.0, uv.x);
    float edge_y = step(uv.y, 1.0) + step(31.0, uv.y);
    float edge = max(edge_x, edge_y);
    final_color = mix(final_color, final_color * 0.7, edge * 0.3);
    
    COLOR = vec4(final_color, 1.0);
}
