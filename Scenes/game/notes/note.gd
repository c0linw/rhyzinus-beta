extends Spatial
class_name Note

var time: float
var lane: int
var chart_position: float

const early_flawless: float = 0.025
const late_flawless: float = 0.025
const early_decrypted: float = 0.050
const late_decrypted: float = 0.050
const early_cracked: float = 0.100
const late_cracked: float = 0.100

enum {ENCRYPTED, CRACKED, DECRYPTED, FLAWLESS}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func can_judge(event_time: float):
	return event_time >= time-early_cracked && event_time <= time + late_cracked

# returns a dict containing the judgement and offset
func judge(event_time: float):
	if event_time >= time-early_flawless && event_time <= time + late_flawless:
		return {"judgement": FLAWLESS, "offset": event_time - time}
	if event_time >= time-early_decrypted && event_time <= time + late_decrypted:
		return {"judgement": DECRYPTED, "offset": event_time - time}
	elif event_time >= time-early_cracked && event_time <= time + late_cracked:
		return {"judgement": CRACKED, "offset": event_time - time}
	else:
		return null

func _render(chart_position: float, lane_depth: float, base_note_screen_time: float):
	pass
