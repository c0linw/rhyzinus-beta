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
		$MarginContainer2/SongScore.set_score(score)
		
	var song_title = SceneSwitcher.get_param("song_title")
	if song_title:
		$MarginContainer2/SongScore.set_song_name(song_title)
		
	var difficulty = SceneSwitcher.get_param("difficulty")
	if difficulty:
		$MarginContainer2/SongScore.set_song_difficulty(difficulty)
		
	var jacket_path = SceneSwitcher.get_param("jacket_path")
	if jacket_path:
		$MarginContainer2/SongScore.set_song_jacket(jacket_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_RetryButton_pressed():
	pass # Replace with function body.


func _on_SongSelectButton_pressed():
	SceneSwitcher.change_scene("res://scenes/song_select/song_select.tscn")
