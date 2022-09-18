extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal tab_selected(index)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_custom_tab_selected(index):
	$TabContainer.current_tab = index
	for tab_button in $VerticalTabs.get_children():
		tab_button.set_selected(tab_button.tab_index == index)
