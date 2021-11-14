extends Note


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if lane == 0:
		rotate_z(-PI/2)
	elif lane == 7:
		rotate_z(PI/2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	if lane == 0:
		translation = Vector3(0,0.625,-lane_depth*(chart_position-song_chart_position)/base_note_screen_time)
	elif lane == 7:
		translation = Vector3(6,0.625,-lane_depth*(chart_position-song_chart_position)/base_note_screen_time)
