extends Control


var grade_cutoffs: Dictionary = {
	1000000: "r_plus_rainbow",
	995000: "r_plus",
	990000: "r",
	960000: "a",
	900000: "b",
	800000: "c",
	0: "d"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	var result_data = SceneSwitcher.get_param("result_data")
	if result_data:
		$MarginContainer/NoteCounts.set_results(result_data)
		
	var score = SceneSwitcher.get_param("score")
	if score:
		$MarginContainer2/SongScore.set_score(score)
		$MarginContainer/NoteCounts.set_grade(calculate_grade(score))
		
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

func calculate_grade(score: int):
	print(grade_cutoffs.keys())
	for cutoff in grade_cutoffs.keys():
		if score >= cutoff:
			return grade_cutoffs[cutoff]
	return "d"

func _on_RetryButton_pressed():
	pass # Replace with function body.


func _on_SongSelectButton_pressed():
	SceneSwitcher.change_scene("res://scenes/song_select/song_select.tscn")
