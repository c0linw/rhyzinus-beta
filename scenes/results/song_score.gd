extends MarginContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_song_name(name: String):
	find_node("SongName").text = name
	
func set_song_difficulty(diffname: String):
	find_node("SongDifficulty").text = diffname
	
func set_score(score: int):
	find_node("SongScore").text = "Score: " + str(score)

func set_song_jacket(jacket_path: String):
	print("set_song_jacket called! jacket_path = ", jacket_path)
	find_node("SongJacket").texture = load(jacket_path)
