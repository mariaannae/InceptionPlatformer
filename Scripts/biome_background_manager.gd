extends Node2D
class_name BiomeBackgroundManager

# Reference to the background sprite
var background_sprite: Sprite2D

# Disco ball sprites
var disco_balls: Array = []

# Disco ball configuration (adjustable parameters)
# spawn_height_range: As fraction of screen height
# spawn_width_range: As fraction of screen width
var disco_ball_config = {
	"min_count": 2,
	"max_count": 5,
	"min_scale": 0.3,
	"max_scale": 0.8,
	"spawn_height_range": Vector2(0.2, 0.7),
	"spawn_width_range": Vector2(0.1, 0.9),
	"min_spacing": 150.0,  # Minimum distance between disco ball centers
	"max_spawn_attempts": 50,  # Maximum attempts to find non-overlapping position
	"shader_params": {
		"iridescent_speed": 1.0,
		"facet_scale": 10.0,
		"brightness": 0.8,
		"color_shift_range": 1.0
	}
}

# Create and configure background based on biome
func setup_background(style_config: TileStyleConfig, viewport_size: Vector2) -> void:
	# Remove existing background if present
	if background_sprite:
		background_sprite.queue_free()
	
	# Create new background Sprite2D
	background_sprite = Sprite2D.new()
	background_sprite.z_index = -100  # Render behind everything
	background_sprite.centered = true  # Center it!
	# Center the background on the world origin
	background_sprite.position = Vector2.ZERO
	
	# Create a base texture
	var img = Image.create(int(viewport_size.x), int(viewport_size.y), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 0.5))  # Gray base
	var texture = ImageTexture.create_from_image(img)
	background_sprite.texture = texture
	
	# Load appropriate shader based on style
	var shader_path = _get_background_shader_path(style_config.current_style)
	
	if shader_path != "":
		var shader_material = ShaderMaterial.new()
		shader_material.shader = load(shader_path)
		
		# Configure shader parameters
		_configure_background_shader(shader_material, style_config)
		
		# Apply shader to sprite
		background_sprite.material = shader_material
		print("Applied ", style_config.get_style_name(), " background shader")
	else:
		# Fallback to simple colored background for non-biome styles
		print("No background shader for: ", style_config.get_style_name())
	
	# Add to scene at the beginning (so it renders first/behind)
	add_child(background_sprite)
	move_child(background_sprite, 0)
	
	# Spawn disco balls if disco biome
	if style_config.current_style == TileStyleConfig.Style.DISCO:
		_spawn_disco_balls(style_config, viewport_size)

# Get shader path for each biome
func _get_background_shader_path(style: int) -> String:
	match style:
		TileStyleConfig.Style.GRASSLAND:
			return "res://Shaders/grassland_background.gdshader"
		TileStyleConfig.Style.FOREST:
			return "res://Shaders/forest_background.gdshader"
		TileStyleConfig.Style.CAVE:
			return "res://Shaders/cave_background.gdshader"
		TileStyleConfig.Style.DISCO:
			return "res://Shaders/disco_background.gdshader"
		_:
			return ""  # No background for other styles

# Configure shader parameters with biome palette
func _configure_background_shader(shader_material: ShaderMaterial, style_config: TileStyleConfig) -> void:
	var palette = style_config.get_palette()
	
	# Set seed for procedural generation
	shader_material.set_shader_parameter("seed", float(style_config.current_seed))
	
	# Set style-specific parameters
	var current_style = int(style_config.current_style)
	match current_style:
		TileStyleConfig.Style.GRASSLAND:
			shader_material.set_shader_parameter("grass_light", palette.get("grass_light", Color.GREEN))
			shader_material.set_shader_parameter("grass_medium", palette.get("grass_medium", Color.DARK_GREEN))
			shader_material.set_shader_parameter("grass_dark", palette.get("grass_dark", Color.DARK_OLIVE_GREEN))
			shader_material.set_shader_parameter("sky_hint", palette.get("sky_hint", Color.SKY_BLUE))
		
		TileStyleConfig.Style.FOREST:
			shader_material.set_shader_parameter("canopy_light", palette.get("canopy_light", Color.GREEN))
			shader_material.set_shader_parameter("canopy_medium", palette.get("canopy_medium", Color.DARK_GREEN))
			shader_material.set_shader_parameter("canopy_dark", palette.get("canopy_dark", Color.DARK_OLIVE_GREEN))
			shader_material.set_shader_parameter("bark_light", palette.get("bark_light", Color.BROWN))
			shader_material.set_shader_parameter("bark_dark", palette.get("bark_dark", Color.DARK_GOLDENROD))
		
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
			shader_material.set_shader_parameter("club_black", palette.get("club_black", Color(0.02, 0.02, 0.05)))
			shader_material.set_shader_parameter("club_shadow", palette.get("club_shadow", Color(0.05, 0.05, 0.1)))
			shader_material.set_shader_parameter("mirror_sparkle", palette.get("mirror_sparkle", Color.WHITE))
			shader_material.set_shader_parameter("time_offset", randf() * 100.0)

