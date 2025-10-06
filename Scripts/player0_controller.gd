extends CharacterBody2D

signal first_movement

@export var jump_volume_db: float = -6.0
@export var fly_volume_db: float = -6.0

const _JUMP_PATHS := ["res://Musics/jump.wav"]
const _FLY_PATHS  := ["res://Musics/fly.mp3"]
var _jump_sfx: AudioStreamPlayer
var _fly_sfx: AudioStreamPlayer

# Movement variables
const SPEED = 200.0
const JUMP_VELOCITY = -600.0
const ACCELERATION = 2000.0
const FRICTION = 2000.0
const COYOTE_TIME = 0.1 # coyote timer is a nice little buffer when the player jumps to make it easier to not fall
#i guess this stuff is standard for platformers according to several tutorials?
const JUMP_BUFFER_TIME = 0.1

# Flying mode variables
const FLYING_SPEED = 200.0
const FLYING_ACCELERATION = 2000.0
const FLYING_FRICTION = 2000.0
const HOVER_HEIGHT = 600.0  # Height to hover at (same as jump velocity magnitude)
const HOVER_SPEED = 800.0   # Speed to reach hover position

# Movement state
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var has_moved: bool = false

# Flying mode state
var flying_mode: bool = false
var is_hovering: bool = false
var hover_target_y: float = 0.0

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Add player to player group for identification
	add_to_group("player")
	
	# Player position is now set dynamically by TilesetGenerator.gd
	# Wait a frame for the scene tree to be fully ready before setting up camera
	call_deferred("setup_camera_limits")
	call_deferred("_init_sfx")

func setup_camera_limits():
	var camera = $Camera2D
	if not camera:
		print("Warning: Camera2D not found on player")
		return
	
	# Try to get world dimensions from TilesetGenerator
	var tileset_generator = get_parent().get_node_or_null("TileMap")
	
	var world_width_tiles = 66  # Default fallback
	var world_height_tiles = 16  # Default fallback
	var tile_size = 32
	
	if tileset_generator and tileset_generator is TilesetGenerator:
		# Get actual dimensions from the generator
		world_width_tiles = tileset_generator.scene_width_tiles
		world_height_tiles = tileset_generator.scene_height_tiles
		tile_size = tileset_generator.tile_size
		print("Using world dimensions from TilesetGenerator: ", world_width_tiles, "x", world_height_tiles)
	else:
		print("Warning: Could not find TilesetGenerator, using default dimensions")
	
	# Calculate world boundaries in pixels
	# The world goes from x=-half_width to x=half_width-1 (or half_width for odd widths) in tile coordinates
	var half_width = int(world_width_tiles / 2)
	var min_x_tiles = -half_width
	var max_x_tiles = half_width - 1 if world_width_tiles % 2 == 0 else half_width
	
	# Convert to world coordinates (pixels)
	# The tilemap uses map_to_local which centers tiles, so we need to account for that
	var world_left = min_x_tiles * tile_size
	var world_right = (max_x_tiles + 1) * tile_size
	var world_top = -(world_height_tiles - 1) * tile_size
	var world_bottom = (world_height_tiles - 1) * tile_size
	
	# Set camera limits to the world boundaries
	camera.limit_left = world_left
	camera.limit_right = world_right
	camera.limit_top = world_top
	camera.limit_bottom = world_bottom
	
	# Enable camera smoothing for better feel
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Reset smoothing to snap camera to player position immediately
	# This prevents the camera from smoothly transitioning from (0,0) on initial load
	camera.reset_smoothing()
	
	print("Camera limits set: left=", world_left, " right=", world_right, " top=", world_top, " bottom=", world_bottom)

func _physics_process(delta):
	# Handle flying mode differently
	if flying_mode:
		_handle_flying_mode(delta)
		return
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# Update coyote time - start timer when leaving ground without jumping
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer = COYOTE_TIME
	
	# Update jump buffer - remember jump input
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
		# Emit first movement signal
		if not has_moved:
			has_moved = true
			emit_signal("first_movement")
	
	# Handle jump with coyote time and buffer
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
		if _jump_sfx and _jump_sfx.stream:
			_jump_sfx.stop()
			_jump_sfx.play()
	
	# Get input direction for horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		# Emit first movement signal
		if not has_moved:
			has_moved = true
			emit_signal("first_movement")
		# Use acceleration for smoother movement
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		# Flip sprite based on direction
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		# Use friction for smoother stopping
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	# Handle animations based on player state (normal mode)
	if not is_on_floor():
		# Player is in the air - jumping/falling
		if $AnimatedSprite2D.animation != "agent_jumping":
			$AnimatedSprite2D.play("agent_jumping")
	elif abs(velocity.x) > 10:
		# Player is moving on the ground
		if $AnimatedSprite2D.animation != "agent_walking":
			$AnimatedSprite2D.play("agent_walking")
	else:
		# Player is idle on the ground
		if $AnimatedSprite2D.animation != "agent_idle":
			$AnimatedSprite2D.play("agent_idle")
		
	# Update timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Store floor state for next frame
	was_on_floor = is_on_floor()
	
	move_and_slide()


