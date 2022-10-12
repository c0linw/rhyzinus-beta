extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_SongSelect_song_selected(song_data):
	if song_data.has("bpm"):
		get_node("GridContainer/BPMDisplay").text = str(song_data.bpm)
	get_node("GridContainer/LengthDisplay").text = "???"


func _on_SongPreviewPlayer_song_stream_loaded(audioplayer):
	if audioplayer.stream != null:
		var length = audioplayer.get_stream_length()
		get_node("GridContainer/LengthDisplay").text = "%s:%02d" % [int(length)/60, int(length)%60]
