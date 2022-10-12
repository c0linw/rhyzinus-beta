extends AudioStreamPlayerShinobu

const FADEOUT_TIME = 5.0

var preview_start: float
var preview_end: float

signal song_stream_loaded(audioplayer)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if stream != null and stream.is_playing():
		if get_playback_position() >= preview_end and not $FadeTween.is_active():
			$FadeTween.interpolate_method(self, "set_volume", 1.0, 0.0,
										FADEOUT_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$FadeTween.start()


func start_preview(audio_path: String, song_data: Dictionary):
	load_audio(audio_path)
	if stream != null:
		emit_signal("song_stream_loaded", self)
		preview_start = 0.0
		preview_end = get_stream_length() - FADEOUT_TIME
		if song_data.has("preview_start"):
			preview_start = song_data["preview_start"]
		if song_data.has("preview_end"):
			preview_end = song_data["preview_end"]
		$FadeTween.remove_all()
		$ResetTimer.stop()
		set_volume(1.0)
		play_from_position(preview_start)

func _on_FadeTween_tween_completed(object, key):
	set_volume(0)
	stop()
	$FadeTween.stop_all()
	$FadeTween.remove_all()
	$ResetTimer.start(1.0)


func _on_ResetTimer_timeout():
	set_volume(1.0)
	play_from_position(preview_start)
