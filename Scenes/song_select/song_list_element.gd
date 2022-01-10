extends TextureButton

var data: Dictionary = {
	"title": "",
	"artist": "",
	"bpm": "",
	"path": "",
	"levels": ""
}

var focused_tex = preload("res://textures/ui/song_border_selected.png")
var normal_tex = preload("res://textures/ui/song_border.png")


signal song_selected(song_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/SongNameContainer/SongName.text = data.title
	$VBoxContainer/ArtistContainer/ArtistName.text = data.artist

func setup(song_data: Dictionary):
	data = song_data

func _on_SongListElement_pressed():
	set_focus_mode(Control.FOCUS_ALL)
	grab_focus()


func _on_SongListElement_focus_entered():
	set_normal_texture(focused_tex)
	$VBoxContainer/SongNameContainer.add_constant_override("margin_left", 72)
	$VBoxContainer/SongNameContainer/SongName.add_color_override("font_color", Color(0, 0, 0, 1))
	$VBoxContainer/ArtistContainer.add_constant_override("margin_left", 108)
	$VBoxContainer/ArtistContainer/ArtistName.add_color_override("font_color", Color(0, 0, 0, 1))
	emit_signal("song_selected", data)

func _on_SongListElement_focus_exited():
	set_focus_mode(Control.FOCUS_NONE)
	$VBoxContainer/SongNameContainer.add_constant_override("margin_left", 24)
	$VBoxContainer/SongNameContainer/SongName.add_color_override("font_color", Color(1, 1, 1, 1))
	$VBoxContainer/ArtistContainer.add_constant_override("margin_left", 24)
	$VBoxContainer/ArtistContainer/ArtistName.add_color_override("font_color", Color(1, 1, 1, 1))
	set_normal_texture(normal_tex)
