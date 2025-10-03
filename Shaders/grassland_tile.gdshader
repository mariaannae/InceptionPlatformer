shader_type canvas_item;

// Realistic grassland colors - more muted and varied
uniform vec3 soil_dry : source_color = vec3(0.48, 0.38, 0.28);
uniform vec3 soil_wet : source_color = vec3(0.35, 0.28, 0.20);
uniform vec3 grass_fresh : source_color = vec3(0.35, 0.45, 0.25);  // Fresh green
uniform vec3 grass_normal : source_color = vec3(0.40, 0.42, 0.28); // Average green
uniform vec3 grass_dry : source_color = vec3(0.55, 0.50, 0.35);    // Yellowed grass
uniform vec3 grass_dark : source_color = vec3(0.25, 0.32, 0.18);   // Shadow grass
uniform vec3 flower_white : source_color = vec3(0.9, 0.9, 0.85);
uniform vec3 flower_yellow : source_color = vec3(0.85, 0.75, 0.35);
uniform vec3 stone_color : source_color = vec3(0.55, 0.52, 0.50);

uniform float seed : hint_range(0.0, 1000.0) = 1.0;
uniform int tile_type : hint_range(0, 3) = 0;

// Advanced hash for better randomness
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195) + seed);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// Improved noise with better interpolation
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // Quintic interpolation
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Multi-octave noise for organic patterns
float fbm(vec2 p, int octaves, float persistence) {
    float value = 0.0;
    float amplitude = 0.5;
    float total = 0.0;
    
    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(p);
        total += amplitude;
        p *= 2.0;
        amplitude *= persistence;
    }
    
    return value / total;
}

// Generate individual grass blades
vec3 generate_grass_blade(vec2 pos, float blade_seed) {
    // Blade properties from seed
    float height = 0.5 + blade_seed * 0.5;
    float curve = sin(pos.y * 3.0 + blade_seed * 6.28) * 0.1;
    float thickness = 1.0 - pos.y * 0.7;
    
    // Color variation
    vec3 blade_color = mix(grass_normal, grass_fresh, blade_seed * 0.5);
    if (blade_seed > 0.7) {
        blade_color = mix(blade_color, grass_dry, (blade_seed - 0.7) * 3.0);
    }
    
    // Shading
    float shade = thickness * (0.7 + curve * 0.3);
    return blade_color * shade * height;
}

// Realistic soil texture
vec3 generate_soil(vec2 pos) {
    float soil_noise = fbm(pos * 0.3, 3, 0.5);
    float moisture = noise(pos * 0.1 + vec2(100.0));
    
    vec3 soil = mix(soil_dry, soil_wet, moisture * 0.4);
    
    // Add tiny stones
    float stones = smoothstep(0.8, 0.82, noise(pos * 0.5));
    soil = mix(soil, stone_color, stones * 0.3);
    
    // Organic matter (darker spots)
    float organic = smoothstep(0.7, 0.75, noise(pos * 0.4 + vec2(50.0)));
    soil = mix(soil, soil_wet * 0.7, organic * 0.2);
    
    return soil * (0.9 + soil_noise * 0.1);
}

void fragment() {
    vec2 uv = UV;
    vec2 pos = uv * 32.0;
    vec3 final_color;
    
    if (tile_type == 3) { // ENDGOAL
        float goal_gradient = smoothstep(0.0, 1.0, uv.y);
        final_color = mix(vec3(0.0, 0.8, 0.2), vec3(0.0, 0.6, 0.0), goal_gradient);
        float pulse = sin(seed * 0.1) * 0.1 + 0.9;
        final_color *= pulse;
    }
    else if (tile_type == 0 || tile_type == 2) { // Ground tile or Platform - Worn earth/wood
        // Create natural platform (compressed earth with wood planks)
        float wood_grain = sin(pos.x * 0.5) * 0.5 + 0.5;
        vec3 platform = mix(soil_dry * 1.1, soil_wet * 1.2, wood_grain);
        
        // Wear patterns
        float wear = fbm(pos * 0.1, 3, 0.5);
        platform = mix(platform, soil_dry * 0.9, wear * 0.3);
        
        // Edge grass growth
        float edge_grass = 0.0;
        if (uv.y < 0.15) {
            edge_grass = noise(pos * 0.3);
            platform = mix(platform, grass_normal * 0.8, edge_grass * 0.4);
        }
        
        // Subtle moss in cracks
        float cracks = smoothstep(0.8, 0.85, noise(pos * 0.2));
        platform = mix(platform, grass_dark * 0.7, cracks * 0.2);
        
        final_color = platform;
    }
    else if (tile_type == 1) { // Wall tile - Dense hedge/bush
        // Create realistic hedge texture
        float bush_density = fbm(pos * 0.2, 4, 0.5);
        float depth = fbm(pos * 0.3 + vec2(50.0), 3, 0.6);
        
        // Base hedge color
        vec3 hedge = mix(grass_dark, grass_normal, depth);
        
        // Add leaf clusters
        float leaves = smoothstep(0.4, 0.6, noise(pos * 0.4));
        hedge = mix(hedge, grass_fresh, leaves * 0.3);
        
        // Shadow for depth
        float shadow_pattern = fbm(pos * 0.15, 2, 0.7);
        hedge *= 0.7 + shadow_pattern * 0.3;
        
        // Occasional flowers on hedge
        if (hash(floor(pos * 0.2)) > 0.9) {
            hedge = mix(hedge, flower_white * 0.9, 0.2);
        }
        
        // Branch/stem hints
        float branches = smoothstep(0.8, 0.82, noise(pos * vec2(0.1, 0.3)));
        hedge = mix(hedge, soil_wet, branches * 0.2);
        
        final_color = hedge;
    }
    
    // Global adjustments for realism
    // Add subtle grain/noise
    float grain = (hash(pos) - 0.5) * 0.02;
    final_color += vec3(grain);
    
    // Slight desaturation for realism
    float gray = dot(final_color, vec3(0.299, 0.587, 0.114));
    final_color = mix(final_color, vec3(gray), 0.1);
    
    // Ensure we don't exceed valid color range
    final_color = clamp(final_color, 0.0, 1.0);
    
    COLOR = vec4(final_color, 1.0);
}
