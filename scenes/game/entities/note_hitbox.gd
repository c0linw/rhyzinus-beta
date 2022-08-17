extends Node2D
class_name NoteHitbox

var area: Rect2
var center: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#func _draw():
	#draw_rect(Rect2(get_center() - Vector2(4,4), Vector2(8,8)), Color.green)

func set_points(upper_left: Vector2, lower_right: Vector2, center_point: Vector2):
	area.position = upper_left
	area.end = lower_right
	area.abs()
	
	center = center_point
	
	$ReferenceRect.set_position(area.position)
	$ReferenceRect.set_size(area.end - area.position)
	
	$ColorRect.set_position(center_point)

func get_center() -> Vector2:
	return center
