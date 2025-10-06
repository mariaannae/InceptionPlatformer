extends Area2D

var debug_mode = true  # Toggle this to see visual debugging
var collision_shape: CollisionShape2D

func _ready():
	# Ensure monitoring is enabled for collision detection
	monitoring = true
	monitorable = true
	
	# Ensure we're on the right collision layers
	# Layer 1 is typically for game objects
	collision_layer = 1
	collision_mask = 1
	
	# Add to goal group so UILayer can find us
	add_to_group("goal")
	
	# Get reference to collision shape for debugging
	collision_shape = $CollisionShape2D
	if collision_shape and debug_mode:
		collision_shape.visible = true  # Show collision shape outline
	
	# Connect the body_entered signal directly as a backup
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	
	print("Goal initialized at position: ", global_position)
	print("  Monitoring enabled: ", monitoring)
	print("  Monitorable: ", monitorable)
	print("  Collision layer: ", collision_layer)
	print("  Collision mask: ", collision_mask)
	if collision_shape and collision_shape.shape:
		var rect_shape = collision_shape.shape as RectangleShape2D
		if rect_shape:
			print("  Collision box size: ", rect_shape.size)
			print("  Collision box offset: ", collision_shape.position)

func _on_body_entered(body: Node2D) -> void:
	# Calculate distance for more precise debugging
	var distance = global_position.distance_to(body.global_position)
	
	# Debug print with distance information
	print("Goal detected body: ", body.name, " at ", body.global_position)
	print("  Distance from goal center: ", distance)
	print("  Body collision layer: ", body.get("collision_layer") if body.get("collision_layer") != null else "N/A")
	
	# Check if it's the player
	var is_player = body.name == "Player" or body.is_in_group("player")
	if is_player:
		print("SUCCESS! Player reached the goal!")
		
		# Additional debug info for player collision
		if collision_shape and collision_shape.shape:
			var rect_shape = collision_shape.shape as RectangleShape2D
			if rect_shape:
				var half_extents = rect_shape.size / 2
				var goal_rect = Rect2(global_position - half_extents + collision_shape.position, rect_shape.size)
				print("  Goal rect: ", goal_rect)
				print("  Player position: ", body.global_position)

func _physics_process(_delta):
	# Extra debugging to continuously check for overlapping bodies
	if debug_mode:
		var overlapping_bodies = get_overlapping_bodies()
		if overlapping_bodies.size() > 0:
			for body in overlapping_bodies:
				print("Overlapping with: ", body.name)
