extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var result_data
var score

# Called when the node enters the scene tree for the first time.
func _ready():
	result_data = SceneSwitcher.get_param("result_data")
	if result_data:
		$MarginContainer/NoteCounts.set_results(result_data)
		
	score = SceneSwitcher.get_param("score")
	if score:
		$MarginContainer2/SongScore.set_score()
		
	var song_title = SceneSwitcher.get_param("song_title")
	if song_title:
		$MarginContainer2/SongScore.set_song_name(song_title)
		
	var difficulty = SceneSwitcher.get_param("difficulty")
	if difficulty:
		$MarginContainer2/SongScore.set_song_difficulty(difficulty)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
