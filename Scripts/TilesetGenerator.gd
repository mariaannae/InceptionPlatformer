extends TileMap
class_name TilesetGenerator

# Preload the style config
const TileStyleConfig = preload("res://Scripts/TileStyleConfig.gd")

# Configuration
@export var tile_size: int = 32
@export var initial_seed: float = -1.0
@export var auto_generate: bool = true

# Scene size configuration (number of tiles)
@export var scene_width_tiles: int = 66
@export var scene_height_tiles: int = 24

# Internal state
var style_config
var generated_tileset: TileSet
var tile_cache: Dictionary = {}

func _ready():
	if auto_generate:
		await generate_tileset()

func _input(event):
	# Press 'R' to regenerate tileset with new random style and seed
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		print("\n>>> Regenerating tileset with new random style <<<")
		await regenerate_tileset()
		print(">>> Press 'R' again to regenerate <<<\n")

func generate_tileset(seed_value: float = -1.0) -> void:
	print("=== Starting Tileset Generation ===")
	
	# Create style configuration
	style_config = TileStyleConfig.new(seed_value if seed_value >= 0 else initial_seed)
	print("Selected Style: ", style_config.get_style_name())
	print("Seed: ", style_config.current_seed)
	
	# Create new tileset
	generated_tileset = TileSet.new()
	generated_tileset.tile_size = Vector2i(tile_size, tile_size)
	
	# Generate tiles for each type
	await _generate_tile_type(TileStyleConfig.TileType.GROUND, 0)
	await _generate_tile_type(TileStyleConfig.TileType.WALL, 1)
	await _generate_tile_type(TileStyleConfig.TileType.PLATFORM, 2)
	
	# Assign tileset to this TileMap
	tile_set = generated_tileset
	
	print("=== Tileset Generation Complete ===")
	print("Total tiles created: ", generated_tileset.get_source_count())
	
	# Paint test level
	paint_test_level()

func _generate_tile_type(tile_type: int, source_id: int) -> void:
	# Create tile source
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = await _create_tile_texture(tile_type)
	atlas_source.texture_region_size = Vector2i(tile_size, tile_size)
	
	# Add source to tileset
	generated_tileset.add_source(atlas_source, source_id)
	
	# Create tile at position (0, 0) in the atlas
	var tile_coords = Vector2i(0, 0)
	atlas_source.create_tile(tile_coords)
	
	# Set up collision based on tile type
	_setup_tile_collision(atlas_source, tile_coords, tile_type)
	
	print("Created tile type: ", _get_tile_type_name(tile_type))

func _create_tile_texture(tile_type: int) -> ImageTexture:
	# Check cache first
	var cache_key = "%s_%d_%f" % [style_config.get_style_name(), tile_type, style_config.current_seed]
	if tile_cache.has(cache_key):
		return tile_cache[cache_key]
	
	# Create a SubViewport to render the shader
	var viewport = SubViewport.new()
	viewport.size = Vector2i(tile_size, tile_size)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.transparent_bg = false
	
	# Create a ColorRect to apply the shader
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(tile_size, tile_size)
	
	# Create and configure shader material
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load(style_config.get_shader_path())
	
	# Set shader parameters
	_configure_shader_material(shader_material, tile_type)
	
	color_rect.material = shader_material
	
	# Add to scene tree temporarily
	viewport.add_child(color_rect)
	add_child(viewport)
	
	# Wait for rendering
	await RenderingServer.frame_post_draw
	
	# Get the rendered texture
	var viewport_texture = viewport.get_texture()
	var image = viewport_texture.get_image()
	
	# Create ImageTexture
	var texture = ImageTexture.create_from_image(image)
	
	# Clean up
	viewport.remove_child(color_rect)
	remove_child(viewport)
	color_rect.queue_free()
	viewport.queue_free()
	
	# Cache the texture
	tile_cache[cache_key] = texture
	
	return texture

func _configure_shader_material(material: ShaderMaterial, tile_type: int) -> void:
	var palette = style_config.get_palette()
	
	# Set common parameters
	material.set_shader_parameter("seed", style_config.current_seed)
	material.set_shader_parameter("tile_type", tile_type)
	
	# Set style-specific color parameters
	match style_config.current_style:
		TileStyleConfig.Style.MINIMALIST:
			material.set_shader_parameter("primary_color", palette.get("primary_color", Color.BLUE))
			material.set_shader_parameter("secondary_color", palette.get("secondary_color", Color.WHITE))
		
		TileStyleConfig.Style.PIXEL_ART:
			material.set_shader_parameter("color1", palette.get("color1", Color.BLACK))
			material.set_shader_parameter("color2", palette.get("color2", Color.GRAY))
			material.set_shader_parameter("color3", palette.get("color3", Color.WHITE))
		
		TileStyleConfig.Style.SMOOTH_MODERN:
			material.set_shader_parameter("base_color", palette.get("base_color", Color.PURPLE))
			material.set_shader_parameter("highlight_color", palette.get("highlight_color", Color.PINK))
			material.set_shader_parameter("shadow_color", palette.get("shadow_color", Color.DARK_VIOLET))

