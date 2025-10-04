shader_type canvas_item;

uniform float seed : hint_range(0.0, 1000.0) = 0.0;
uniform vec4 canopy_light : source_color;
uniform vec4 canopy_medium : source_color;
uniform vec4 canopy_dark : source_color;
uniform vec4 bark_light : source_color;
uniform vec4 bark_dark : source_color;

// Hash function for star placement
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    
    // Night sky gradient from black (bottom) to dark blue (top)
    // Smooth vertical gradient
    vec3 black = vec3(0.0, 0.0, 0.0);
    vec3 dark_blue = vec3(0.0, 0.05, 0.15);  // Very dark blue
    
    // Smooth gradient from bottom to top
    float gradient = smoothstep(0.0, 1.0, 1.0 - uv.y);  // Inverted so black is at bottom
    vec3 color = mix(black, dark_blue, gradient);
    
    // Add twinkling stars
    // Create a grid of potential star positions
    vec2 star_uv = uv * 50.0;  // Scale to create more star positions
    vec2 star_id = floor(star_uv);
    
    // Use hash to determine if this grid cell has a star
    float star_chance = hash(star_id);
    
    if (star_chance > 0.92) {  // Only ~8% of cells have stars
        // Get position within the cell
        vec2 cell_pos = fract(star_uv);
        
        // Center the star in the cell with slight random offset
        vec2 star_offset = vec2(hash(star_id + vec2(1.0, 0.0)), hash(star_id + vec2(0.0, 1.0)));
        vec2 star_center = star_offset * 0.5 + 0.25;  // Keep stars somewhat centered
        
        // Distance from star center
        float dist = distance(cell_pos, star_center);
        
        // Create star shape (small bright point)
        float star_size = 0.05 + hash(star_id + vec2(2.0, 0.0)) * 0.03;
        float star = smoothstep(star_size, 0.0, dist);
        
        // Twinkling effect using time and hash
        float twinkle_speed = 2.0 + hash(star_id + vec2(3.0, 0.0)) * 3.0;
        float twinkle_offset = hash(star_id + vec2(4.0, 0.0)) * 6.28;
        float twinkle = sin(TIME * twinkle_speed + twinkle_offset) * 0.5 + 0.5;
        twinkle = twinkle * twinkle;  // Make twinkling more dramatic
        
        // Apply twinkling to star brightness
        star *= twinkle;
        
        // Star color (slight variation in color)
        float color_var = hash(star_id + vec2(5.0, 0.0));
        vec3 star_color = vec3(0.9, 0.95, 1.0);  // Slightly bluish white
        if (color_var > 0.7) {
            star_color = vec3(1.0, 0.95, 0.9);  // Slightly warm white
        }
        
        // Add star to background
        color = mix(color, star_color, star * 0.8);
    }
    
    COLOR = vec4(color, 1.0);
}
