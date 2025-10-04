extends Node2D
class_name BiomeBackgroundManager

# Reference to the background sprite
var background_sprite: Sprite2D

# Create and configure background based on biome
func setup_background(style_config, viewport_size: Vector2) -> void:
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
func _configure_background_shader(shader_material: ShaderMaterial, style_config) -> void:
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

# Clean up
func _exit_tree():
	if background_sprite:
		background_sprite.queue_free()
