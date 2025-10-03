extends Node2D

# Track flip state
var is_flipped: bool = false

func _ready():
	pass

func _input(event):
	# Handle input events
	if event is InputEventKey and event.pressed and not event.echo:
		# Toggle vertical flip when 'u' key is pressed
		if event.keycode == KEY_U:
			toggle_vertical_flip()
		# Regenerate level around player when 'w' key is pressed
		elif event.keycode == KEY_W:
			trigger_level_regeneration()

func toggle_vertical_flip():
	is_flipped = !is_flipped
	
	# Get the SubViewportContainer and flip its Y-scale
	# This flips only the rendering, not the physics world inside the SubViewport
	# Physics run normally, but the final rendered output is flipped
	var viewport_container = $SubViewportContainer
	if viewport_container:
		if is_flipped:
			viewport_container.scale.y = -1
			# Adjust position to keep the flipped content visible
			# When flipped, move it down by its height
			viewport_container.position.y = viewport_container.size.y
		else:
			viewport_container.scale.y = 1
			# Reset position to original
			viewport_container.position.y = 0

func trigger_level_regeneration():
	# Get references to player and tileset generator inside the SubViewport
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	var player = game_world.get_node_or_null("Player")
	var tileset_generator = game_world.get_node_or_null("TileMap")
	
	if not player or not tileset_generator:
		print("Warning: Could not find Player or TileMap nodes")
		return
	
	print("\n>>> Regenerating level around player (position preserved) <<<")
	
	if tileset_generator is TilesetGenerator:
		# Regenerate with a new seed while preserving player position
		await tileset_generator.regenerate_tileset(-1.0, true)
		print(">>> Level regenerated! Player may be in mid-air <<<\n")
	else:
		print("Warning: TileMap is not a TilesetGenerator")
