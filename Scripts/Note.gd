extends Spatial
class_name Note

var time: float
var lane: int
var chart_position: float

const early_perfect_plus: float = 0.025
const late_perfect_plus: float = 0.025
const early_perfect: float = 0.050
const late_perfect: float = 0.050
const early_great: float = 0.100
const late_great: float = 0.100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func can_judge(event_time: float):
	return event_time >= time-early_great && event_time <= time + late_great

# returns either null, or a tuple containing [judgement type, offset]
func judge(event_time: float):
	if event_time >= time-early_perfect_plus && event_time <= time + late_perfect_plus:
		return [0, event_time - time]
	if event_time >= time-early_perfect && event_time <= time + late_perfect:
		return [1, event_time - time]
	elif event_time >= time-early_great && event_time <= time + late_great:
		return [2, event_time - time]

func _render(chart_position: float, lane_depth: float, base_note_screen_time: float):
	pass
