extends TileMap
class_name TilesetGenerator

# Configuration
@export var tile_size: int = 32
@export var initial_seed: float = -1.0
@export var auto_generate: bool = true

# Scene size configuration (number of tiles)
@export var scene_width_tiles: int = 66
@export var scene_height_tiles: int = 16

# Internal state
var style_config
var generated_tileset: TileSet
var tile_cache: Dictionary = {}
var background_manager: BiomeBackgroundManager

func _ready():
	if auto_generate:
		await generate_tileset()

func _input(event):
	# Press 'R' to regenerate tileset with new random style and seed
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		print("\n>>> Regenerating tileset with new random style <<<")
		await regenerate_tileset()
		print(">>> Press 'R' again to regenerate <<<\n")

func generate_tileset(seed_value: float = -1.0, preserve_player_position: bool = false) -> void:
	print("=== Starting Tileset Generation ===")
	
	# Create style configuration
	style_config = TileStyleConfig.new(seed_value if seed_value >= 0 else initial_seed)
	print("Selected Style: ", style_config.get_style_name())
	print("Seed: ", style_config.current_seed)
	
	# Setup background for biome
	_setup_background()
	
	# Create new tileset
	generated_tileset = TileSet.new()
	generated_tileset.tile_size = Vector2i(tile_size, tile_size)
	
	# Generate tiles for each type
	await _generate_tile_type(TileStyleConfig.TileType.GROUND, 0)
	await _generate_tile_type(TileStyleConfig.TileType.WALL, 1)
	await _generate_tile_type(TileStyleConfig.TileType.PLATFORM, 2)
	await _generate_tile_type(TileStyleConfig.TileType.ENDGOAL, 3)
	await _generate_tile_type(TileStyleConfig.TileType.SUBSURFACE, 4)
	
	# Assign tileset to this TileMap
	tile_set = generated_tileset
	
	# Apply crystal cave ripple effect if in crystal cave biome
	_apply_biome_effects()
	
	print("=== Tileset Generation Complete ===")
	print("Total tiles created: ", generated_tileset.get_source_count())
	
	# Paint test level with player position preservation flag
	paint_test_level(preserve_player_position)

func _generate_tile_type(tile_type: int, source_id: int) -> void:
	# Create tile source
	var atlas_source = TileSetAtlasSource.new()
	
	# Special handling for ENDGOAL (48px high)
	if tile_type == TileStyleConfig.TileType.ENDGOAL:
		atlas_source.texture = await _create_endgoal_texture()
		atlas_source.texture_region_size = Vector2i(tile_size, 48)
	else:
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
	
	# Check if this style should use pixel art generation
	if _should_use_pixel_art():
		var biome_name = style_config.get_style_name().to_upper().replace(" ", "_")
		var pixel_art_image = PixelArtTileGenerator.generate_tile_image(biome_name, tile_type, style_config.current_seed, tile_size)
		var pixel_art_texture = ImageTexture.create_from_image(pixel_art_image)
		tile_cache[cache_key] = pixel_art_texture
		return pixel_art_texture
	
	# Otherwise use shader-based generation
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
	var shader_path = style_config.get_shader_path()
	
	# Check if shader file exists, fallback to smooth if not
	if not ResourceLoader.exists(shader_path):
		print("Warning: Shader not found at ", shader_path, ", using smooth shader as fallback")
		shader_path = "res://Shaders/smooth_tile.gdshader"
	
	shader_material.shader = load(shader_path)
	
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
	var rendered_image = viewport_texture.get_image()
	
	# Create ImageTexture
	var texture = ImageTexture.create_from_image(rendered_image)
	
	# Clean up
	viewport.remove_child(color_rect)
	remove_child(viewport)
	color_rect.queue_free()
	viewport.queue_free()
	
	# Cache the texture
	tile_cache[cache_key] = texture
	
	return texture

