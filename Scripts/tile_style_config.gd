extends RefCounted
class_name TileStyleConfig

# Style types
enum Style {
	GRASSLAND,
	FOREST,
	CAVE,
	DISCO
}

# Tile types
enum TileType {
	GROUND,
	WALL,
	PLATFORM,
	ENDGOAL,
	SUBSURFACE
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
		Style.GRASSLAND:
			color_palettes[Style.GRASSLAND] = BiomeStylePalettes.generate_grassland_palette(rng)
		Style.FOREST:
			color_palettes[Style.FOREST] = BiomeStylePalettes.generate_forest_palette(rng)
		Style.CAVE:
			color_palettes[Style.CAVE] = BiomeStylePalettes.generate_cave_palette(rng)
		Style.DISCO:
			color_palettes[Style.DISCO] = BiomeStylePalettes.generate_disco_palette(rng)

func get_style_name() -> String:
	match current_style:
		Style.GRASSLAND:
			return "Grassland"
		Style.FOREST:
			return "Forest"
		Style.CAVE:
			return "Cave"
		Style.DISCO:
			return "Disco"
		_:
			return "Unknown"

func get_shader_path() -> String:
	match current_style:
		Style.GRASSLAND:
			return "res://Shaders/grassland_tile.gdshader"
		Style.FOREST:
			return "res://Shaders/forest_tile.gdshader"
		Style.CAVE:
			return "res://Shaders/cave_tile.gdshader"
		Style.DISCO:
			return "res://Shaders/disco_tile.gdshader"
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
