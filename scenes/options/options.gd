extends Control

var options: Dictionary

signal change_value(value_name, new_value)

# Called when the node enters the scene tree for the first time.
func _ready():
	for node in get_tree().get_nodes_in_group("settings"):
		node.connect("value_changed", self, "_on_HorizontalSpinBox_value_changed")
		self.connect("change_value", node, "_on_Options_change_value")
	for key in Settings.setting_values.keys():
		print("key = %s, value = %s" % [key, Settings.setting_values[key]])
		emit_signal("change_value", key, Settings.setting_values[key])

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_HorizontalSpinBox_value_changed(value_name: String, new_value):
	Settings.setting_values[value_name] = new_value


func _on_BackButton_pressed():
	Settings.save_settings_file()