# Spawn disco balls for disco biome  
func _spawn_disco_balls(style_config: TileStyleConfig, viewport_size: Vector2) -> void:
	# Clear existing disco balls
	for ball in disco_balls:
		ball.queue_free()
	disco_balls.clear()
	
	# Load disco ball scene
	var disco_ball_scene = load("res://Scenes/disco_ball.tscn")
	if disco_ball_scene == null:
		print("ERROR: Could not load disco_ball.tscn!")
		return
	
	print("Successfully loaded disco_ball.tscn scene")
	
	# Randomly determine number of disco balls to spawn
	var ball_count = randi_range(disco_ball_config["min_count"], disco_ball_config["max_count"])
	
	# Store spawned positions for overlap checking
	var spawned_positions: Array = []
	
	# Spawn disco balls
	for i in range(ball_count):
		# Instance the disco ball scene
		var ball = disco_ball_scene.instantiate()
		
		# Between background (-100) and platforms (0)
		ball.z_index = -50
		
		# Try to find a non-overlapping position
		var valid_position_found = false
		var attempts = 0
		var ball_position = Vector2.ZERO
		var scale_val = 1.0
		
		while not valid_position_found and attempts < disco_ball_config["max_spawn_attempts"]:
			attempts += 1
			
			# Random position within spawn area
			var spawn_height = disco_ball_config["spawn_height_range"]
			var spawn_width = disco_ball_config["spawn_width_range"]
			var x = lerp(viewport_size.x * spawn_width.x, viewport_size.x * spawn_width.y, randf())
			var y = lerp(viewport_size.y * spawn_height.x, viewport_size.y * spawn_height.y, randf())
			# Center on origin
			ball_position = Vector2(x, y) - viewport_size / 2.0
			
			# Scale based on height - higher balls are larger (depth effect)
			var height_factor = (y - viewport_size.y * spawn_height.x) / (viewport_size.y * (spawn_height.y - spawn_height.x))
			height_factor = 1.0 - height_factor
			scale_val = lerp(disco_ball_config["min_scale"], disco_ball_config["max_scale"], height_factor)
			
			# Check if this position overlaps with any existing disco ball
			valid_position_found = true
			for existing_pos in spawned_positions:
				var distance = ball_position.distance_to(existing_pos)
				if distance < disco_ball_config["min_spacing"]:
					valid_position_found = false
					break
		
		# If we found a valid position, place the ball
		if valid_position_found:
			ball.position = ball_position
			ball.scale = Vector2(scale_val, scale_val)
			spawned_positions.append(ball_position)
			
			# The shader should already be applied in the scene
			# But we can update parameters if needed
			if ball.material:
				ball.material.set_shader_parameter("time_offset", randf() * 100.0)
				print("Set time_offset for disco ball #", i)
			
			# Add to scene
			add_child(ball)
			disco_balls.append(ball)
		else:
			# Could not find valid position, free the ball instance
			ball.queue_free()
			print("Could not find non-overlapping position for disco ball #", i, " after ", attempts, " attempts")
	
	print("Spawned ", ball_count, " disco balls from scene")

# Clean up
func _exit_tree() -> void:
	if background_sprite:
		background_sprite.queue_free()
	
	for ball in disco_balls:
		ball.queue_free()
	disco_balls.clear()
