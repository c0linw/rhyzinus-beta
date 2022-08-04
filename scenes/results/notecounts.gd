extends MarginContainer

enum {ENCRYPTED, CRACKED, DECRYPTED, FLAWLESS}

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_results(result_data: Dictionary):
	$HBoxContainer/NoteStats/HBoxContainer/NoteCounts/FlawlessCount.text = str(len(result_data[FLAWLESS])) + " "
	$HBoxContainer/NoteStats/HBoxContainer/NoteCounts/DecryptedCount.text = str(len(result_data[DECRYPTED])) + " "
	$HBoxContainer/NoteStats/HBoxContainer/NoteCounts/CrackedCount.text = str(len(result_data[CRACKED])) + " "
	$HBoxContainer/NoteStats/HBoxContainer/NoteCounts/EncryptedCount.text = str(len(result_data[ENCRYPTED])) + " "
