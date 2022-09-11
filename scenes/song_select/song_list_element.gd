extends TextureButton

var data: Dictionary = {
	"title": "",
	"artist": "",
	"bpm": "",
	"path": "",
	"levels": []
}

var focused_tex = preload("res://textures/ui/song_border_selected.png")
var normal_tex = preload("res://textures/ui/song_border.png")
var selected: bool = false
var anim_names: Array = ["glow_green", "glow_orange", "glow_red", "glow_purple"]
var diff_colors: Array = [Color(0.31, 1, 0.31), Color(1, 0.67, 0.125), Color(1, 0.25, 0.25), Color(0.78, 0.25, 1)]
var curr_anim: String = "glow_none"

signal song_selected(instance, song_data)
signal play_song(song_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	find_node("SongName").text = data.title
	find_node("ArtistName").text = data.artist

func setup(song_data: Dictionary):
	data = song_data

func _on_SongListElement_pressed():
	if selected:
		emit_signal("play_song", data)
		return
	set_selected()

func set_selected():
	selected = true
	find_node("AnimationPlayer").play(curr_anim)
	emit_signal("song_selected", self, data)

func set_unselected():
	selected = false
	find_node("AnimationPlayer").play("glow_none")
	
func _on_SongSelect_difficulty_set(difficulty):
	curr_anim = anim_names[difficulty]
	if $AnimationPlayer.current_animation != "glow_none" and $AnimationPlayer.current_animation != "":
		$AnimationPlayer.play(curr_anim)
		
	var diffnumber = find_node("DiffNumber")
	diffnumber.text = str(int(data.levels[difficulty]))
	diffnumber.add_color_override("font_color", diff_colors[difficulty])
