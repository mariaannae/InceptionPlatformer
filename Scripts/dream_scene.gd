extends Node2D

# Track flip state
var is_flipped: bool = false

func _ready():
	pass

func _input(event):
	# Toggle vertical flip when 'u' key is pressed
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_U:
			toggle_vertical_flip()

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
