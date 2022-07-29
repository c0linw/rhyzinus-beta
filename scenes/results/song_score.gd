extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_song_name(name: String):
	find_node("SongName").text = name
	
func set_song_difficulty(diff: int):
	find_node("SongDifficulty").text = str(diff)
	
func set_score(score: int):
	find_node("SongScore").text = str(score)
