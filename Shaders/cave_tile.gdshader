shader_type canvas_item;

// Cave biome colors
uniform vec3 rock_darkest : source_color = vec3(0.1, 0.1, 0.15);
uniform vec3 rock_dark : source_color = vec3(0.15, 0.15, 0.2);
uniform vec3 rock_medium : source_color = vec3(0.25, 0.25, 0.3);
uniform vec3 mineral_blue : source_color = vec3(0.3, 0.4, 0.6);
uniform vec3 mineral_purple : source_color = vec3(0.4, 0.3, 0.5);
uniform vec3 wet_highlight : source_color = vec3(0.35, 0.35, 0.4);
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

// Voronoi for crystal/mineral formation
vec2 voronoi(vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    
    float min_dist = 1.0;
    vec2 min_point;
    
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 point = hash(n + neighbor) * vec2(1.0) + neighbor;
            float dist = length(point - f);
            
            if(dist < min_dist) {
                min_dist = dist;
                min_point = n + neighbor;
            }
        }
    }
    
    return vec2(min_dist, hash(min_point));
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
    else if (tile_type == 0) { // Ground tile (cave floor)
        // Rocky, uneven cave floor
        float rock_noise = fbm(pos * 0.15, 4);
        float sediment = fbm(pos * 0.08, 2);
        float pebbles = step(0.8, noise(pos * 0.3));
        
        vec3 floor_color = mix(rock_darkest, rock_dark, rock_noise);
        floor_color = mix(floor_color, rock_medium, sediment * 0.3);
        
        // Add scattered pebbles
        floor_color = mix(floor_color, rock_medium * 1.2, pebbles * 0.2);
        
        // Wet areas (puddles)
        float wetness = smoothstep(0.6, 0.8, noise(pos * 0.05));
        if (wetness > 0.0) {
            floor_color = mix(floor_color, wet_highlight, wetness * 0.3);
            // Add reflection
            float reflection = sin(pos.x * 0.5) * sin(pos.y * 0.5) * 0.1;
            floor_color += vec3(reflection * wetness);
        }
        
        // Occasional mineral deposits
        vec2 vor = voronoi(pos * 0.1);
        if (vor.x < 0.1 && vor.y > 0.8) {
            floor_color = mix(floor_color, mineral_blue * 0.7, 0.4);
        }
        
        final_color = floor_color;
    }
    else if (tile_type == 1) { // Wall tile (cave wall)
        // Rough cave wall with layers
        float layers = sin(pos.y * 0.3 + fbm(pos * 0.1, 2) * 3.0) * 0.5 + 0.5;
        float roughness = fbm(pos * 0.2, 3);
        float crevices = step(0.7, fbm(pos * 0.25, 2));
        
        vec3 wall_color = mix(rock_darkest, rock_dark, layers);
        wall_color = mix(wall_color, rock_medium, roughness * 0.4);
        
        // Deep crevices
        wall_color = mix(wall_color, rock_darkest * 0.5, crevices * 0.5);
        
        // Mineral veins
        float veins = step(0.85, noise(pos * vec2(0.05, 0.5)));
        if (veins > 0.0) {
            float vein_type = hash(floor(pos * 0.1));
            if (vein_type > 0.5) {
                wall_color = mix(wall_color, mineral_blue, 0.5);
            } else {
                wall_color = mix(wall_color, mineral_purple, 0.5);
            }
        }
        
        // Dripping water stains
        float drips = smoothstep(0.7, 0.9, noise(vec2(pos.x * 0.2, pos.y * 0.05)));
        if (drips > 0.0 && uv.y > 0.3) {
            wall_color = mix(wall_color, wet_highlight * 0.8, drips * 0.2);
        }
        
        final_color = wall_color;
    }
    else { // Platform tile (rock formation/ledge)
        // Natural rock ledge
        float stratification = sin(pos.x * 0.2) * 0.5 + 0.5;
        float surface = fbm(pos * 0.18, 3);
        
        vec3 ledge_color = mix(rock_dark, rock_medium, stratification);
        ledge_color = mix(ledge_color, rock_medium * 1.1, surface * 0.3);
        
        // Worn smooth top surface
        if (uv.y < 0.2) {
            ledge_color = mix(ledge_color, rock_medium * 1.2, 0.3);
            // Wet surface
            float wet = noise(pos * 0.1);
            if (wet > 0.6) {
                ledge_color = mix(ledge_color, wet_highlight, 0.25);
            }
        }
        
        // Crystal growth on underside
        if (uv.y > 0.7) {
            float crystals = step(0.8, noise(pos * 0.2));
            if (crystals > 0.0) {
                ledge_color = mix(ledge_color, mineral_purple * 0.8, 0.4);
            }
        }
        
        final_color = ledge_color;
    }
    
    // Cave atmosphere - very dark ambiance
    float depth = pow(1.0 - uv.y, 0.5);
    final_color *= (0.6 + depth * 0.4);
    
    // Subtle bioluminescence
    float bio = noise(pos * 0.03 + vec2(seed * 0.01));
    if (bio > 0.85) {
        final_color += mineral_blue * 0.1;
    }
    
    COLOR = vec4(final_color, 1.0);
}