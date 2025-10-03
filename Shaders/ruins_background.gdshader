shader_type canvas_item;

uniform float seed : hint_range(0.0, 1000.0) = 0.0;
uniform vec4 stone_light : source_color;
uniform vec4 stone_medium : source_color;
uniform vec4 stone_dark : source_color;
uniform vec4 moss_stone : source_color;
uniform vec4 accent_copper : source_color;

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
    
    // Overcast sky
    float sky_gradient = smoothstep(0.5, 0.0, uv.y);
    vec3 color = mix(stone_light.rgb * 1.3, stone_medium.rgb * 1.1, sky_gradient);
    
    // Add distant crumbling walls
    for (float i = 0.0; i < 6.0; i += 1.0) {
        float wall_x = 0.15 + i * 0.15 + hash(vec2(i + seed, 0.0)) * 0.1;
        float wall_height = 0.4 + hash(vec2(i, 1.0 + seed)) * 0.3;
        float wall_width = 0.08 + hash(vec2(i, 2.0 + seed)) * 0.04;
        
        // Wall structure
        if (abs(uv.x - wall_x) < wall_width && uv.y > (1.0 - wall_height)) {
            float depth = 0.6 + hash(vec2(i, 3.0)) * 0.3;
            vec3 wall_color = stone_medium.rgb * depth;
            
            // Add weathering
            float weathering = noise(vec2(uv.x * 20.0, uv.y * 15.0));
            wall_color = mix(wall_color, stone_dark.rgb * 0.8, weathering * 0.3);
            
            // Add moss patches
            float moss = noise(vec2(uv.x * 15.0 + i, uv.y * 10.0));
            if (moss > 0.7) {
                wall_color = mix(wall_color, moss_stone.rgb, 0.4);
            }
            
            float fade = 1.0 - smoothstep(wall_width * 0.7, wall_width, abs(uv.x - wall_x));
            color = mix(color, wall_color, fade);
        }
    }
    
    // Add ancient pillars
    for (float i = 0.0; i < 4.0; i += 1.0) {
        float pillar_x = 0.2 + i * 0.25 + hash(vec2(i * 10.0 + seed, 5.0)) * 0.05;
        float pillar_width = 0.02 + hash(vec2(i, 6.0 + seed)) * 0.01;
        
        if (abs(uv.x - pillar_x) < pillar_width && uv.y > 0.3) {
            float depth = 0.5 + hash(vec2(i, 7.0)) * 0.4;
            vec3 pillar_color = stone_light.rgb * depth;
            
            // Horizontal bands (ancient carved patterns)
            float band = sin(uv.y * 40.0 + i * 3.0) * 0.5 + 0.5;
            pillar_color = mix(pillar_color, stone_dark.rgb * 0.9, band * 0.2);
            
            float fade = 1.0 - smoothstep(pillar_width * 0.6, pillar_width, abs(uv.x - pillar_x));
            color = mix(color, pillar_color, fade * 0.8);
        }
    }
    
    // Add broken arches
    vec2 arch_center = vec2(0.5, 0.4);
    float arch_radius = 0.3;
    float arch_thickness = 0.04;
    float dist_to_arch = abs(distance(uv, arch_center) - arch_radius);
    
    if (dist_to_arch < arch_thickness && uv.y < arch_center.y) {
        // Only show top half (arch)
        float arch_fade = smoothstep(arch_thickness, arch_thickness * 0.3, dist_to_arch);
        vec3 arch_color = stone_medium.rgb * 0.7;
        
        // Break the arch (make it crumbled)
        float break_noise = noise(vec2(atan(uv.y - arch_center.y, uv.x - arch_center.x) * 5.0, 0.0));
        if (break_noise > 0.6) {
            color = mix(color, arch_color, arch_fade * 0.6);
        }
    }
    
    // Add subtle copper/jade accent hints (ancient decorations)
    float accent_noise = noise(uv * 30.0 + vec2(seed * 0.2, 0.0));
    if (accent_noise > 0.85 && uv.y > 0.5) {
        float accent_type = hash(floor(uv * 30.0));
        vec3 accent_color = accent_type > 0.5 ? accent_copper.rgb : moss_stone.rgb;
        color = mix(color, accent_color, 0.3);
    }
    
    COLOR = vec4(color, 1.0);
}
