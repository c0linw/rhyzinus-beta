extends Note
class_name NoteSwipe

# Declare member variables here. Examples:
var activated: bool = false
var start_position = null

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("swipes")


# returns either null, or a dict containing the judgement and offset
func judge(event_time: float):
	pass # swipe judgement is performed in game.gd's process() instead

func can_judge(event_time: float):
	return not activated and event_time >= time-early_cracked and event_time <= time+late_cracked

func render(song_chart_position: float, lane_depth: float, base_note_screen_time: float):
	if lane > 0 && lane < 7:
		translation = Vector3(lane-0.5,0,-lane_depth*(chart_position-song_chart_position)/base_note_screen_time)
