extends AudioStreamPlayer

const FADEOUT_TIME = 5.0

var preview_start: float
var preview_end: float
var base_volume_db: float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_base_volume(db):
	base_volume_db = db
	volume_db = db
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if playing:
		if get_playback_position() >= preview_end and not $FadeTween.is_active():
			$FadeTween.interpolate_method(self, "set_linear_volume", db2linear(base_volume_db), 0.0,
										FADEOUT_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$FadeTween.start()
			
			
func set_linear_volume(linear_volume: float):
	volume_db = linear2db(linear_volume)
	

func start_preview(audio_path: String, song_data: Dictionary):
	stream = load(audio_path)
	if stream != null:
		preview_start = 0.0
		preview_end = stream.get_length() - FADEOUT_TIME
		if song_data.has("preview_start"):
			preview_start = song_data["preview_start"]
		if song_data.has("preview_end"):
			preview_end = song_data["preview_end"]
		$FadeTween.remove_all()
		$ResetTimer.stop()
		volume_db = base_volume_db
		play(preview_start)

func _on_FadeTween_tween_completed(object, key):
	volume_db = linear2db(0.0)
	stop()
	$FadeTween.stop_all()
	$FadeTween.remove_all()
	$ResetTimer.start(1.0)


func _on_ResetTimer_timeout():
	volume_db = base_volume_db
	play(preview_start)
