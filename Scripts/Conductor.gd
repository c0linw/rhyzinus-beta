extends AudioStreamPlayer

var bpm

# Tracking the beat and song position
var time_begin: float
var time_delay: float

var song_position: float = 0.0
var song_position_in_beats = 1
var sec_per_beat
var last_reported_beat = 0
var beats_before_start = 0
var song_offset = 0
var audio_offset = 0
var timing_points: Array = []

# Determining how close to the beat an event is
var closest = 0
var time_off_beat = 0.0


func _ready():
	pass
	
func set_bpm(num):
	bpm = num
	sec_per_beat = 60.0 / bpm

#func _process(_delta):
#	update_song_position()


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
