extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var ObjSongListElement = preload("res://scenes/song_select/song_list_element.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(0, 10):
		var new_element = ObjSongListElement.instance()
		new_element.connect("song_selected", self, "_on_SongListElement_song_selected")
		$SongSelectScroll/VBoxContainer.add_child(new_element)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_SongListElement_song_selected(songname: String, levels: Array):
	print("Song selected!")
