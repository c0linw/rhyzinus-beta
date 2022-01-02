extends Control


var note_speed: float = 5.0
var audio_offset: int = 0
var input_offset: int = 0
var volume: float = 1.0

signal note_speed_changed(new_speed)
signal audio_offset_changed(new_offset)
signal input_offset_changed(new_offset)
signal volume_changed(new_volume)

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: load from persistent settings file
	emit_signal("note_speed_changed", note_speed)
	emit_signal("audio_offset_changed", audio_offset)
	emit_signal("input_offset_changed", input_offset)
	emit_signal("volume_changed", volume)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_NoteSpeedDecrement_pressed():
	if note_speed <= 1.0:
		note_speed = 1.0
	else:
		note_speed = stepify(note_speed - 0.1, 0.1)
		emit_signal("note_speed_changed", note_speed)


func _on_NoteSpeedIncrement_pressed():
	if note_speed >= 10.0:
		note_speed = 10.0
	else:
		note_speed = stepify(note_speed + 0.1, 0.1)
		emit_signal("note_speed_changed", note_speed)
