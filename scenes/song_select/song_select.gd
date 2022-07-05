extends Control

enum {ALPHA, BETA, GAMMA, DELTA}

var selected_difficulty: int = ALPHA

var song_folder: String = "res://songs/"
var diff_buttons: Array
var pack_name: String = "beta1"

var ObjSongListElement = preload("res://scenes/song_select/song_list_element.tscn")

signal difficulty_set(difficulty)
signal song_selected(song_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	var song_index = read_index(pack_name)
	var first_song = null
	if song_index != null:
		for song in song_index:
			var new_element = ObjSongListElement.instance()
			new_element.connect("song_selected", self, "_on_SongListElement_song_selected")
			new_element.connect("play_song", self, "_on_SongListElement_play_song")
			new_element.setup(song)
			$SongSelectScroll/VBoxContainer.add_child(new_element)
			if first_song == null:
				first_song = new_element
		
	var diff_buttons = [
		find_node("DiffAlpha"),
		find_node("DiffBeta"),
		find_node("DiffGamma"),
		find_node("DiffDelta"),
	]
	for node in diff_buttons:
		node.connect("difficulty_selected", self, "_on_DifficultyButton_difficulty_selected")
		self.connect("difficulty_set", node, "_on_SongSelect_difficulty_set")
		self.connect("song_selected", node, "_on_SongSelect_song_selected")
		
	$MarginContainer2/HBoxContainer/JacketImage.set_pack(pack_name)
	emit_signal("difficulty_set", ALPHA)
	first_song.emit_signal("pressed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_SongListElement_song_selected(song_data: Dictionary):
	emit_signal("song_selected", song_data)
	
func _on_SongListElement_play_song(song_data: Dictionary):
	print("%s%s/%s/%s.rznx" % [song_folder, pack_name, song_data.path, selected_difficulty])
	var data: Dictionary = {
		"chart_path": "%s%s/%s/%s.rznx" % [song_folder, pack_name, song_data.path, selected_difficulty],
		"audio_path": "%s%s/%s/audio.mp3" % [song_folder, pack_name, song_data.path]
	}
	SceneSwitcher.change_scene("res://scenes/game/loadscreen.tscn", data)

func _on_DifficultyButton_difficulty_selected(signal_difficulty):
	selected_difficulty = signal_difficulty
	emit_signal("difficulty_set", signal_difficulty)
	
func read_index(pack_name: String):
	var file_path: String = "%s%s/index.json" % [song_folder, pack_name]
	# get data from file
	var file := File.new()
	if not file.file_exists(file_path):
		print("Missing index file ", file_path)
		return null
	var err := file.open(file_path, File.READ)
	if err:
		print("Error %s while opening file: %s" % [err, file_path])
		return null
	var raw_text = file.get_as_text()
	file.close()
	var parse_result = JSON.parse(raw_text)
	if parse_result.error != OK:
		print("JSON parse error at line %s: %s" % [parse_result.error_line, parse_result.error_string])
		return null
	if not parse_result.result is Array:
		print("Error: index.json content is not an array")
		return null
	return parse_result.result
