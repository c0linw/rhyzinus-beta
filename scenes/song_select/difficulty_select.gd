extends TextureButton

enum {ALPHA, BETA, GAMMA, DELTA}

export var difficulty: int = ALPHA

var difficulty_names: Array = ["Alpha", "Beta", "Gamma", "Delta"]
var level_number: int = 0

var orig_min_size: Vector2
var expanded_min_size: Vector2
var orig_font_size: int
var expanded_font_size: int

signal difficulty_selected(difficulty)

# Called when the node enters the scene tree for the first time.
func _ready():
	$MarginContainer/Label.text = difficulty_names[difficulty] + " " + str(level_number)
	orig_min_size = self.rect_min_size
	expanded_min_size = orig_min_size * 1.33
	orig_font_size = $MarginContainer/Label.get_font("font").size
	expanded_font_size = orig_font_size * 1.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DifficultyButton_pressed():
	emit_signal("difficulty_selected", difficulty)


func _on_SongSelect_song_selected(song_data: Dictionary):
	$MarginContainer/Label.text = difficulty_names[difficulty] + " " + str(song_data.levels[difficulty])
		
func _on_SongSelect_difficulty_set(signal_difficulty):
	if signal_difficulty == difficulty:
		self.rect_min_size = expanded_min_size
		$MarginContainer/Label.get_font("font").size = expanded_font_size
	if signal_difficulty != difficulty:
		self.rect_min_size = orig_min_size
		$MarginContainer/Label.get_font("font").size = orig_font_size
