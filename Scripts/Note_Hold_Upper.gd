extends Note
class_name NoteHoldUpper

var end_time: float
var end_position: float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	if lane > 9:
		translation = Vector3((lane-10)*1.5+0.75,0,-lane_depth*(chart_position-song_chart_position)/base_note_screen_time)
		if end_position <= song_chart_position + base_note_screen_time:
			$Body.scale = Vector3($Body.scale.x, $Body.scale.y, lane_depth*(end_position-chart_position)/base_note_screen_time)
		else:
			$Body.scale = Vector3($Body.scale.x, $Body.scale.y, lane_depth*(song_chart_position+base_note_screen_time-chart_position)/base_note_screen_time)
	$Body.translation = Vector3(0,0,-$Body.scale.z/2.0)
