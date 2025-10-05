extends Node2D

# Track flip state
var is_flipped: bool = false

# Transition settings
@export var transition_duration: float = 0.8
@export var radial_wipe_duration: float = 1.0  # Speed for radial wipe transition

# Random regeneration settings
var should_trigger_random_regen: bool = false
var random_regen_time: float = 0.0
var game_elapsed_time: float = 0.0
var has_triggered_regen: bool = false
@export var min_regen_time: float = 5.0  # Minimum time before regeneration (seconds)
@export var max_regen_time: float = 30.0  # Maximum time before regeneration (seconds)

# Reference to dissolve overlay
@onready var dissolve_overlay: ColorRect = $DissolveOverlay

# Preload both shader materials
var pixelated_dissolve_shader: Shader
var radial_wipe_shader: Shader

@export var sfx_enabled: bool = true
@export var sfx_volume_db: float = -3.0

const _DREAM_SFX_PATHS := ["res://Musics/dream.mp3"]
var _sfx: AudioStreamPlayer

func _ready():
	# Load shaders
	pixelated_dissolve_shader = load("res://Shaders/pixelated_dissolve.gdshader")
	radial_wipe_shader = load("res://Shaders/radial_wipe.gdshader")
	
	# Start with pixelated dissolve shader
	_set_shader(pixelated_dissolve_shader, "dissolve_progress")
	
	# Ensure dissolve starts at 0 (fully visible)
	if dissolve_overlay and dissolve_overlay.material:
		dissolve_overlay.material.set_shader_parameter("dissolve_progress", 0.0)
	
	# 20% chance to start in upside down mode
	_apply_random_flip()
	
	# 20% chance to schedule a random mid-playthrough regeneration
	_schedule_random_regeneration()
	
	call_deferred("_play_opening_dissolve")

func _process(delta: float):
	# Track game time and trigger random regeneration if scheduled
	if should_trigger_random_regen and not has_triggered_regen:
		game_elapsed_time += delta
		
		if game_elapsed_time >= random_regen_time:
			has_triggered_regen = true
			print(">>> Random regeneration triggered at %.2f seconds! <<<" % game_elapsed_time)
			trigger_level_regeneration()
			_play_dream_sfx()

func _set_shader(shader: Shader, progress_param: String):
	"""Helper function to set the shader on the dissolve overlay"""
	if dissolve_overlay:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		dissolve_overlay.material = shader_material

func _input(event):
	# Handle input events
	if event is InputEventKey and event.pressed and not event.echo:
		# Toggle vertical flip when 'u' key is pressed
		if event.keycode == KEY_U:
			toggle_vertical_flip()
		# Apply random flip when 'r' key is pressed (after tileset regeneration)
		elif event.keycode == KEY_R:
			# Wait a frame for the tileset regeneration to complete, then apply random flip
			await get_tree().process_frame
			_apply_random_flip()

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
	
	print("\n>>> Starting radial wipe transition <<<")
	
	# Pause the timer during transition
	var timer_label = _get_timer_label()
	if timer_label and timer_label.has_method("pause_timer"):
		timer_label.pause_timer()
	
	# Switch to radial wipe shader for 'w' key
	_set_shader(radial_wipe_shader, "wipe_progress")
	dissolve_overlay.material.set_shader_parameter("wipe_progress", 0.0)
	
	# Create tween for wipe animation
	var tween = create_tween()
	
	# Wipe out (circle collapses inward to black)
	tween.tween_property(
		dissolve_overlay.material,
		"shader_parameter/wipe_progress",
		1.0,
		radial_wipe_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Wait for wipe out to complete
	await tween.finished
	
	# Regenerate the level
	await _regenerate_level(tileset_generator)
	
	# Create new tween for wipe in
	var tween_in = create_tween()
	
	# Wipe in (circle expands from center revealing new level)
	tween_in.tween_property(
		dissolve_overlay.material,
		"shader_parameter/wipe_progress",
		0.0,
		radial_wipe_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await tween_in.finished
	print(">>> Radial wipe transition complete <<<\n")
	
	# Switch back to pixelated dissolve shader for other transitions
	_set_shader(pixelated_dissolve_shader, "dissolve_progress")
	dissolve_overlay.material.set_shader_parameter("dissolve_progress", 0.0)
	
	# Unpause the timer after transition
	if timer_label and timer_label.has_method("unpause_timer"):
		timer_label.unpause_timer()

func _regenerate_level(tileset_generator):
	"""Helper function to regenerate the level"""
	print(">>> Regenerating level around player (position preserved) <<<")
	
	if tileset_generator is TilesetGenerator:
		# Regenerate with a new seed while preserving player position
		await tileset_generator.regenerate_tileset(-1.0, true)
		print(">>> Level regenerated! Player may be in mid-air <<<")
	else:
		print("Warning: TileMap is not a TilesetGenerator")
	
	# 20% chance to flip after regeneration
	_apply_random_flip()
	
func _play_opening_dissolve() -> void:
	_play_dream_sfx()
	if dissolve_overlay and dissolve_overlay.material:
		var mat := dissolve_overlay.material
		mat.set_shader_parameter("dissolve_progress", 1.0)
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(mat, "shader_parameter/dissolve_progress", 0.0, transition_duration)
		await tw.finished

func _schedule_random_regeneration():
	"""Determine if this playthrough will have a random regeneration (20% chance)"""
	var random_value = randf()
	should_trigger_random_regen = random_value < 0.2
	
	if should_trigger_random_regen:
		# Choose a random time between min and max
		random_regen_time = randf_range(min_regen_time, max_regen_time)
		print(">>> Random regeneration scheduled for %.2f seconds (rolled %.2f) <<<" % [random_regen_time, random_value])
	else:
		print(">>> No random regeneration for this playthrough (rolled %.2f) <<<" % random_value)

func _apply_random_flip():
	"""Apply a 20% chance to flip the game upside down"""
	# Generate random number between 0 and 1
	var random_value = randf()
	
	# 20% chance (0.2) to be flipped
	var should_be_flipped = random_value < 0.2
	
	# Force the state to match the random decision
	if should_be_flipped != is_flipped:
		toggle_vertical_flip()
	
	# Print the result
	if should_be_flipped:
		print(">>> Random flip: Game is UPSIDE DOWN (rolled %.2f) <<<" % random_value)
	else:
		print(">>> Random flip: Game is RIGHT SIDE UP (rolled %.2f) <<<" % random_value)

func _get_timer_label() -> Label:
	"""Helper function to get the timer label from UILayer"""
	var ui_layer = get_node_or_null("UILayer")
	if ui_layer:
		var timer_label = ui_layer.get_node_or_null("TimerPanel/TimerLabel")
		if timer_label:
			return timer_label
	return null

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