func _create_endgoal_texture() -> ImageTexture:
	# Check if this style should use pixel art generation
	if _should_use_pixel_art():
		var biome_name = style_config.get_style_name().to_upper().replace(" ", "_")

		var pixel_art_image = PixelArtTileGenerator.generate_tile_image(biome_name, TileStyleConfig.TileType.ENDGOAL, style_config.current_seed, tile_size)
		var pixel_art_texture = ImageTexture.create_from_image(pixel_art_image)
		return pixel_art_texture
	
	# Otherwise use shader-based generation
	# Create a 32x48 texture for the end goal
	var viewport = SubViewport.new()
	viewport.size = Vector2i(tile_size, 48)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.transparent_bg = false
	
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(tile_size, 48)
	
	# Check if we have a biome shader, otherwise create simple green
	if style_config.current_style >= TileStyleConfig.Style.GRASSLAND:
		# Use biome shader with ENDGOAL tile type
		var shader_material = ShaderMaterial.new()
		var shader_path = style_config.get_shader_path()
		
		if ResourceLoader.exists(shader_path):
			shader_material.shader = load(shader_path)
			_configure_shader_material(shader_material, TileStyleConfig.TileType.ENDGOAL)
			color_rect.material = shader_material
		else:
			# Fallback to simple green
			color_rect.color = Color(0.0, 0.7, 0.2)
	else:
		# For non-biome styles, create a simple green goal
		color_rect.color = Color(0.0, 0.7, 0.2)
	
	viewport.add_child(color_rect)
	add_child(viewport)
	
	await RenderingServer.frame_post_draw
	
	var viewport_texture = viewport.get_texture()
	var rendered_image = viewport_texture.get_image()
	var rendered_texture = ImageTexture.create_from_image(rendered_image)
	
	viewport.remove_child(color_rect)
	remove_child(viewport)
	color_rect.queue_free()
	viewport.queue_free()
	
	return rendered_texture

func _configure_shader_material(shader_material: ShaderMaterial, tile_type: int) -> void:
	var palette = style_config.get_palette()
	
	# Set common parameters
	shader_material.set_shader_parameter("seed", style_config.current_seed)
	shader_material.set_shader_parameter("tile_type", tile_type)
	
	# Set style-specific color parameters
	match style_config.current_style:
		
		TileStyleConfig.Style.SMOOTH_MODERN_ABSTRACT:
			shader_material.set_shader_parameter("base_color", palette.get("base_color", Color.PURPLE))
			shader_material.set_shader_parameter("highlight_color", palette.get("highlight_color", Color.PINK))
			shader_material.set_shader_parameter("shadow_color", palette.get("shadow_color", Color.DARK_VIOLET))
		
		TileStyleConfig.Style.GRASSLAND:
			shader_material.set_shader_parameter("grass_light", palette.get("grass_light", Color.GREEN))
			shader_material.set_shader_parameter("grass_medium", palette.get("grass_medium", Color.DARK_GREEN))
			shader_material.set_shader_parameter("grass_dark", palette.get("grass_dark", Color.DARK_OLIVE_GREEN))
			shader_material.set_shader_parameter("earth_light", palette.get("earth_light", Color.BROWN))
			shader_material.set_shader_parameter("earth_dark", palette.get("earth_dark", Color.DARK_GOLDENROD))
			shader_material.set_shader_parameter("sky_hint", palette.get("sky_hint", Color.SKY_BLUE))
		
		TileStyleConfig.Style.FOREST:
			shader_material.set_shader_parameter("canopy_light", palette.get("canopy_light", Color.GREEN))
			shader_material.set_shader_parameter("canopy_medium", palette.get("canopy_medium", Color.DARK_GREEN))
			shader_material.set_shader_parameter("canopy_dark", palette.get("canopy_dark", Color.DARK_OLIVE_GREEN))
			shader_material.set_shader_parameter("bark_light", palette.get("bark_light", Color.BROWN))
			shader_material.set_shader_parameter("bark_dark", palette.get("bark_dark", Color.DARK_GOLDENROD))
			shader_material.set_shader_parameter("moss_color", palette.get("moss_color", Color.DARK_SEA_GREEN))
		
		TileStyleConfig.Style.RUINS:
			shader_material.set_shader_parameter("stone_light", palette.get("stone_light", Color.LIGHT_GRAY))
			shader_material.set_shader_parameter("stone_medium", palette.get("stone_medium", Color.GRAY))
			shader_material.set_shader_parameter("stone_dark", palette.get("stone_dark", Color.DIM_GRAY))
			shader_material.set_shader_parameter("moss_stone", palette.get("moss_stone", Color.DARK_SEA_GREEN))
			shader_material.set_shader_parameter("accent_copper", palette.get("accent_copper", Color.PERU))
			shader_material.set_shader_parameter("accent_jade", palette.get("accent_jade", Color.MEDIUM_SEA_GREEN))
		
		TileStyleConfig.Style.CAVE:
			shader_material.set_shader_parameter("rock_darkest", palette.get("rock_darkest", Color.BLACK))
			shader_material.set_shader_parameter("rock_dark", palette.get("rock_dark", Color.DIM_GRAY))
			shader_material.set_shader_parameter("rock_medium", palette.get("rock_medium", Color.GRAY))
			shader_material.set_shader_parameter("mineral_blue", palette.get("mineral_blue", Color.STEEL_BLUE))
			shader_material.set_shader_parameter("mineral_purple", palette.get("mineral_purple", Color.MEDIUM_PURPLE))
			shader_material.set_shader_parameter("wet_highlight", palette.get("wet_highlight", Color.LIGHT_SLATE_GRAY))
		
		TileStyleConfig.Style.DISCO:
			shader_material.set_shader_parameter("neon_pink", palette.get("neon_pink", Color(1.0, 0.0, 0.8)))
			shader_material.set_shader_parameter("neon_blue", palette.get("neon_blue", Color(0.0, 0.5, 1.0)))
			shader_material.set_shader_parameter("neon_green", palette.get("neon_green", Color(0.0, 1.0, 0.5)))
			shader_material.set_shader_parameter("neon_purple", palette.get("neon_purple", Color(0.8, 0.0, 1.0)))
			shader_material.set_shader_parameter("floor_light", palette.get("floor_light", Color(0.8, 0.2, 0.6)))
			shader_material.set_shader_parameter("floor_medium", palette.get("floor_medium", Color(0.2, 0.6, 0.8)))
			shader_material.set_shader_parameter("floor_dark", palette.get("floor_dark", Color(0.6, 0.2, 0.8)))
			shader_material.set_shader_parameter("club_black", palette.get("club_black", Color(0.02, 0.02, 0.05)))
			shader_material.set_shader_parameter("club_shadow", palette.get("club_shadow", Color(0.05, 0.05, 0.1)))
			shader_material.set_shader_parameter("mirror_sparkle", palette.get("mirror_sparkle", Color(1.0, 1.0, 1.0)))

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
			# Full collision
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
		
		TileStyleConfig.TileType.ENDGOAL:
			# No collision - it's a trigger/goal area
			pass  # Player should be able to enter it
		
		TileStyleConfig.TileType.SUBSURFACE:
			# Full collision like ground
			var polygon = PackedVector2Array([
				Vector2(0, 0),
				Vector2(tile_size, 0),
				Vector2(tile_size, tile_size),
				Vector2(0, tile_size)
			])
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, polygon)

