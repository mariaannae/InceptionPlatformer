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
	pass
	# position = Vector2(32 * 2, 0)



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
