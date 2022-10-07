extends Control

enum {ALPHA, BETA, GAMMA, DELTA}

var selected_difficulty: int = ALPHA

var song_folder: String = "res://songs/"
var diff_buttons: Array
var pack_name: String = "beta1"

var diff_names: Dictionary = {
	ALPHA: "Alpha",
	BETA: "Beta",
	GAMMA: "Gamma",
	DELTA: "Delta"
}

var ObjSongListElement = preload("res://scenes/song_select/song_list_element.tscn")

signal difficulty_set(difficulty)
signal song_selected(song_data)
signal set_selected_if_same(instance)

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioServer.set_bus_volume_db(1, linear2db(Settings.setting_values["music_volume"]/100.0))
	ShinobuGlobals.set_music_volume(Settings.setting_values["music_volume"]/100.0)
	
	var song_index = read_index(pack_name)
	var first_song = null
	if song_index != null:
		for song in song_index:
			var new_element = ObjSongListElement.instance()
			new_element.connect("song_selected", self, "_on_SongListElement_song_selected")
			new_element.connect("play_song", self, "_on_SongListElement_play_song")
			self.connect("difficulty_set", new_element, "_on_SongSelect_difficulty_set")
			new_element.setup(song)
			find_node("SongListContainer").add_child(new_element)
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
		
	find_node("JacketImage").set_pack(pack_name)
	emit_signal("difficulty_set", ALPHA) # TODO: find a way to locally save the last selected diff
	if first_song != null:
		first_song._on_TextureButton_pressed()
		
	if SceneSwitcher.get_param("popup_msg") != null:
		popup_alert(SceneSwitcher.get_param("popup_msg"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_SongListElement_song_selected(instance, song_data):
	emit_signal("song_selected", song_data)
	for button in get_tree().get_nodes_in_group("song_list_elements"):
		if button != instance:
			button.set_unselected()
			
	$SongPreviewPlayer.start_preview("%s%s/%s/audio.mp3" % [song_folder, pack_name, song_data.path], song_data)
	
func _on_SongListElement_play_song(song_data: Dictionary):
	var chart_path = "%s%s/%s/%s.rznx" % [song_folder, pack_name, song_data.path, selected_difficulty]
	var file = File.new()
	var exists = file.file_exists(chart_path)
	file.close()
	if not exists:
		popup_alert("Chart file not found")
		return
	var data: Dictionary = {
		"chart_path": "%s%s/%s/%s.rznx" % [song_folder, pack_name, song_data.path, selected_difficulty],
		"audio_path": "%s%s/%s/audio.mp3" % [song_folder, pack_name, song_data.path],
		"song_title": song_data.title,
		"diff_name": diff_names[selected_difficulty],
		"diff_level": song_data.levels[selected_difficulty],
		"jacket_path": "%s%s/%s/jacket.png" % [song_folder, pack_name, song_data.path]
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


func _on_OptionsButton_pressed():
	var data = {
		"prev_scene": "res://scenes/song_select/song_select.tscn"
	}
	SceneSwitcher.change_scene("res://scenes/options/options.tscn", data)
	
func popup_alert(msg: String):
	var popup = $AlertPopup.get_canvas_item()
	VisualServer.canvas_item_set_z_index(popup, 101)
	$AlertPopup.find_node("Label").text = msg
	$AlertPopup.popup_centered()
