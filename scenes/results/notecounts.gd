extends MarginContainer

enum {CORRUPTED, CRACKED, DECRYPTED, FLAWLESS}

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
	find_node("FlawlessCount").text = str(len(result_data[FLAWLESS])) + " "
	find_node("DecryptedCount").text = str(len(result_data[DECRYPTED])) + " "
	find_node("CrackedCount").text = str(len(result_data[CRACKED])) + " "
	find_node("CorruptedCount").text = str(len(result_data[CORRUPTED])) + " "
