extends TextureButton

enum {ALPHA, BETA, GAMMA, DELTA}

export var difficulty: int = ALPHA

var difficulty_names: Array = ["Alpha", "Beta", "Gamma", "Delta"]
var anim_names: Array = ["glow_green", "glow_orange", "glow_red", "glow_purple"]
var diff_colors: Array = [Color(0.31, 1, 0.31), Color(1, 0.67, 0.125), Color(1, 0.25, 0.25), Color(0.78, 0.25, 1)]
var level_number: int = 0 # the displayed rating number, e.g. the "12" in "Delta 12"

signal difficulty_selected(difficulty)

# Called when the node enters the scene tree for the first time.
func _ready():
	$MarginContainer/Label.add_color_override("font_color", diff_colors[difficulty])
	$MarginContainer/Label.text = str(level_number)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DifficultyButton_pressed():
	emit_signal("difficulty_selected", difficulty)

func _on_SongSelect_song_selected(song_data: Dictionary):
	level_number = song_data.levels[difficulty]
	$MarginContainer/Label.text = str(level_number)
		
func _on_SongSelect_difficulty_set(signal_difficulty):
	if signal_difficulty == difficulty and $AnimationPlayer.current_animation != anim_names[difficulty]:
		$AnimationPlayer.play(anim_names[difficulty])
	if signal_difficulty != difficulty:
		$AnimationPlayer.play("glow_none")
