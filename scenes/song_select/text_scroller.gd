extends ScrollContainer

const PIXELS_PER_SECOND: float = 48.0

# Called when the node enters the scene tree for the first time.
func _ready():
	yield(get_tree(), "idle_frame")
	if $SongName.rect_size.x - rect_size.x > 0:
		start_tween()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func start_tween():
	$Tween.interpolate_property(self, "scroll_horizontal", 
		0, $SongName.rect_size.x - rect_size.x, 
		($SongName.rect_size.x - rect_size.x) / PIXELS_PER_SECOND,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 2.0)
	$Tween.start()

func _on_Timer_timeout():
	scroll_horizontal = 0
	start_tween()


func _on_Tween_tween_completed(object, key):
	$Tween.stop_all()
	$Timer.start(2.0)
