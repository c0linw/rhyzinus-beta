extends TextureButton

var songname: String = "Song Name"
var levels: Array = [1,2,3,4,5]

signal song_selected(songname, difficulty_array)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_SongListElement_pressed():
	set_focus_mode(Control.FOCUS_ALL)
	grab_focus()


func _on_SongListElement_focus_entered():
	var tex = load("res://Textures/UI/song_border_selected.png")
	set_normal_texture(tex)
	emit_signal("song_selected", songname, levels)

func _on_SongListElement_focus_exited():
	set_focus_mode(Control.FOCUS_NONE)
	var tex = load("res://Textures/UI/song_border.png")
	set_normal_texture(tex)
