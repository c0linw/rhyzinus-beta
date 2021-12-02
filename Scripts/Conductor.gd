extends AudioStreamPlayer

var bpm

# Tracking the beat and song position
var time_begin: float
var time_delay: float

var song_position: float = 0.0
var song_position_in_beats = 0
var sec_per_beat = 0
var last_reported_beat = 0
var beats_before_start = 0
var song_offset = 0
var audio_offset = 0
var beat_data: Array = []

# Determining how close to the beat an event is
var closest = 0
var time_off_beat = 0.0

class TimeSorter:
	# denotes the order in which these should be sorted, if there are objects with the same time
	const type_enum: Dictionary = {
		"bpm": 0, 
		"velocity": 1,
		"barline": 2,
		"tap": 3,
		"hold_start": 3,
		"hold_end": 3,
		"hold": 3
	}
	
	static func sort_ascending(a: Dictionary, b: Dictionary) -> bool:
		return a["time"] < b["time"]
		
	# use this after adding the timing points and notes into one array
	static func sort_ascending_with_type_priority(a: Dictionary, b: Dictionary) -> bool:
		if a["time"] < b["time"]:
			return true
		elif a["time"] == b["time"]:
			return type_enum[a["type"]] < type_enum[b["type"]]
		else:
			return false

func _ready():
	pass
	
func set_bpm(num: float):
	bpm = num
	sec_per_beat = 60.0 / bpm
	
func set_beat_length(num: float):
	sec_per_beat = num
	bpm = (60.0 / num)

# func _process(_delta):

func play_with_offset(offset: float):
	#$StartTimer.wait_time = offset
	audio_offset = offset
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	#$StartTimer.start()
	

func closest_beat(nth):
	closest = int(round((song_position / sec_per_beat) / nth) * nth) 
	time_off_beat = abs(closest * sec_per_beat - song_position)
	return Vector2(closest, time_off_beat)


func play_from_beat(beat, offset):
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	play()
	seek(beat * sec_per_beat)

func _on_StartTimer_timeout():
	play()
	$StartTimer.stop()

func update_song_position():
	var time = (OS.get_ticks_usec() - time_begin) / 1000000.0
	# Compensate for latency.
	time -= time_delay
	song_position = max(0, time)
#		var new_position = get_playback_position() + AudioServer.get_time_since_last_mix()
#		new_position -= AudioServer.get_output_latency()
#		if new_position > song_position:
#			song_position = new_position
#		song_position_in_beats = int(floor(song_position / sec_per_beat)) + beats_before_start
