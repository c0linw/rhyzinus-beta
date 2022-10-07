extends Node
class_name AudioStreamPlayerShinobu

var stream: ShinobuSoundPlayer
var song_position: float = 0.0
var paused_position: float = 0.0

var finish_signal_sent: bool = false
signal finished()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

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
	stream = sound_source.instantiate(ShinobuGlobals.music_group)
	stream.looping_enabled = false
	add_child(stream)

	song_position = 0.0
	paused_position = 0.0
	seek(song_position)
	#emit_signal("audio_loaded", get_stream_length())
	#emit_signal("song_position_updated", song_position, get_stream_length())
	
	return OK
	
func unload_audio():
	if stream != null:
		stream.queue_free()
		remove_child(stream)
		stream = null


func play_from_position(from_position: float):
	if stream != null:
		seek(from_position)
		song_position = from_position
		var err = stream.start()
		if err != OK:
			print(err)
			
func stop():
	if stream != null:
		var err = stream.stop()
		if err != OK:
			print(err)
		song_position = 0.0

func pause():
	if stream != null:
		stream.stop()

func update_song_position():
	if stream != null and stream.is_playing() and not stream.is_at_stream_end():
		var new_position = get_playback_position() - Shinobu.get_actual_buffer_size() / 1000.0
		if new_position > song_position:
			song_position = new_position
			#emit_signal("song_position_updated", song_position, get_stream_length())


func seek(to_position: float):
	if stream == null:
		return
	var previously_playing = stream.is_playing()
	var new_position_ms = to_position * 1000
	var err = stream.seek(new_position_ms)
	if err != OK:
		print(err)
	song_position = to_position
	
	if previously_playing:
		stream.start()
	
	if stream.is_at_stream_end() and not finish_signal_sent:
		emit_signal("finished")
		finish_signal_sent = true
	else:
		finish_signal_sent = false
		
func get_playback_position() -> float:
	if stream == null:
		return 0.0
	return (stream.get_playback_position_msec() - Shinobu.get_actual_buffer_size()) / 1000.0

func get_stream_length() -> float:
	if stream == null:
		return 0.0
	return stream.get_length_msec() / 1000.0
	
func is_playing() -> bool:
	if stream == null:
		return false
	return stream.is_playing()
