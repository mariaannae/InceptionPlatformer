shader_type canvas_item;

// ===== Palette =====
uniform vec4 color_a : source_color = vec4(0.00, 0.02, 0.06, 1.0); // deep blue-black
uniform vec4 color_b : source_color = vec4(0.02, 0.10, 0.18, 1.0); // cool teal base
uniform vec3 grid_color = vec3(0.20, 0.95, 1.00);                  // neon cyan
uniform vec3 glow_color = vec3(1.00, 0.20, 0.50);                  // magenta accent

// ===== Grid / Motion =====
uniform float grid_scale : hint_range(10.0, 200.0) = 80.0;   // density of the tech grid
uniform float grid_thickness : hint_range(0.001, 0.06) = 0.018;
uniform float grid_glow : hint_range(0.0, 3.0) = 1.35;
uniform float drift_x = 0.05;     // slow drift of the grid
uniform float drift_y = 0.02;
uniform float neon_speed = 1.6;   // pulsing along the grid

// ===== Fog / Noise =====
uniform float fog_amount : hint_range(0.0, 1.0) = 0.22;
uniform float fog_scale : hint_range(0.5, 8.0) = 3.0;
uniform float fog_speed = 0.12;

// ===== Scanlines =====
uniform float scan_strength : hint_range(0.0, 0.25) = 0.08;
uniform float scan_density : hint_range(50.0, 2000.0) = 900.0;

// ===== Glitch / Chromatic Aberration =====
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.55;
uniform float glitch_speed : hint_range(0.0, 5.0) = 2.2;
uniform float slice_freq : hint_range(10.0, 400.0) = 140.0;
uniform float jitter_amount : hint_range(0.0, 0.5) = 0.10;
uniform float chroma_px : hint_range(0.0, 6.0) = 2.0;

// ===== Vignette =====
uniform float vignette : hint_range(0.0, 1.0) = 0.45;

// ---- Helpers ----
float hash21(vec2 p){
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.45);
    return fract(p.x * p.y);
}
float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
float fbm(vec2 p){
    float v = 0.0;
    float a = 0.5;
    for (int i=0; i<5; i++){
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// Tech grid (animated)
float tech_grid(vec2 uv, out float pulse){
    // scale & drift
    vec2 g = uv * grid_scale + vec2(TIME * drift_x, TIME * drift_y);

    // crisp cell lines
    float gx = 1.0 - smoothstep(0.0, grid_thickness, abs(fract(g.x) - 0.5));
    float gy = 1.0 - smoothstep(0.0, grid_thickness, abs(fract(g.y) - 0.5));
    float lines = max(gx, gy);

    // pulsing intensity per cell
    float cell = floor(g.x) + floor(g.y);
    pulse = 0.5 + 0.5 * sin(cell * 1.7 + TIME * 6.28318 * neon_speed);

    return lines;
}

// Core look at a given UV (so we can chroma-shift)
vec3 look(vec2 uv){
    float t = TIME;

    // Gradient base with drifting fog
    float f = fbm(uv * fog_scale + vec2(t * fog_speed, -t * 0.6 * fog_speed));
    vec3 base = mix(color_a.rgb, color_b.rgb, clamp(f * 0.85 + 0.15, 0.0, 1.0));

    // Tech grid + neon glow
    float pulse;
    float grid = tech_grid(uv, pulse);
    vec3 grid_neon = (grid_color * (0.7 + 0.3 * pulse) + glow_color * 0.35 * pulse) * grid_glow * grid;

    // Scanlines
    float scan = sin(uv.y * scan_density + t * 10.0) * scan_strength;

    // Fog overlay
    vec3 fog = (color_a.rgb * 0.35 + color_b.rgb * 0.65) * fog_amount * (0.5 + 0.5 * f);

    return base + grid_neon + vec3(scan) + fog;
}

void fragment(){
    vec2 suv = SCREEN_UV;
    float t = TIME;

    // Glitch slicing by rows
    float row = floor(suv.y * slice_freq);
    float gate = step(0.6, fract(sin((row + floor(t * glitch_speed)) * 12.9898) * 78.233));
    float slice_offset = (hash21(vec2(row, floor(t * glitch_speed))) - 0.5) * 2.0;
    float jump = gate * slice_offset * jitter_amount * glitch_intensity;

    // Total x-offset for the effect
    float xoff = (sin(suv.y * 50.0 + t * 5.0) * 0.003 + jump);

    // Chromatic aberration offsets in UV units
    vec2 px = SCREEN_PIXEL_SIZE * chroma_px;

    // Sample the "scene" we generate at three slightly different UVs
    vec3 col_r = look(suv + vec2(xoff, 0.0) + vec2(px.x, 0.0));
    vec3 col_g = look(suv + vec2(xoff * 0.5, 0.0));
    vec3 col_b = look(suv - vec2(xoff, 0.0) - vec2(px.x, 0.0));

    vec3 col = vec3(col_r.r, col_g.g, col_b.b);

    // Vignette for focus
    vec2 v = suv - 0.5;
    float vig = 1.0 - dot(v, v) * 2.2;
    vig = clamp(mix(1.0, vig, vignette), 0.0, 1.0);

    COLOR = vec4(col * vig, 1.0);
}