func _get_tile_type_name(tile_type: int) -> String:
	match tile_type:
		TileStyleConfig.TileType.GROUND:
			return "Ground"
		TileStyleConfig.TileType.WALL:
			return "Wall"
		TileStyleConfig.TileType.PLATFORM:
			return "Platform"
		TileStyleConfig.TileType.ENDGOAL:
			return "End Goal"
		TileStyleConfig.TileType.SUBSURFACE:
			return "Subsurface"
		_:
			return "Unknown"

func regenerate_tileset(new_seed: float = -1.0, preserve_player_position: bool = false) -> void:
	# Clear existing tiles and tileset reference to avoid duplicate atlas source IDs
	clear()
	tile_set = null
	tile_cache.clear()
	
	# Generate new tileset with player position preservation flag
	await generate_tileset(new_seed, preserve_player_position)

func get_current_style() -> String:
	if style_config:
		return style_config.get_style_name()
	return "None"

func get_current_seed() -> float:
	if style_config:
		return style_config.current_seed
	return 0.0

# Check if the current style should use pixel art generation
func _should_use_pixel_art() -> bool:
	return style_config.current_style in [
		TileStyleConfig.Style.GRASSLAND,
		TileStyleConfig.Style.FOREST,
		TileStyleConfig.Style.RUINS,
		TileStyleConfig.Style.CAVE,
		TileStyleConfig.Style.DISCO
	]

# Apply biome-specific visual effects
func _apply_biome_effects() -> void:
	if style_config.current_style == TileStyleConfig.Style.DISCO:
		# Apply the disco lights effect
		var disco_shader = load("res://Shaders/disco_lights.gdshader")
		var shader_material = ShaderMaterial.new()
		shader_material.shader = disco_shader
		
		# Set shader parameters from palette
		var palette = style_config.get_palette()
		shader_material.set_shader_parameter("neon_pink", palette.get("neon_pink", Color(1.0, 0.0, 0.8)))
		shader_material.set_shader_parameter("neon_blue", palette.get("neon_blue", Color(0.0, 0.5, 1.0)))
		shader_material.set_shader_parameter("neon_green", palette.get("neon_green", Color(0.0, 1.0, 0.5)))
		shader_material.set_shader_parameter("neon_purple", palette.get("neon_purple", Color(0.8, 0.0, 1.0)))
		
		# Set disco light parameters (slower speeds, very low intensity so iridescence is visible)
		shader_material.set_shader_parameter("rotation_speed", 0.3)
		shader_material.set_shader_parameter("light_intensity", 0.15)
		shader_material.set_shader_parameter("strobe_speed", 0.8)
		shader_material.set_shader_parameter("light_seed", style_config.current_seed)
		
		# Apply material to the TileMap
		material = shader_material
		
		print("Applied disco lights effect with seed: ", style_config.current_seed)
	else:
		# Remove any shader effect for other biomes
		material = null

