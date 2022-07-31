extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var result_data: Dictionary
var score: int

# Called when the node enters the scene tree for the first time.
func _ready():
	$MarginContainer/NoteCounts.set_results(SceneSwitcher.get_param("result_data"))
	$MarginContainer2/SongScore.set_score(SceneSwitcher.get_param("score"))
	$MarginContainer2/SongScore.set_song_name(SceneSwitcher.get_param("song_title"))
	$MarginContainer2/SongScore.set_song_difficulty(SceneSwitcher.get_param("difficulty"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
