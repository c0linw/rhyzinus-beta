extends TextureButton


# Declare member variables here. Examples:
var normal_texture = preload("res://textures/ui/vtab_normal.png")
var selected_texture = preload("res://textures/ui/vtab_selected.png")

export var tab_index: int = 0

signal tab_selected(index)


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", self, "_on_custom_tab_pressed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_custom_tab_pressed():
	emit_signal("tab_selected", tab_index)
	
func set_selected(selected: bool):
	if selected:
		texture_normal = selected_texture
	else:
		texture_normal = normal_texture
