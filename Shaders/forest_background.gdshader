shader_type canvas_item;

uniform float seed : hint_range(0.0, 1000.0) = 0.0;
uniform vec4 canopy_light : source_color;
uniform vec4 canopy_medium : source_color;
uniform vec4 canopy_dark : source_color;
uniform vec4 bark_light : source_color;
uniform vec4 bark_dark : source_color;

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
    
    // Start with dark canopy base
    vec3 color = canopy_dark.rgb * 0.5;
    
    // Add dappled light effect (patches of light through canopy)
    float light_patches = noise(uv * 5.0 + vec2(seed * 0.1, 0.0));
    light_patches = smoothstep(0.3, 0.8, light_patches);
    color = mix(color, canopy_medium.rgb * 0.7, light_patches * 0.4);
    
    // Add distant tree trunk silhouettes
    for (float i = 0.0; i < 8.0; i += 1.0) {
        float tree_x = hash(vec2(i + seed * 0.01, 0.0));
        float tree_width = 0.015 + hash(vec2(i + seed * 0.02, 1.0)) * 0.01;
        
        // Calculate distance from tree center
        float dist_to_tree = abs(uv.x - tree_x);
        
        // Tree trunk (dark vertical shape)
        if (dist_to_tree < tree_width) {
            float fade = 1.0 - (dist_to_tree / tree_width);
            float depth_fade = 0.3 + hash(vec2(i, 2.0)) * 0.4; // Trees at different depths
            color = mix(color, bark_dark.rgb * depth_fade, fade * 0.6);
        }
    }
    
    // Add horizontal fog/mist layers
    float mist_y1 = 0.3 + sin(seed * 0.1) * 0.1;
    float mist_y2 = 0.6 + cos(seed * 0.15) * 0.1;
    
    float mist1 = smoothstep(0.1, 0.0, abs(uv.y - mist_y1)) * 0.2;
    float mist2 = smoothstep(0.15, 0.0, abs(uv.y - mist_y2)) * 0.15;
    
    color = mix(color, canopy_light.rgb * 0.8, mist1 + mist2);
    
    // Add subtle light rays from top
    if (uv.y < 0.3) {
        float rays = noise(vec2(uv.x * 15.0 + seed * 0.05, uv.y * 2.0));
        rays = smoothstep(0.5, 0.7, rays);
        color = mix(color, canopy_light.rgb, rays * 0.2 * (1.0 - uv.y / 0.3));
    }
    
    COLOR = vec4(color, 1.0);
}
