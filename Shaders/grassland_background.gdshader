shader_type canvas_item;

uniform float seed : hint_range(0.0, 1000.0) = 0.0;
uniform vec4 grass_light : source_color;
uniform vec4 grass_medium : source_color;
uniform vec4 grass_dark : source_color;
uniform vec4 sky_hint : source_color;
uniform int sky_style : hint_range(0, 2) = 0; // 0=regular, 1=sunset/dawn, 2=blue gradient

// Simple hash function
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
    
    // Sky gradient (top to middle)
    vec3 sky;
    
    if (sky_style == 1) {
        // Sunset/Dawn: Pink/Orange vertical gradient
        vec3 top_color = vec3(1.0, 0.4, 0.6);    // Pink
        vec3 mid_color = vec3(1.0, 0.6, 0.3);    // Orange
        vec3 bottom_color = vec3(1.0, 0.8, 0.5); // Light orange/yellow
        
        // Vertical gradient from top to bottom
        if (uv.y < 0.4) {
            sky = mix(top_color, mid_color, uv.y / 0.4);
        } else {
            sky = mix(mid_color, bottom_color, (uv.y - 0.4) / 0.6);
        }
    } else if (sky_style == 2) {
        // Blue sky with darker horizon
        vec3 top_color = vec3(0.4, 0.7, 1.0);     // Bright blue
        vec3 bottom_color = vec3(0.3, 0.5, 0.8);  // Darker blue
        
        // Gradient darker near horizon (bottom)
        sky = mix(top_color, bottom_color, smoothstep(0.0, 0.6, uv.y));
    } else {
        // Regular sky using sky_hint
        float sky_gradient = smoothstep(0.6, 0.0, uv.y);
        sky = mix(sky_hint.rgb * 0.7, sky_hint.rgb * 1.2, sky_gradient);
    }
    
    // Add simple clouds
    float cloud_noise = noise(uv * 3.0 + vec2(seed * 0.1, 0.0));
    cloud_noise = smoothstep(0.4, 0.7, cloud_noise);
    sky = mix(sky, vec3(1.0, 1.0, 1.0) * 0.9, cloud_noise * 0.3);
    
    // Rolling hills - 3 layers
    float hill1_height = 0.65 + noise(vec2(uv.x * 2.0 + seed * 0.1, 0.0)) * 0.1;
    float hill2_height = 0.75 + noise(vec2(uv.x * 3.0 + seed * 0.2, 1.0)) * 0.08;
    float hill3_height = 0.85 + noise(vec2(uv.x * 4.0 + seed * 0.3, 2.0)) * 0.06;
    
    vec3 color = sky;
    
    // Distant hills (lightest)
    if (uv.y > hill1_height) {
        color = grass_light.rgb * 0.6;
    }
    
    // Middle hills
    if (uv.y > hill2_height) {
        color = grass_medium.rgb * 0.7;
    }
    
    // Near hills (darkest)
    if (uv.y > hill3_height) {
        color = grass_dark.rgb * 0.8;
    }
    
    // Add simple sun
    vec2 sun_pos = vec2(0.75, 0.15);
    float sun_dist = distance(uv, sun_pos);
    float sun = smoothstep(0.08, 0.05, sun_dist);
    color = mix(color, vec3(1.0, 0.95, 0.7), sun * 0.8);
    
    COLOR = vec4(color, 1.0);
}
