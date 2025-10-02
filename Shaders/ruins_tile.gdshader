shader_type canvas_item;

// Ruins biome colors
uniform vec3 stone_light : source_color = vec3(0.65, 0.65, 0.6);
uniform vec3 stone_medium : source_color = vec3(0.45, 0.45, 0.4);
uniform vec3 stone_dark : source_color = vec3(0.25, 0.25, 0.2);
uniform vec3 moss_stone : source_color = vec3(0.35, 0.4, 0.3);
uniform vec3 accent_copper : source_color = vec3(0.7, 0.45, 0.3);
uniform vec3 accent_jade : source_color = vec3(0.3, 0.5, 0.4);
uniform float seed : hint_range(0.0, 1000.0) = 1.0;
uniform int tile_type : hint_range(0, 3) = 0;

// Simple Bayer 2x2 matrix for dithering
float bayer2(vec2 p) {
    int x = int(mod(p.x, 2.0));
    int y = int(mod(p.y, 2.0));
    return (float(x) + float(y) * 2.0) / 4.0;
}

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

// Quantized fbm for pixel art
float quant_fbm(vec2 p, float scale, int levels) {
    float value = 0.0;
    float amplitude = 0.5;
    for(int i = 0; i < 3; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    // Quantize to discrete levels
    return floor(value * float(levels)) / float(levels);
}

// Generate brick/stone block pattern with hard mortar lines
float stone_blocks(vec2 p) {
    vec2 block = floor(p);
    float offset = mod(block.y, 2.0) * 0.5;
    block.x += offset;
    vec2 f = fract(p);
    f.x = fract(p.x + offset);

    // Use step for hard mortar lines (pixelated)
    float mortar = 1.0;
    mortar *= step(0.07, f.x) * step(f.x, 0.93);
    mortar *= step(0.10, f.y) * step(f.y, 0.90);
    return mortar;
}

void fragment() {
    vec2 uv = UV;
    vec2 pos = uv * 32.0;

    // Snap overlays to a 4x4 grid for pixelation
    vec2 snapped = floor(pos / 4.0) * 4.0;

    vec3 final_color;

    if (tile_type == 3) { // ENDGOAL
        float goal_gradient = smoothstep(0.0, 1.0, uv.y);
        final_color = mix(vec3(0.0, 0.8, 0.2), vec3(0.0, 0.6, 0.0), goal_gradient);
        float pulse = sin(seed * 0.1) * 0.1 + 0.9;
        final_color *= pulse;
    }
    else if (tile_type == 0) { // Ground tile (ancient stone floor)
        // Create worn stone tile pattern
        float blocks = stone_blocks(pos * 0.25);
        float wear = quant_fbm(snapped * 0.1, 0.1, 4);
        float cracks = step(0.75, quant_fbm(snapped * 0.3, 0.3, 3));

        vec3 tile_color = mix(stone_dark, stone_medium, blocks);
        tile_color = mix(tile_color, stone_light, wear * 0.3);

        // Add cracks (quantized)
        tile_color = mix(tile_color, stone_dark * 0.5, cracks * 0.4);

        // Add moss in crevices (quantized)
        float moss_growth = step(0.7, quant_fbm(snapped * 0.15, 0.15, 3));
        if (blocks < 0.3 || cracks > 0.5) {
            tile_color = mix(tile_color, moss_stone, moss_growth * 0.4);
        }

        // Ancient inscriptions/decorations (rare, snapped)
        if (noise(floor(snapped * 0.125)) > 0.9) {
            float inscription = sin(snapped.x * 0.5) * sin(snapped.y * 0.5);
            if (inscription > 0.7) {
                tile_color = mix(tile_color, accent_jade * 0.7, 0.3);
            }
        }

        final_color = tile_color;
    }
    else if (tile_type == 1) { // Wall tile (ancient stone wall)
        // Create stone brick wall with damage
        float blocks = stone_blocks(pos * vec2(0.2, 0.3));
        float damage = step(0.7, quant_fbm(snapped * 0.08, 0.08, 2));
        float weathering = quant_fbm(snapped * 0.15, 0.15, 3);

        vec3 wall_color = mix(stone_dark, stone_medium, blocks);

        // Add weathering and damage (quantized)
        if (damage > 0.5) {
            wall_color *= 0.7; // Damaged areas are darker
            wall_color = mix(wall_color, stone_dark, 0.5);
        }

        wall_color = mix(wall_color, stone_light * 0.9, weathering * 0.2);

        // Moss and vines on old walls (quantized)
        float moss = step(0.6, quant_fbm(snapped * 0.1 + vec2(0.0, snapped.y * 0.1), 0.1, 2));
        if (moss > 0.5 || uv.y < 0.15) {
            wall_color = mix(wall_color, moss_stone, 0.35);
        }

        // Occasional copper/metal accents (ancient fixtures, snapped)
        if (hash(floor(snapped * 0.0625)) > 0.95) {
            float metal_pattern = step(0.5, sin(snapped.x * 2.0) * sin(snapped.y * 2.0));
            wall_color = mix(wall_color, accent_copper * 0.8, metal_pattern * 0.4);
        }

        final_color = wall_color;
    }
    else { // Platform tile (ancient stone platform)
        // Ornate ancient platform
        float center_dist = length(uv - vec2(0.5, 0.5));
        float ornate = sin(center_dist * 20.0) * 0.5 + 0.5;
        float blocks = stone_blocks(pos * 0.3);

        vec3 platform_color = mix(stone_medium, stone_light, blocks);

        // Add ornamental patterns (quantized)
        if (ornate > 0.7) {
            platform_color = mix(platform_color, accent_jade * 0.9, 0.2);
        }

        // Edge wear (quantized)
        float edge_wear = 0.0;
        if (uv.x < 0.1 || uv.x > 0.9 || uv.y < 0.1 || uv.y > 0.9) {
            edge_wear = quant_fbm(snapped * 0.2, 0.2, 2);
            platform_color = mix(platform_color, stone_dark, edge_wear * 0.3);
        }

        // Some moss on edges (quantized)
        float moss = step(0.6, quant_fbm(snapped * 0.15, 0.15, 2));
        if ((uv.y < 0.15 || edge_wear > 0.5) && moss > 0.5) {
            platform_color = mix(platform_color, moss_stone, 0.3);
        }

        final_color = platform_color;
    }

    // Ancient ambiance - slightly desaturated
    final_color = mix(final_color, vec3(dot(final_color, vec3(0.299, 0.587, 0.114))), 0.15);

    // Dithering for color transitions (optional, subtle)
    float dither = bayer2(pos);
    final_color += (dither - 0.25) * 0.04;

    // Dust particles effect (quantized)
    float dust = quant_fbm(snapped * 0.05 + vec2(seed * 0.01), 0.05, 2);
    final_color += vec3(dust * 0.05);

    COLOR = vec4(final_color, 1.0);
}
