extends Node

# enums and constants
enum {ENCRYPTED, CRACKED, DECRYPTED, FLAWLESS}

var results: Dictionary = {
	ENCRYPTED: [],
	CRACKED: [],
	DECRYPTED: [],
	FLAWLESS: []
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Game_note_judged(input):
	results[input.judgement].append(input.offset)
