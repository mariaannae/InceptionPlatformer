shader_type canvas_item;

// Screen texture uniform (required in Godot 4)
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Dissolve progress: 0.0 = fully visible, 1.0 = fully dissolved
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;

// Size of pixelated blocks
uniform float block_size : hint_range(2.0, 32.0) = 8.0;

// Color to dissolve to (default black)
uniform vec4 dissolve_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Simple noise function for randomization
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // Sample the screen behind this overlay
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    
    // Calculate block coordinates for pixelation
    vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 block_coord = floor(SCREEN_UV * viewport_size / block_size);
    
    // Generate random value for this block
    float block_random = random(block_coord);
    
    // Determine if this block should be dissolved based on progress
    // The dissolve happens at different times for different blocks
    float dissolve_threshold = block_random;
    
    // Add a slight fade effect near the dissolve edge for smoother transition
    float edge_width = 0.1;
    float edge_fade = smoothstep(dissolve_threshold - edge_width, dissolve_threshold, dissolve_progress);
    
    // Clamp edge_fade to ensure no artifacts when progress is 0 or 1
    edge_fade = clamp(edge_fade, 0.0, 1.0);
    
    // When dissolve_progress is near 0, force edge_fade to 0
    // When dissolve_progress is near 1, force edge_fade to 1
    edge_fade = mix(0.0, edge_fade, step(0.001, dissolve_progress));
    edge_fade = mix(edge_fade, 1.0, step(0.999, dissolve_progress));
    
    // Mix between screen color and dissolve color based on progress
    COLOR = mix(screen_color, dissolve_color, edge_fade);
}
