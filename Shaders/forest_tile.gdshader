shader_type canvas_item;

// Forest biome colors
uniform vec3 canopy_light : source_color = vec3(0.4, 0.6, 0.3);
uniform vec3 canopy_medium : source_color = vec3(0.25, 0.4, 0.2);
uniform vec3 canopy_dark : source_color = vec3(0.1, 0.2, 0.05);
uniform vec3 bark_light : source_color = vec3(0.4, 0.3, 0.2);
uniform vec3 bark_dark : source_color = vec3(0.2, 0.15, 0.1);
uniform vec3 moss_color : source_color = vec3(0.3, 0.35, 0.2);
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

float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    
    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
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
    else if (tile_type == 0) { // Ground tile (forest floor)
        // Create forest floor with leaves, twigs, moss
        float leaves = fbm(pos * 0.15, 4);
        float moss_patches = smoothstep(0.4, 0.7, noise(pos * 0.1));
        float twigs = step(0.8, noise(pos * vec2(0.5, 0.1)));
        
        // Base is decomposed leaves and earth
        vec3 floor_base = mix(bark_dark, canopy_dark, 0.5);
        vec3 floor_color = mix(floor_base, bark_light * 0.8, leaves * 0.4);
        
        // Add moss patches
        floor_color = mix(floor_color, moss_color, moss_patches * 0.6);
        
        // Add scattered leaves on top
        if (uv.y < 0.3) {
            float leaf_scatter = noise(pos * 0.2);
            if (leaf_scatter > 0.7) {
                floor_color = mix(floor_color, canopy_medium * 0.8, 0.5);
            }
        }
        
        // Add twigs
        floor_color = mix(floor_color, bark_dark * 0.7, twigs * 0.3);
        
        final_color = floor_color;
    }
    else if (tile_type == 1) { // Wall tile (tree trunk)
        // Create realistic bark texture
        float bark_vertical = fbm(pos * vec2(0.05, 0.3), 3);
        float bark_horizontal = noise(pos * vec2(0.2, 0.05));
        float bark_cracks = step(0.7, fbm(pos * 0.2, 2));
        
        vec3 trunk_color = mix(bark_dark, bark_light, bark_vertical);
        trunk_color = mix(trunk_color, bark_dark * 0.7, bark_cracks);
        
        // Add moss on one side
        float moss_growth = smoothstep(0.3, 0.7, noise(pos * 0.15));
        if (uv.x < 0.4) {
            moss_growth *= smoothstep(0.4, 0.0, uv.x);
            trunk_color = mix(trunk_color, moss_color * 0.8, moss_growth * 0.5);
        }
        
        // Add some leaves/vines
        if (bark_horizontal > 0.8 && noise(pos * 0.5) > 0.7) {
            trunk_color = mix(trunk_color, canopy_dark, 0.3);
        }
        
        final_color = trunk_color;
    }
    else { // Platform tile (tree branch/wooden platform)
        // Create branch/wood platform texture
        float wood_grain = sin(pos.x * 0.3 + noise(pos * vec2(0.05, 0.01)) * 1.5) * 0.5 + 0.5;
        float moss_coverage = noise(pos * 0.2);
        
        vec3 branch_color = mix(bark_dark, bark_light, wood_grain);
        
        // Top surface has moss and leaves
        if (uv.y < 0.25) {
            float leaves = fbm(pos * 0.3, 2);
            branch_color = mix(branch_color, moss_color, moss_coverage * 0.4);
            if (leaves > 0.6) {
                branch_color = mix(branch_color, canopy_medium, 0.3);
            }
        }
        
        // Add knots and imperfections
        float knots = smoothstep(0.8, 0.9, noise(pos * 0.1));
        branch_color = mix(branch_color, bark_dark * 0.6, knots);
        
        final_color = branch_color;
    }
    
    // Forest ambient occlusion (darker at bottom)
    float ao = pow(uv.y, 0.5);
    final_color *= (0.7 + ao * 0.3);
    
    // Dappled light effect (sunlight through canopy)
    float dappled = fbm(pos * 0.08 + vec2(seed * 0.01), 2);
    if (dappled > 0.6) {
        final_color *= 1.2;
    }
    
    COLOR = vec4(final_color, 1.0);
}