func _init_sfx() -> void:
	var j := _load_first_existing(_JUMP_PATHS)
	if j:
		_jump_sfx = AudioStreamPlayer.new()
		_jump_sfx.name = "JumpSFX"
		_jump_sfx.stream = j
		_jump_sfx.volume_db = jump_volume_db
		add_child(_jump_sfx)

	var f := _load_first_existing(_FLY_PATHS)
	if f:
		_fly_sfx = AudioStreamPlayer.new()
		_fly_sfx.name = "FlySFX"
		_fly_sfx.stream = f
		_fly_sfx.volume_db = fly_volume_db
		add_child(_fly_sfx)

func start_fly_sfx() -> void:
	if _fly_sfx and _fly_sfx.stream and not _fly_sfx.playing:
		_fly_sfx.play()

func stop_fly_sfx() -> void:
	if _fly_sfx and _fly_sfx.playing:
		_fly_sfx.stop()

func _load_first_existing(paths: Array) -> AudioStream:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func set_flying_mode(enabled: bool) -> void:
	"""Enable or disable flying mode"""
	flying_mode = enabled
	is_hovering = false
	
	if flying_mode:
		print(">>> Flying mode ENABLED <<<")
		# Reset velocity when entering flying mode
		velocity = Vector2.ZERO
	else:
		print(">>> Flying mode DISABLED <<<")

func _handle_flying_mode(delta: float) -> void:
	"""Handle movement and physics when in flying mode"""
	
	# Handle spacebar for vertical boost
	if Input.is_action_just_pressed("ui_accept"):
		# Apply upward velocity boost equal to regular jump height
		velocity.y = JUMP_VELOCITY
		
		# Emit first movement signal
		if not has_moved:
			has_moved = true
			emit_signal("first_movement")
		
		# Play fly sound effect
		if _fly_sfx and _fly_sfx.stream:
			_fly_sfx.play()
	
	# Handle arrow key vertical movement
	var vertical_direction = Input.get_axis("ui_up", "ui_down")
	if vertical_direction != 0:
		velocity.y = move_toward(velocity.y, vertical_direction * FLYING_SPEED, FLYING_ACCELERATION * delta)
		
		# Emit first movement signal
		if not has_moved:
			has_moved = true
			emit_signal("first_movement")
		
		# Play fly sound when first moving vertically
		if _fly_sfx and _fly_sfx.stream and not _fly_sfx.playing:
			_fly_sfx.play()
	else:
		# Apply friction when not pressing any vertical keys
		velocity.y = move_toward(velocity.y, 0, FLYING_FRICTION * delta)
	
	# Handle horizontal movement
	var horizontal_direction = Input.get_axis("ui_left", "ui_right")
	if horizontal_direction != 0:
		velocity.x = move_toward(velocity.x, horizontal_direction * FLYING_SPEED, FLYING_ACCELERATION * delta)
		
		# Flip sprite based on direction
		$AnimatedSprite2D.flip_h = horizontal_direction < 0
		
		# Emit first movement signal
		if not has_moved:
			has_moved = true
			emit_signal("first_movement")
	else:
		velocity.x = move_toward(velocity.x, 0, FLYING_FRICTION * delta)
	
	# Handle flying animations
	_handle_flying_animations()
	
	move_and_slide()

func _handle_flying_animations() -> void:
	"""Handle animations when in flying mode"""
	# Priority: vertical movement > horizontal movement > idle
	if abs(velocity.y) > 10:
		# Flying/hovering vertically
		if $AnimatedSprite2D.animation != "jetpack_flying":
			$AnimatedSprite2D.play("jetpack_flying")
	elif abs(velocity.x) > 10:
		# Moving horizontally
		if $AnimatedSprite2D.animation != "jetpack_walking":
			$AnimatedSprite2D.play("jetpack_walking")
	else:
		# Idle in the air
		if $AnimatedSprite2D.animation != "jetpack_idle":
			$AnimatedSprite2D.play("jetpack_idle")
