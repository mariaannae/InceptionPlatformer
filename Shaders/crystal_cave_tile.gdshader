shader_type canvas_item;

// Crystal Cave biome colors
uniform vec3 crystal_bright : source_color = vec3(0.5, 0.9, 1.0);
uniform vec3 crystal_medium : source_color = vec3(0.3, 0.6, 0.9);
uniform vec3 crystal_dark : source_color = vec3(0.2, 0.4, 0.7);
uniform vec3 crystal_secondary : source_color = vec3(0.9, 0.5, 0.7);
uniform vec3 cave_black : source_color = vec3(0.05, 0.05, 0.08);
uniform vec3 cave_shadow : source_color = vec3(0.1, 0.1, 0.15);
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

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    
    for(int i = 0; i < 3; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// Crystal facet pattern
float crystal_facets(vec2 p) {
    float facet1 = abs(sin(p.x * 0.5 + p.y * 0.3));
    float facet2 = abs(cos(p.x * 0.3 - p.y * 0.4));
    float facet3 = abs(sin(p.x * 0.7 + p.y * 0.7));
    
    return max(max(facet1, facet2), facet3);
}

// Voronoi for crystal clusters
vec3 voronoi_crystal(vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    
    float min_dist = 1.0;
    vec2 min_point;
    float second_dist = 1.0;
    
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 point = hash(n + neighbor) * vec2(1.0) + neighbor;
            float dist = length(point - f);
            
            if(dist < min_dist) {
                second_dist = min_dist;
                min_dist = dist;
                min_point = n + neighbor;
            } else if(dist < second_dist) {
                second_dist = dist;
            }
        }
    }
    
    float edge = second_dist - min_dist;
    return vec3(min_dist, edge, hash(min_point));
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
    else if (tile_type == 0) { // Ground tile (crystal cave floor)
        // Dark cave floor with crystal shards
        float base_rock = fbm(pos * 0.15);
        vec3 vor = voronoi_crystal(pos * 0.15);
        
        vec3 floor_color = mix(cave_black, cave_shadow, base_rock * 0.5);
        
        // Crystal shards scattered on ground
        if (vor.x < 0.2) {
            float crystal_type = vor.z;
            vec3 shard_color = crystal_type > 0.5 ? crystal_dark : crystal_secondary * 0.7;
            
            // Crystal shimmer
            float shimmer = crystal_facets(pos);
            shard_color = mix(shard_color, crystal_bright, shimmer * 0.3);
            
            floor_color = mix(floor_color, shard_color, 0.6);
        }
        
        // Glowing crystal dust
        float dust = noise(pos * 0.05);
        if (dust > 0.7) {
            floor_color += crystal_medium * 0.1 * (dust - 0.7);
        }
        
        // Reflection from crystals above
        float reflection = sin(pos.x * 0.1 + seed) * sin(pos.y * 0.1) * 0.5 + 0.5;
        floor_color += crystal_bright * reflection * 0.05;
        
        final_color = floor_color;
    }
    else if (tile_type == 1) { // Wall tile (crystal formations)
        // Dark rock with large crystal formations
        float rock_base = fbm(pos * 0.1);
        vec3 vor = voronoi_crystal(pos * 0.08);
        
        vec3 wall_color = mix(cave_black, cave_shadow, rock_base * 0.3);
        
        // Large crystal clusters
        if (vor.x < 0.3) {
            float crystal_height = 1.0 - uv.y;
            float facet = crystal_facets(pos * 0.5);
            
            // Determine crystal color
            vec3 crystal_color;
            if (vor.z > 0.6) {
                crystal_color = mix(crystal_medium, crystal_bright, facet);
            } else if (vor.z > 0.3) {
                crystal_color = mix(crystal_dark, crystal_medium, facet);
            } else {
                crystal_color = mix(crystal_secondary, crystal_bright * 0.8, facet);
            }
            
            // Crystal intensity based on position
            float intensity = smoothstep(0.3, 0.0, vor.x) * crystal_height;
            wall_color = mix(wall_color, crystal_color, intensity);
            
            // Inner glow
            if (vor.x < 0.1) {
                wall_color += crystal_bright * 0.2;
            }
        }
        
        // Subtle crystal veins
        float veins = step(0.9, noise(pos * vec2(0.03, 0.3)));
        if (veins > 0.0) {
            wall_color = mix(wall_color, crystal_dark * 0.5, 0.3);
        }
        
        final_color = wall_color;
    }
    else { // Platform tile (crystal platform)
        // Crystalline platform
        vec3 vor = voronoi_crystal(pos * 0.2);
        float facet = crystal_facets(pos);
        
        // Base crystal structure
        vec3 platform_color = mix(crystal_dark, crystal_medium, facet);
        
        // Crystal edges and patterns
        if (vor.y > 0.1) {
            platform_color = mix(platform_color, crystal_bright, vor.y * 0.5);
        }
        
        // Top surface polish
        if (uv.y < 0.3) {
            platform_color = mix(platform_color, crystal_bright, 0.2);
            
            // Refraction effect
            float refraction = sin(pos.x * 0.3 + pos.y * 0.2) * 0.5 + 0.5;
            platform_color = mix(platform_color, crystal_secondary * 0.8, refraction * 0.2);
        }
        
        // Edge glow
        float edge = 0.0;
        if (uv.x < 0.1 || uv.x > 0.9 || uv.y < 0.1 || uv.y > 0.9) {
            edge = 1.0;
        }
        platform_color += crystal_bright * edge * 0.1;
        
        // Inner light
        float inner_light = 1.0 - length(uv - vec2(0.5, 0.5)) * 2.0;
        platform_color += crystal_bright * max(0.0, inner_light) * 0.1;
        
        final_color = platform_color;
    }
    
    // Crystal cave ambiance - glowing effect
    float glow = fbm(pos * 0.02 + vec2(seed * 0.01));
    final_color += crystal_medium * glow * 0.05;
    
    // Prismatic light scattering
    float scatter = sin(pos.x * 0.1 + pos.y * 0.15 + seed);
    if (scatter > 0.8) {
        final_color += crystal_secondary * 0.05;
    }
    
    COLOR = vec4(final_color, 1.0);
}