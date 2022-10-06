extends Node

var bpm

var custom_stream: ShinobuSoundPlayer


# Tracking the beat and song position
var time_begin: float
var time_delay: float
var last_paused: float

var song_position: float = 0.0
var paused_position: float = 0.0
var beat_data: Array = []


var played_sfxs: Array = [] # manually free these when each one is done

var finish_signal_sent: bool = false
signal finished()

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
	
func _process(delta):
	for sfx_player in played_sfxs.duplicate():
		if sfx_player.is_at_stream_end():
			sfx_player.queue_free()
			played_sfxs.erase(sfx_player)
	if custom_stream != null and custom_stream.is_at_stream_end() and not finish_signal_sent:
		emit_signal("finished")
		finish_signal_sent = true
			
func load_audio(path: String) -> int:
	# shinobu audio will literally try to load any file, so at least check the filetype (maybe try header check when i have more time)
	if not (path.ends_with(".mp3") or path.ends_with(".wav") or path.ends_with(".ogg")):
		return FAILED
		
	unload_audio()
	
	var file = File.new()
	var err = file.open(path, File.READ)
	if err != OK:
		return err
	var buffer = file.get_buffer(file.get_len())
	file.close()
	var sound_source := Shinobu.register_sound_from_memory("music", buffer)
	custom_stream = sound_source.instantiate(ShinobuGlobals.music_group)
	custom_stream.looping_enabled = false
	add_child(custom_stream)

	song_position = 0.0
	paused_position = 0.0
	seek(song_position)
	#emit_signal("audio_loaded", get_stream_length())
	#emit_signal("song_position_updated", song_position, get_stream_length())
	
	return OK
	
func unload_audio():
	if custom_stream != null:
		custom_stream.queue_free()
		remove_child(custom_stream)
		custom_stream = null


func play_from_position(from_position: float):
	if custom_stream != null:
		seek(from_position)
		song_position = from_position
		var err = custom_stream.start()
		if err != OK:
			print(err)
			
func stop():
	if custom_stream != null:
		var err = custom_stream.stop()
		if err != OK:
			print(err)
		song_position = 0.0

func pause():
	if custom_stream != null:
		custom_stream.stop()

func update_song_position():
	if custom_stream != null and custom_stream.is_playing() and not custom_stream.is_at_stream_end():
		var new_position = get_playback_position() - Shinobu.get_actual_buffer_size() / 1000.0
		if new_position > song_position:
			song_position = new_position
			#emit_signal("song_position_updated", song_position, get_stream_length())


func seek(to_position: float):
	if custom_stream == null:
		return
	var previously_playing = custom_stream.is_playing()
	var new_position_ms = to_position * 1000
	var err = custom_stream.seek(new_position_ms)
	if err != OK:
		print(err)
	song_position = to_position
	
	if previously_playing:
		custom_stream.start()
	
	if custom_stream.is_at_stream_end() and not finish_signal_sent:
		emit_signal("finished")
		finish_signal_sent = true
	else:
		finish_signal_sent = false
		
func get_playback_position() -> float:
	if custom_stream == null:
		return 0.0
	return (custom_stream.get_playback_position_msec() - Shinobu.get_actual_buffer_size()) / 1000.0

func get_stream_length() -> float:
	if custom_stream == null:
		return 0.0
	return custom_stream.get_length_msec() / 1000.0
	
func is_playing() -> bool:
	if custom_stream == null:
		return false
	return custom_stream.is_playing()


func play_sfx(sfx_enum_value: int):
	var sfx_source = ShinobuGlobals.sfx_sources[sfx_enum_value]
	if sfx_source != null:
		var sfx_player = sfx_source.instantiate(ShinobuGlobals.sfx_group)
		played_sfxs.append(sfx_player)
		sfx_player.start()
