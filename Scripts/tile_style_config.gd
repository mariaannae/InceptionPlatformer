extends RefCounted
class_name TileStyleConfig

# Style types
enum Style {
	MINIMALIST,
	PIXEL_ART,
	SMOOTH_MODERN_ABSTRACT,
	GRASSLAND,
	FOREST,
	RUINS,
	CAVE,
	CRYSTAL_CAVE
}

# Tile types
enum TileType {
	GROUND,
	WALL,
	PLATFORM,
	ENDGOAL
}

# Current configuration
var current_style: Style
var current_seed: float
var color_palettes: Dictionary = {}

func _init(seed_value: float = -1.0):
	if seed_value < 0:
		randomize()
		current_seed = randf() * 1000.0
	else:
		current_seed = seed_value
	
	# Randomly select a style
	current_style = Style.values()[randi() % Style.size()]
	
	# Generate color palette for the selected style
	generate_color_palette()

func generate_color_palette() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = int(current_seed)
	
	match current_style:
		Style.MINIMALIST:
			_generate_minimalist_palette(rng)
		Style.PIXEL_ART:
			_generate_pixel_palette(rng)
		Style.SMOOTH_MODERN_ABSTRACT:
			_generate_smooth_palette(rng)
		Style.GRASSLAND:
			color_palettes[Style.GRASSLAND] = BiomeStylePalettes.generate_grassland_palette(rng)
		Style.FOREST:
			color_palettes[Style.FOREST] = BiomeStylePalettes.generate_forest_palette(rng)
		Style.RUINS:
			color_palettes[Style.RUINS] = BiomeStylePalettes.generate_ruins_palette(rng)
		Style.CAVE:
			color_palettes[Style.CAVE] = BiomeStylePalettes.generate_cave_palette(rng)
		Style.CRYSTAL_CAVE:
			color_palettes[Style.CRYSTAL_CAVE] = BiomeStylePalettes.generate_crystal_cave_palette(rng)

func _generate_minimalist_palette(rng: RandomNumberGenerator) -> void:
	# Generate harmonious two-color palette
	var hue = rng.randf()
	var saturation = rng.randf_range(0.3, 0.7)
	
	# Primary color (darker)
	var primary_value = rng.randf_range(0.2, 0.4)
	var primary_color = Color.from_hsv(hue, saturation, primary_value)
	
	# Secondary color (lighter)
	var secondary_value = rng.randf_range(0.7, 0.9)
	var secondary_saturation = saturation * 0.5
	var secondary_color = Color.from_hsv(hue, secondary_saturation, secondary_value)
	
	color_palettes[Style.MINIMALIST] = {
		"primary_color": primary_color,
		"secondary_color": secondary_color
	}

func _generate_pixel_palette(rng: RandomNumberGenerator) -> void:
	# Generate retro 3-color palette
	var hue = rng.randf()
	var saturation = rng.randf_range(0.5, 0.8)
	
	# Dark color
	var color1 = Color.from_hsv(hue, saturation * 1.2, 0.15)
	
	# Mid color
	var color2 = Color.from_hsv(hue, saturation, 0.45)
	
	# Light color
	var color3 = Color.from_hsv(hue, saturation * 0.6, 0.75)
	
	color_palettes[Style.PIXEL_ART] = {
		"color1": color1,
		"color2": color2,
		"color3": color3
	}

func _generate_smooth_palette(rng: RandomNumberGenerator) -> void:
	# Generate smooth gradient palette
	var hue = rng.randf()
	var saturation = rng.randf_range(0.4, 0.8)
	
	# Shadow color (darkest)
	var shadow_color = Color.from_hsv(hue, saturation * 1.1, 0.2)
	
	# Base color (middle)
	var base_color = Color.from_hsv(hue, saturation, 0.5)
	
	# Highlight color (lightest)
	var highlight_hue = fmod(hue + 0.05, 1.0)  # Slight hue shift
	var highlight_color = Color.from_hsv(highlight_hue, saturation * 0.7, 0.8)
	
	color_palettes[Style.SMOOTH_MODERN_ABSTRACT] = {
		"base_color": base_color,
		"highlight_color": highlight_color,
		"shadow_color": shadow_color
	}

func get_style_name() -> String:
	match current_style:
		Style.MINIMALIST:
			return "Minimalist"
		Style.PIXEL_ART:
			return "Pixel Art"
		Style.SMOOTH_MODERN_ABSTRACT:
			return "Smooth Modern"
		Style.GRASSLAND:
			return "Grassland"
		Style.FOREST:
			return "Forest"
		Style.RUINS:
			return "Ruins"
		Style.CAVE:
			return "Cave"
		Style.CRYSTAL_CAVE:
			return "Crystal Cave"
		_:
			return "Unknown"

func get_shader_path() -> String:
	match current_style:
		Style.MINIMALIST:
			return "res://Shaders/minimalist_tile.gdshader"
		Style.PIXEL_ART:
			return "res://Shaders/pixel_tile.gdshader"
		Style.SMOOTH_MODERN_ABSTRACT:
			return "res://Shaders/smooth_tile.gdshader"
		Style.GRASSLAND:
			return "res://Shaders/grassland_tile.gdshader"
		Style.FOREST:
			return "res://Shaders/forest_tile.gdshader"
		Style.RUINS:
			return "res://Shaders/ruins_tile.gdshader"
		Style.CAVE:
			return "res://Shaders/cave_tile.gdshader"
		Style.CRYSTAL_CAVE:
			return "res://Shaders/crystal_cave_tile.gdshader"
		_:
			return ""

func get_palette() -> Dictionary:
	return color_palettes.get(current_style, {})

func regenerate(new_seed: float = -1.0) -> void:
	if new_seed < 0:
		randomize()
		current_seed = randf() * 1000.0
	else:
		current_seed = new_seed
	
	# Randomly select new style
	current_style = Style.values()[randi() % Style.size()]
	
	# Generate new palette
	generate_color_palette()
