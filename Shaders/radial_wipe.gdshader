shader_type canvas_item;

// Screen texture uniform (required in Godot 4)
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Wipe progress: 0.0 = fully visible, 1.0 = fully wiped
uniform float wipe_progress : hint_range(0.0, 1.0) = 0.0;

// Center point of the wipe (normalized coordinates)
uniform vec2 wipe_center = vec2(0.5, 0.5);

// Color to wipe to (default black for dream theme)
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Feather/softness of the wipe edge
uniform float edge_softness : hint_range(0.0, 0.3) = 0.1;

void fragment() {
	// Sample the screen behind this overlay
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	
	// Calculate distance from center point
	vec2 aspect_ratio = vec2(1.0, SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x);
	vec2 centered_uv = (SCREEN_UV - wipe_center) * aspect_ratio;
	float distance_from_center = length(centered_uv);
	
	// Maximum possible distance (corner to corner)
	float max_distance = length(aspect_ratio * 0.5);
	
	// Normalize distance
	float normalized_distance = distance_from_center / max_distance;
	
	// Calculate wipe threshold with smoothstep for soft edge
	float wipe_threshold = wipe_progress * 1.2; // Extend slightly beyond 1.0 for full coverage
	float edge_start = wipe_threshold - edge_softness;
	float edge_end = wipe_threshold;
	
	// Create smooth transition
	float wipe_amount = smoothstep(edge_start, edge_end, normalized_distance);
	
	// Invert so center wipes first (circle collapses inward)
	wipe_amount = 1.0 - wipe_amount;
	
	// Mix between screen color and wipe color
	COLOR = mix(screen_color, wipe_color, wipe_amount);
}
