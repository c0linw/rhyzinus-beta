extends NoteHold
class_name NoteHoldSide

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("holds")
	if lane == 0:
		rotate_z(-PI/2)
	elif lane == 7:
		rotate_z(PI/2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	var head: float = chart_position
	var tail: float
	if end_position <= song_chart_position + base_note_screen_time:
		tail = end_position
	else:
		tail = song_chart_position + base_note_screen_time
		
	if held:
		head = song_chart_position
		$Body.get_surface_material(0).albedo_color = Color(1,0.93,0,0.7)
	else:
		$Body.get_surface_material(0).albedo_color = Color(1,0.93,0,0.5)
		
	if lane == 0:
		translation = Vector3(0,0.625,-lane_depth*(head-song_chart_position)/base_note_screen_time)
	elif lane == 7:
		translation = Vector3(6,0.625,-lane_depth*(head-song_chart_position)/base_note_screen_time)
	$Body.scale = Vector3($Body.scale.x, $Body.scale.y, lane_depth*(tail - head)/base_note_screen_time)
	$Body.translation = Vector3(0,0,-$Body.scale.z/2.0)
