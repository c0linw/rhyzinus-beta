extends MarginContainer

var data: Dictionary = {
	"title": "",
	"artist": "",
	"bpm": "",
	"path": "",
	"levels": []
}

var extended_tex = preload("res://textures/ui/song_border_extended.png")
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

func set_selected():
	selected = true
	$TextureButton.texture_normal = extended_tex
	var bloom = find_node("GlowEffectBloom").get_canvas_item()
	VisualServer.canvas_item_set_z_index(bloom, 100)
	find_node("AnimationPlayer").play(curr_anim)
	emit_signal("song_selected", self, data)

func set_unselected():
	selected = false
	$TextureButton.texture_normal = normal_tex
	var bloom = find_node("GlowEffectBloom").get_canvas_item()
	VisualServer.canvas_item_set_z_index(bloom, 0)
	find_node("AnimationPlayer").play("glow_none")
	
func _on_SongSelect_difficulty_set(difficulty):
	curr_anim = anim_names[difficulty]
	var animplayer = find_node("AnimationPlayer")
	if animplayer.current_animation != "glow_none" and animplayer.current_animation != "":
		animplayer.play(curr_anim)
		
	var diffnumber = find_node("DiffNumber")
	diffnumber.text = str(int(data.levels[difficulty]))
	diffnumber.add_color_override("font_color", diff_colors[difficulty])


func _on_TextureButton_pressed():
	if selected:
		emit_signal("play_song", data)
		return
	set_selected()
