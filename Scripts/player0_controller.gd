extends CharacterBody2D

# Movement variables
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 2000.0
const FRICTION = 2000.0
const COYOTE_TIME = 0.1
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
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get input direction for horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	print(direction)
	
	if direction != 0:
		velocity.x = direction * SPEED
		# Flip sprite based on direction
		$AnimatedSprite2D.flip_h = direction < 0
		# TODO: dif. sprite when it's still.
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
