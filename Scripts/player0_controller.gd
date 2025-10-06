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
@export var flying_auto_jump_delay: float = 1.2  # Delay in seconds before auto-jump in flying mode

# Movement state
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var has_moved: bool = false

# Flying mode state
var flying_mode: bool = false
var is_hovering: bool = false
var hover_target_y: float = 0.0
var flying_auto_jump_timer: float = 0.0
var flying_auto_jump_triggered: bool = false

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Add player to player group for identification
	add_to_group("player")
	
	# Ensure player is on the correct collision layer for goal detection
	collision_layer = 1  # Player is on layer 1
	collision_mask = 1   # Player can collide with layer 1 (for platforms/walls)
	
	print("Player collision setup - Layer: ", collision_layer, ", Mask: ", collision_mask)
	
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
	var sprite = $AnimatedSprite2D
	if not is_on_floor():
		# Player is in the air - jumping/falling
		if sprite.animation != "agent_jumping":
			sprite.play("agent_jumping")
			# Reset to default sprite offset for regular animations
			sprite.offset = Vector2(-16, -14)
	elif abs(velocity.x) > 10:
		# Player is moving on the ground
		if sprite.animation != "agent_walking":
			sprite.play("agent_walking")
			# Reset to default sprite offset for regular animations
			sprite.offset = Vector2(-16, -14)
	else:
		# Player is idle on the ground
		if sprite.animation != "agent_idle":
			sprite.play("agent_idle")
			# Reset to default sprite offset for regular animations
			sprite.offset = Vector2(-16, -14)
		
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
		print("Player position: ", position)
		
		# Immediately set jetpack idle animation with correct offset
		# This ensures the sprite is positioned correctly from the start
		var sprite = $AnimatedSprite2D
		sprite.play("jetpack_idle")
		# Apply offset adjustment for jetpack sprites to align feet with ground
		# Jetpack sprites appear significantly higher than regular sprites
		sprite.offset = Vector2(-16, 3)  # Move down more (from -14 to +3 = 17px down)
		
		# Adjust collision shape to match sprite offset change
		# The sprite moved down 17 pixels (from -14 to +3), so move collision shape down too
		var collision_shape = $CollisionShape2D
		collision_shape.position.y = 17  # Move collision shape down to match sprite
		
		# Reset velocity when entering flying mode
		velocity = Vector2.ZERO
		# Start auto-jump timer
		flying_auto_jump_timer = flying_auto_jump_delay
		flying_auto_jump_triggered = false
		print("Auto-jump will trigger in %.1f seconds" % flying_auto_jump_delay)
	else:
		print(">>> Flying mode DISABLED <<<")
		flying_auto_jump_timer = 0.0
		flying_auto_jump_triggered = false
		
		# Reset to regular idle animation with default offset when disabling flying mode
		var sprite = $AnimatedSprite2D
		sprite.play("agent_idle")
		sprite.offset = Vector2(-16, -14)  # Reset to default sprite offset
		
		# Reset collision shape position
		var collision_shape = $CollisionShape2D
		collision_shape.position.y = 0  # Reset collision shape to center

func reset_movement_flag() -> void:
	"""Reset the has_moved flag to allow first_movement signal to be emitted again"""
	has_moved = false
	print("Player movement flag reset")

func _adjust_position_to_ground() -> void:
	"""Adjust player position so their feet are exactly at ground level"""
	print("=== _adjust_position_to_ground called ===")
	print("Current position:", position)
	
	var tilemap = get_parent().get_node_or_null("TileMap")
	if not tilemap or not tilemap is TileMap:
		print("ERROR: Could not find TileMap for position adjustment")
		return
	
	# Get tilemap properties
	var tileset_generator = tilemap as TilesetGenerator
	if not tileset_generator:
		print("ERROR: TileMap is not a TilesetGenerator")
		return
	
	var scene_height_tiles = tileset_generator.scene_height_tiles
	var tile_size = tileset_generator.tile_size
	
	print("Scene height tiles:", scene_height_tiles, " Tile size:", tile_size)
	
	# Get player's current tile position
	var player_tile_pos = tilemap.local_to_map(position)
	print("Player tile position:", player_tile_pos)
	
	# Find the ground tile BELOW the player by searching downward
	var ground_y = null
	var tiles_checked = 0
	
	# Search from player position downward to find ground beneath them
	for y in range(player_tile_pos.y, scene_height_tiles):
		var tile_data = tilemap.get_cell_tile_data(0, Vector2i(player_tile_pos.x, y))
		if tile_data:
			tiles_checked += 1
			# Check if this tile has collision (is ground/platform/wall)
			var collision_count = tile_data.get_collision_polygons_count(0)
			if collision_count > 0:
				# Found ground tile below player
				ground_y = y
				print("Found ground tile BELOW player at Y:", y, " (checked ", tiles_checked, " tiles)")
				break
	
	if ground_y != null:
		# Calculate correct position so feet are at ground level
		# Player collision shape is 34px tall (17px below center to feet)
		# Tiles are 32px (16px from center to edge)
		var ground_tile_pos = tilemap.map_to_local(Vector2i(player_tile_pos.x, ground_y))
		print("Ground tile center position:", ground_tile_pos)
		
		var new_y = ground_tile_pos.y - 33  # 17 (collision half-height) + 16 (tile half-height)
		print("Calculated new Y position:", new_y, " (adjustment:", new_y - position.y, ")")
		
		position.y = new_y
		print("FINAL: Player adjusted to tile Y:", ground_y, " World Y:", position.y)
	else:
		print("ERROR: No ground found at X:", player_tile_pos.x, " after checking ", tiles_checked, " tiles")

func _handle_flying_mode(delta: float) -> void:
	"""Handle movement and physics when in flying mode"""
	
	# Handle auto-jump timer
	if not flying_auto_jump_triggered and flying_auto_jump_timer > 0.0:
		flying_auto_jump_timer -= delta
		if flying_auto_jump_timer <= 0.0:
			# Trigger automatic jump
			velocity.y = JUMP_VELOCITY
			flying_auto_jump_triggered = true
			print("Auto-jump triggered!")
			
			# Play fly sound effect
			if _fly_sfx and _fly_sfx.stream:
				_fly_sfx.play()
	
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
	# Apply offset adjustment for jetpack sprites to align feet with ground
	# Jetpack sprites appear significantly higher than regular sprites
	var sprite = $AnimatedSprite2D
	
	# Priority: vertical movement > horizontal movement > idle
	if abs(velocity.y) > 10:
		# Flying/hovering vertically
		if sprite.animation != "jetpack_flying":
			sprite.play("jetpack_flying")
			# Move jetpack sprite down significantly to align feet with ground
			sprite.offset = Vector2(-16, 3)  # Move down more (from -14 to +3 = 17px down)
	elif abs(velocity.x) > 10:
		# Moving horizontally
		if sprite.animation != "jetpack_walking":
			sprite.play("jetpack_walking")
			# Move jetpack sprite down significantly to align feet with ground
			sprite.offset = Vector2(-16, 3)  # Move down more (from -14 to +3 = 17px down)
	else:
		# Idle in the air
		if sprite.animation != "jetpack_idle":
			sprite.play("jetpack_idle")
			# Move jetpack sprite down significantly to align feet with ground
			sprite.offset = Vector2(-16, 3)  # Move down more (from -14 to +3 = 17px down)
