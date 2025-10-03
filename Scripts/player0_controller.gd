extends CharacterBody2D

# Movement variables
const SPEED = 200.0
const JUMP_VELOCITY = -600.0
const ACCELERATION = 2000.0
const FRICTION = 2000.0
const COYOTE_TIME = 0.1 # coyote timer is a nice little buffer when the player jumps to make it easier to not fall
#i guess this stuff is standard for platformers according to several tutorials?
const JUMP_BUFFER_TIME = 0.1

# Movement state
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Player position is now set dynamically by TilesetGenerator.gd
	# Wait a frame for the scene tree to be fully ready before setting up camera
	call_deferred("setup_camera_limits")

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
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# Update coyote time - start timer when leaving ground without jumping
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer = COYOTE_TIME
	
	# Update jump buffer - remember jump input
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	
	# Handle jump with coyote time and buffer
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	
	# Get input direction for horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		# Use acceleration for smoother movement
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		# Flip sprite based on direction
		$AnimatedSprite2D.flip_h = direction < 0
		# TODO: dif. animation when it's still vs moving (maybe vs jumping)
	else:
		# Use friction for smoother stopping
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
	# Update timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Store floor state for next frame
	was_on_floor = is_on_floor()
	
	move_and_slide()