# Helper function to paint level using the new sophisticated layout generator
func paint_test_level(preserve_player_position: bool = false) -> void:
	# Create the level layout generator
	var LevelLayoutGeneratorClass = load("res://Scripts/level_layout_generator.gd")
	var layout_generator = LevelLayoutGeneratorClass.new(style_config.current_seed, scene_width_tiles, scene_height_tiles)
	
	# Generate the level data
	var level_data = layout_generator.generate_level()
	
	print("=== Painting Level with Pattern-Based Generation ===")
	
	# Paint ground tiles
	for ground_tile in level_data.ground:
		set_cell(0, Vector2i(ground_tile.x, ground_tile.y), 0, Vector2i(0, 0))
	
	# Paint subsurface tiles underneath all ground tiles down to bottom of world
	for ground_tile in level_data.ground:
		var bottom_y = scene_height_tiles - 1
		for y in range(ground_tile.y + 1, bottom_y + 1):
			set_cell(0, Vector2i(ground_tile.x, y), 4, Vector2i(0, 0))
	
	# Paint wall tiles
	for wall_tile in level_data.walls:
		set_cell(0, Vector2i(wall_tile.x, wall_tile.y), 1, Vector2i(0, 0))
	
	# Paint platforms
	var platform_count = 0
	for platform in level_data.platforms:
		for i in range(platform.length):
			set_cell(0, Vector2i(platform.x + i, platform.y), 2, Vector2i(0, 0))
		platform_count += 1
	
	# Paint end goal
	if level_data.goal.has("x"):
		# Remove any existing Goal nodes from the parent
		var parent = get_parent()
		for child in parent.get_children():
			if child is Node2D and child.scene_file_path == "res://GameObjects/goal.tscn":
				child.queue_free()
		# Instance and place the Goal gameobject at the goal position
		var goal_scene = load("res://GameObjects/goal.tscn")
		var goal_instance = goal_scene.instantiate()
		var goal_cell = Vector2i(level_data.goal.x, level_data.goal.y)
		var goal_world_pos = self.map_to_local(goal_cell)
		goal_instance.position = goal_world_pos
		parent.add_child.call_deferred(goal_instance)
	
	print("Level generated with ", platform_count, " platform segments")
	print("Style: ", style_config.get_style_name())
	print("Seed: ", style_config.current_seed)
	
	# Set player starting position (only if not preserving position)
	var player_node = null
	if get_parent().has_node("Player"):
		player_node = get_parent().get_node("Player")
	
	if player_node:
		if not preserve_player_position:
			var half_width = int(scene_width_tiles / 2)
			var ground_y = scene_height_tiles - 5
			var player_start_x = -half_width + 2
			var player_cell = Vector2i(player_start_x, ground_y - 1)
			player_node.position = self.map_to_local(player_cell)
		else:
			print("Player position preserved during regeneration")
		
		# Update camera limits after level generation/regeneration
		if player_node.has_method("setup_camera_limits"):
			player_node.call_deferred("setup_camera_limits")

# Setup procedural background based on current biome
func _setup_background() -> void:
	# Get the viewport size - make it tall enough to cover the full camera view
	# The camera extends beyond just the tiles, so we need extra height
	var viewport_size = Vector2(scene_width_tiles * tile_size, (scene_height_tiles * tile_size) * 2)
	
	print("Setting up background with size: ", viewport_size)
	print("Parent node: ", get_parent().name)
	
	# Remove old background if it exists
	if background_manager:
		background_manager.queue_free()
		background_manager = null
	
	# Create background manager and add it with call_deferred
	background_manager = BiomeBackgroundManager.new()
	background_manager.name = "BiomeBackground"
	background_manager.z_index = -1000  # Very low z-index to ensure it's behind everything
	
	# Add to parent using call_deferred
	get_parent().add_child.call_deferred(background_manager)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Move to first position
	if background_manager.get_parent():
		get_parent().move_child(background_manager, 0)
		print("Background manager added to: ", background_manager.get_parent().name)
		
		# Now setup the background
		background_manager.setup_background(style_config, viewport_size)
		print("Background setup complete for: ", style_config.get_style_name())
	else:
		print("ERROR: Background manager not added to tree!")
	if background_manager.background_sprite and background_manager.background_sprite.texture:
		print("Background sprite texture size: ", background_manager.background_sprite.texture.get_size())
		print("Background sprite z-index: ", background_manager.background_sprite.z_index)
		print("Background sprite visible: ", background_manager.background_sprite.visible)
	else:
		print("Background sprite: None")
