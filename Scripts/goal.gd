extends Area2D

# Size of the rectangle (matches CollisionShape2D extents * 2)
const RECT_SIZE = Vector2(32, 48)
const RECT_COLOR = Color(1.0, 0, 0.0, 1) # Yellow

func _draw():
	draw_rect(Rect2(-RECT_SIZE/2, RECT_SIZE), RECT_COLOR)
	
func _ready():
	#update()
	pass
