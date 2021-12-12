extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var result_data: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	result_data = SceneSwitcher.get_param("result_data")
	$MarginContainer/NoteCounts.set_results(result_data)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
