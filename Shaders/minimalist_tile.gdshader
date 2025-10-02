shader_type canvas_item;

// Style parameters
uniform vec3 primary_color : source_color = vec3(0.2, 0.3, 0.5);
uniform vec3 secondary_color : source_color = vec3(0.8, 0.8, 0.9);
uniform float seed : hint_range(0.0, 1000.0) = 1.0;
uniform int tile_type : hint_range(0, 2) = 0; // 0=ground, 1=wall, 2=platform

// Simple hash function for noise
float hash(vec2 p) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth noise function
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
    vec2 uv = UV * 32.0; // Scale to 32x32 tile
    vec2 pixel_uv = floor(uv);
    
    // Base pattern selection based on tile type
    float pattern = 0.0;
    
    if (tile_type == 0) { // Ground tile
        // Horizontal stripes with noise
        pattern = step(0.5, fract(uv.y * 0.25 + noise(pixel_uv * 0.1) * 0.3));
    } else if (tile_type == 1) { // Wall tile
        // Vertical stripes with noise
        pattern = step(0.5, fract(uv.x * 0.25 + noise(pixel_uv * 0.1) * 0.3));
    } else { // Platform tile
        // Simpler pattern - mostly solid with edge detail
        float edge = max(
            step(uv.y, 2.0), 
            step(30.0, uv.y)
        );
        pattern = edge * 0.5 + 0.3;
    }
    
    // Add subtle noise variation
    float noise_val = noise(pixel_uv * 0.3) * 0.15;
    
    // Mix colors based on pattern
    vec3 color = mix(primary_color, secondary_color, pattern + noise_val);
    
    // Add slight geometric variation
    float grid = step(0.9, fract(uv.x * 0.125)) + step(0.9, fract(uv.y * 0.125));
    color += vec3(grid * 0.05);
    
    COLOR = vec4(color, 1.0);
}
