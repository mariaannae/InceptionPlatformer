shader_type canvas_item;

// Style parameters
uniform vec3 base_color : source_color = vec3(0.4, 0.3, 0.6);
uniform vec3 highlight_color : source_color = vec3(0.7, 0.6, 0.9);
uniform vec3 shadow_color : source_color = vec3(0.2, 0.15, 0.3);
uniform float seed : hint_range(0.0, 1000.0) = 1.0;
uniform int tile_type : hint_range(0, 2) = 0; // 0=ground, 1=wall, 2=platform

// Hash function for noise
float hash(vec2 p) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth noise (Perlin-like)
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Smooth interpolation (smoothstep)
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal noise (multiple octaves)
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// Smooth gradient
float smooth_gradient(float t) {
    return t * t * (3.0 - 2.0 * t);
}

void fragment() {
    vec2 uv = UV;
    vec2 tile_uv = uv * 32.0;
    
    // Generate multi-layered noise for organic look
    float noise_large = fbm(tile_uv * 0.05);
    float noise_medium = fbm(tile_uv * 0.15);
    float noise_small = fbm(tile_uv * 0.4);
    
    // Combine noise layers
    float combined_noise = noise_large * 0.5 + noise_medium * 0.3 + noise_small * 0.2;
    
    // Create base gradient based on tile type
    float gradient = 0.0;
    
    if (tile_type == 0) { // Ground tile
        // Top-to-bottom gradient with noise
        gradient = smooth_gradient(1.0 - uv.y);
        gradient += combined_noise * 0.3;
    } else if (tile_type == 1) { // Wall tile
        // Left-to-right gradient with noise
        gradient = smooth_gradient(uv.x);
        gradient += combined_noise * 0.3;
    } else { // Platform tile
        // Center-focused gradient
        float center_dist = length(uv - vec2(0.5, 0.5)) * 1.4;
        gradient = 1.0 - smooth_gradient(center_dist);
        gradient += combined_noise * 0.2;
    }
    
    // Clamp gradient
    gradient = clamp(gradient, 0.0, 1.0);
    
    // Create smooth color blend
    vec3 color;
    if (gradient < 0.5) {
        // Blend from shadow to base
        color = mix(shadow_color, base_color, gradient * 2.0);
    } else {
        // Blend from base to highlight
        color = mix(base_color, highlight_color, (gradient - 0.5) * 2.0);
    }
    
    // Add subtle organic variation
    float variation = fbm(tile_uv * 0.2 + vec2(seed * 0.1)) * 0.1;
    color += vec3(variation);
    
    // Add soft edge highlighting
    float edge_glow = 0.0;
    edge_glow += smoothstep(0.95, 1.0, uv.x) * 0.15;
    edge_glow += smoothstep(0.95, 1.0, uv.y) * 0.15;
    edge_glow += smoothstep(0.05, 0.0, uv.x) * 0.1;
    edge_glow += smoothstep(0.05, 0.0, uv.y) * 0.1;
    
    color += vec3(edge_glow);
    
    COLOR = vec4(color, 1.0);
}
