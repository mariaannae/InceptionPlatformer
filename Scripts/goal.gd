extends Area2D

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
	
	# Connect the body_entered signal directly as a backup
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	
	print("Goal initialized at position: ", global_position)

func _on_body_entered(body: Node2D) -> void:
	# Debug print to verify signal is firing
	print("Goal detected body: ", body.name, " at ", body.global_position)
	
	# Check if it's the player
	var is_player = body.name == "Player" or body.is_in_group("player")
	if is_player:
		print("SUCCESS! Player reached the goal!")
