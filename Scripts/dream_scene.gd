extends Node2D

# Track flip state
var is_flipped: bool = false

# Transition settings
@export var transition_duration: float = 1.5

# Reference to dissolve overlay
@onready var dissolve_overlay: ColorRect = $DissolveOverlay

@export var sfx_enabled: bool = true
@export var sfx_volume_db: float = -3.0

const _DREAM_SFX_PATHS := ["res://Musics/dream.mp3"]
var _sfx: AudioStreamPlayer

func _ready():
	# Ensure dissolve starts at 0 (fully visible)
	if dissolve_overlay and dissolve_overlay.material:
		dissolve_overlay.material.set_shader_parameter("dissolve_progress", 0.0)
	
	call_deferred("_play_opening_dissolve")

func _input(event):
	# Handle input events
	if event is InputEventKey and event.pressed and not event.echo:
		# Toggle vertical flip when 'u' key is pressed
		if event.keycode == KEY_U:
			toggle_vertical_flip()
		# Regenerate level around player when 'w' key is pressed
		elif event.keycode == KEY_W:
			trigger_level_regeneration()
			_play_dream_sfx()

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
	
	if not dissolve_overlay or not dissolve_overlay.material:
		print("Warning: Dissolve overlay not found, regenerating without transition")
		await _regenerate_level(tileset_generator)
		return
	
	print("\n>>> Starting dissolve transition <<<")
	
	# Create tween for dissolve animation
	var tween = create_tween()
	
	# Fade out (dissolve to black)
	tween.tween_property(
		dissolve_overlay.material,
		"shader_parameter/dissolve_progress",
		1.0,
		transition_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Wait for fade out to complete
	await tween.finished
	
	# Regenerate the level
	await _regenerate_level(tileset_generator)
	
	# Create new tween for fade in
	var tween_in = create_tween()
	
	# Fade in (rebuild from black)
	tween_in.tween_property(
		dissolve_overlay.material,
		"shader_parameter/dissolve_progress",
		0.0,
		transition_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await tween_in.finished
	print(">>> Dissolve transition complete <<<\n")

func _regenerate_level(tileset_generator):
	"""Helper function to regenerate the level"""
	print(">>> Regenerating level around player (position preserved) <<<")
	
	if tileset_generator is TilesetGenerator:
		# Regenerate with a new seed while preserving player position
		await tileset_generator.regenerate_tileset(-1.0, true)
		print(">>> Level regenerated! Player may be in mid-air <<<")
	else:
		print("Warning: TileMap is not a TilesetGenerator")
	
func _play_opening_dissolve() -> void:
	_play_dream_sfx()
	if dissolve_overlay and dissolve_overlay.material:
		var mat := dissolve_overlay.material
		mat.set_shader_parameter("dissolve_progress", 1.0)
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(mat, "shader_parameter/dissolve_progress", 0.0, transition_duration)
		await tw.finished

func _play_dream_sfx() -> void:
	if not sfx_enabled:
		return
	var stream: AudioStream = null
	for p in _DREAM_SFX_PATHS:
		if ResourceLoader.exists(p):
			stream = load(p)
			break
	if stream == null:
		push_warning("Dream SFX not found. Tried: %s" % [_DREAM_SFX_PATHS])
		return

	if _sfx == null:
		_sfx = AudioStreamPlayer.new()
		_sfx.name = "DreamSFX"
		add_child(_sfx)

	_sfx.stream = stream
	_sfx.volume_db = sfx_volume_db
	_sfx.play()
