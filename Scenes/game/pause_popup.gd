extends Popup


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal unpause

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ResumeButton_pressed():
	var conductor = get_tree().get_root().find_node("Conductor")
	hide()
	emit_signal("unpause")
	get_tree().paused = false
	
