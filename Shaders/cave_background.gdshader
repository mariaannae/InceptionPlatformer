shader_type canvas_item;

uniform float seed : hint_range(0.0, 1000.0) = 0.0;
uniform vec4 rock_darkest : source_color;
uniform vec4 rock_dark : source_color;
uniform vec4 rock_medium : source_color;
uniform vec4 mineral_blue : source_color;
uniform vec4 mineral_purple : source_color;
uniform vec4 wet_highlight : source_color;

// Hash function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

// Smooth noise
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
    vec2 uv = UV;
    
    // Deep cave darkness with depth fade (darker towards back)
    float depth_fade = 1.0 - uv.y * 0.3;
    vec3 color = rock_darkest.rgb * depth_fade;
    
    // Add rock formation layers
    float rock_noise = noise(uv * 4.0 + vec2(seed * 0.1, 0.0));
    color = mix(color, rock_dark.rgb * 0.8, rock_noise * 0.3);
    
    // Stalactites from ceiling (top)
    for (float i = 0.0; i < 10.0; i += 1.0) {
        float stalactite_x = hash(vec2(i + seed * 0.01, 0.0));
        float stalactite_length = 0.1 + hash(vec2(i, 1.0 + seed)) * 0.15;
        float stalactite_width = 0.015 + hash(vec2(i, 2.0)) * 0.01;
        
        // Only render if in top portion
        if (uv.y < stalactite_length) {
            float dist_x = abs(uv.x - stalactite_x);
            // Taper towards the point
            float taper = (1.0 - (uv.y / stalactite_length)) * stalactite_width;
            
            if (dist_x < taper) {
                float depth = 0.5 + hash(vec2(i, 3.0)) * 0.3;
                vec3 stalactite_color = rock_medium.rgb * depth;
                
                // Add wet highlights
                float wet = noise(vec2(uv.x * 20.0, uv.y * 15.0 + i));
                if (wet > 0.7) {
                    stalactite_color = mix(stalactite_color, wet_highlight.rgb, 0.3);
                }
                
                float fade = 1.0 - (dist_x / taper);
                color = mix(color, stalactite_color, fade * 0.7);
            }
        }
    }
    
    // Stalagmites from floor (bottom)
    for (float i = 0.0; i < 8.0; i += 1.0) {
        float stalagmite_x = hash(vec2(i * 10.0 + seed * 0.02, 5.0));
        float stalagmite_length = 0.12 + hash(vec2(i, 6.0 + seed)) * 0.18;
        float stalagmite_width = 0.02 + hash(vec2(i, 7.0)) * 0.015;
        
        // Only render if in bottom portion
        if (uv.y > (1.0 - stalagmite_length)) {
            float dist_x = abs(uv.x - stalagmite_x);
            // Taper towards the point (from bottom up)
            float height_from_bottom = 1.0 - uv.y;
            float taper = (1.0 - (height_from_bottom / stalagmite_length)) * stalagmite_width;
            
            if (dist_x < taper) {
                float depth = 0.4 + hash(vec2(i, 8.0)) * 0.4;
                vec3 stalagmite_color = rock_medium.rgb * depth;
                
                float fade = 1.0 - (dist_x / taper);
                color = mix(color, stalagmite_color, fade * 0.8);
            }
        }
    }
    
    // Add crystal glints (rare mineral deposits)
    float crystal_noise = noise(uv * 25.0 + vec2(seed * 0.3, 0.0));
    if (crystal_noise > 0.88) {
        float crystal_type = hash(floor(uv * 25.0));
        vec3 crystal_color = crystal_type > 0.5 ? mineral_blue.rgb : mineral_purple.rgb;
        
        // Pulsing glow
        float pulse = sin(seed * 0.5 + uv.x * 10.0 + uv.y * 10.0) * 0.5 + 0.5;
        color = mix(color, crystal_color, 0.4 * pulse);
    }
    
    // Add very subtle water reflections on floor
    if (uv.y > 0.85) {
        float water_shimmer = noise(vec2(uv.x * 30.0 + seed * 0.2, uv.y * 10.0));
        water_shimmer = smoothstep(0.5, 0.8, water_shimmer);
        color = mix(color, wet_highlight.rgb, water_shimmer * 0.15);
    }
    
    // Add ambient blue glow (bioluminescence hint)
    float ambient_glow = noise(uv * 8.0 + vec2(0.0, seed * 0.15));
    if (ambient_glow > 0.7) {
        color = mix(color, mineral_blue.rgb * 0.3, 0.1);
    }
    
    COLOR = vec4(color, 1.0);
}