func _setup_tile_collision(atlas_source: TileSetAtlasSource, tile_coords: Vector2i, tile_type: int) -> void:
	# Create physics layer if it doesn't exist
	if generated_tileset.get_physics_layers_count() == 0:
		generated_tileset.add_physics_layer()
	
	# Get tile data
	var tile_data = atlas_source.get_tile_data(tile_coords, 0)
	
	# Create collision polygon based on tile type
	match tile_type:
		TileStyleConfig.TileType.GROUND:
			# Full collision on all sides
			var polygon = PackedVector2Array([
				Vector2(0, 0),
				Vector2(tile_size, 0),
				Vector2(tile_size, tile_size),
				Vector2(0, tile_size)
			])
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, polygon)
		
		TileStyleConfig.TileType.WALL:
			# Full collision (same as ground for now, but could be different)
			var polygon = PackedVector2Array([
				Vector2(0, 0),
				Vector2(tile_size, 0),
				Vector2(tile_size, tile_size),
				Vector2(0, tile_size)
			])
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, polygon)
		
		TileStyleConfig.TileType.PLATFORM:
			# Top-only collision (one-way platform)
			var polygon = PackedVector2Array([
				Vector2(0, 0),
				Vector2(tile_size, 0),
				Vector2(tile_size, 4),
				Vector2(0, 4)
			])
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, polygon)
			tile_data.set_collision_polygon_one_way(0, 0, true)

func _get_tile_type_name(tile_type: int) -> String:
	match tile_type:
		TileStyleConfig.TileType.GROUND:
			return "Ground"
		TileStyleConfig.TileType.WALL:
			return "Wall"
		TileStyleConfig.TileType.PLATFORM:
			return "Platform"
		_:
			return "Unknown"

func regenerate_tileset(new_seed: float = -1.0) -> void:
	# Clear existing tiles
	clear()
	tile_cache.clear()
	
	# Generate new tileset
	await generate_tileset(new_seed)

func get_current_style() -> String:
	if style_config:
		return style_config.get_style_name()
	return "None"

func get_current_seed() -> float:
	if style_config:
		return style_config.current_seed
	return 0.0

# Helper function to paint a simple test level
func paint_test_level() -> void:
	var half_width = int(scene_width_tiles / 2)
	var ground_y = scene_height_tiles - 5  # Place ground near bottom, leave some space
	var wall_left_x = -half_width
	var wall_right_x = half_width - 1 if scene_width_tiles % 2 == 0 else half_width

	# Paint ground
	for x in range(wall_left_x, wall_right_x + 1):
		set_cell(0, Vector2i(x, ground_y), 0, Vector2i(0, 0))
	
	# Paint walls
	for y in range(0, scene_height_tiles):
		set_cell(0, Vector2i(wall_left_x, y), 1, Vector2i(0, 0))
		set_cell(0, Vector2i(wall_right_x, y), 1, Vector2i(0, 0))
	
	# Randomized platform generation (reachable and above ground)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(style_config.current_seed)
	
	# Player jump physics
	var jump_velocity = 400.0 # abs(JUMP_VELOCITY)
	var gravity = 980.0 # Default Godot gravity, can be adjusted
	var speed = 200.0
	
	var max_jump_time = 2.0 * jump_velocity / gravity
	var max_jump_height = (jump_velocity * jump_velocity) / (2.0 * gravity)
	var max_jump_tiles = int(max_jump_height / tile_size)
	var max_horizontal_reach = int(speed * max_jump_time / tile_size)
	
	var num_platforms = rng.randi_range(5, 10)
	var placed_platforms = []
	var platform_spans = []
	var has_long = false
	var has_short = false

	for i in range(num_platforms):
		var attempts = 0
		while attempts < 20:
			var plat_length = rng.randi_range(1, 6)
			# Force at least one long and one short platform
			if i == num_platforms - 2 and not has_long:
				plat_length = rng.randi_range(5, 6)
			if i == num_platforms - 1 and not has_short:
				plat_length = rng.randi_range(1, 2)
			var plat_x = rng.randi_range(wall_left_x + 2, wall_right_x - plat_length - 2)
			var plat_y = rng.randi_range(ground_y - max_jump_tiles - 6, ground_y - 2)
			# Ensure above ground
			if plat_y >= ground_y:
				attempts += 1
				continue
			# Check for overlap
			var overlap = false
			for span in platform_spans:
				if plat_y == span.y and (plat_x < span.x + span.length and plat_x + plat_length > span.x):
					overlap = true
					break
			if overlap:
				attempts += 1
				continue
			# Check reachability from ground or another platform
			var reachable = false
			# From ground
			if (ground_y - plat_y) <= max_jump_tiles:
				reachable = true
			# From another platform
			for p in placed_platforms:
				if abs(plat_x - p.x) <= max_horizontal_reach and abs(plat_y - p.y) <= max_jump_tiles:
					reachable = true
					break
			if reachable:
				for dx in range(plat_length):
					set_cell(0, Vector2i(plat_x + dx, plat_y), 2, Vector2i(0, 0))
					placed_platforms.append(Vector2(plat_x + dx, plat_y))
				platform_spans.append({"x": plat_x, "y": plat_y, "length": plat_length})
				if plat_length >= 5:
					has_long = true
				if plat_length <= 2:
					has_short = true
				break
			attempts += 1
	
	print("Test level painted")
	
	# Set player starting position to third tile from the left, using tile_size
	var player_node = null
	if get_parent().has_node("Player"):
		player_node = get_parent().get_node("Player")
	if player_node:
		# Place player at the third tile from the left edge, on the ground, using TileMap's map_to_local
		var player_cell = Vector2i(wall_left_x + 2, ground_y)
		player_node.position = self.map_to_local(player_cell)
