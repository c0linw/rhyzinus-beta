extends TextureRect

const jacket_file = "jacket.png"

var song_folder: String = "res://songs/"
var pack_name: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_pack(input: String):
	pack_name = input

func _on_SongSelect_song_selected(song_data: Dictionary):
	texture = load("%s%s/%s/%s" % [song_folder, pack_name, song_data.path, jacket_file])
