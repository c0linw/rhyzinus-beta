extends TextureButton

var songname: String = ""
var artist: String = ""
var levels: Array = [0,0,0,0,0]
var focused_tex = preload("res://textures/ui/song_border_selected.png")
var normal_tex = preload("res://textures/ui/song_border.png")

signal song_selected(songname, difficulty_array)

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/SongNameContainer/SongName.text = songname
	$VBoxContainer/ArtistContainer/ArtistName.text = artist

func setup(song_data: Dictionary):
	songname = song_data.title
	artist = song_data.artist
	levels = song_data.levels

func _on_SongListElement_pressed():
	set_focus_mode(Control.FOCUS_ALL)
	grab_focus()


func _on_SongListElement_focus_entered():
	set_normal_texture(focused_tex)
	$VBoxContainer/SongNameContainer.add_constant_override("margin_left", 72)
	$VBoxContainer/SongNameContainer/SongName.add_color_override("font_color", Color(0, 0, 0, 1))
	$VBoxContainer/ArtistContainer.add_constant_override("margin_left", 108)
	$VBoxContainer/ArtistContainer/ArtistName.add_color_override("font_color", Color(0, 0, 0, 1))
	emit_signal("song_selected", songname, levels)

func _on_SongListElement_focus_exited():
	set_focus_mode(Control.FOCUS_NONE)
	$VBoxContainer/SongNameContainer.add_constant_override("margin_left", 24)
	$VBoxContainer/SongNameContainer/SongName.add_color_override("font_color", Color(1, 1, 1, 1))
	$VBoxContainer/ArtistContainer.add_constant_override("margin_left", 24)
	$VBoxContainer/ArtistContainer/ArtistName.add_color_override("font_color", Color(1, 1, 1, 1))
	set_normal_texture(normal_tex)
