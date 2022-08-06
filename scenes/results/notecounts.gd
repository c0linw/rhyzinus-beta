extends MarginContainer

enum {CORRUPTED, CRACKED, DECRYPTED, FLAWLESS}

var grade_textures: Dictionary = {
	"r_plus_rainbow": preload("res://textures/result/score_rank_r_plus_rainbow.png"),
	"r_plus": preload("res://textures/result/score_rank_r_plus_blue.png"),
	"r": preload("res://textures/result/score_rank_r_blue.png"),
	"a": preload("res://textures/result/score_rank_a_blue.png"),
	"b": preload("res://textures/result/score_rank_b.png"),
	"c": preload("res://textures/result/score_rank_c.png"),
	"d": preload("res://textures/result/score_rank_d.png"),
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_results(result_data: Dictionary):
	find_node("FlawlessCount").text = str(len(result_data[FLAWLESS])) + " "
	find_node("DecryptedCount").text = str(len(result_data[DECRYPTED])) + " "
	find_node("CrackedCount").text = str(len(result_data[CRACKED])) + " "
	find_node("CorruptedCount").text = str(len(result_data[CORRUPTED])) + " "
	
	set_achievement(result_data)
	
func set_grade(grade: String):
	if grade_textures.has(grade):
		find_node("ScoreTexture").texture = grade_textures[grade]

func set_achievement(result_data: Dictionary):
	var achievement_text = "Clear"
	if len(result_data[CORRUPTED]) == 0:
		achievement_text = "Full Chain"
		if len(result_data[CRACKED]) == 0:
			achievement_text = "Full Decryption"
	find_node("AchievementLabel").text = achievement_text
