extends Control

var options: Dictionary

signal change_value(value_name, new_value)

# Called when the node enters the scene tree for the first time.
func _ready():
	for node in get_tree().get_nodes_in_group("settings"):
		node.connect("value_changed", self, "_on_HorizontalSpinBox_value_changed")
		self.connect("change_value", node, "_on_Options_change_value")
	for key in Settings.setting_values.keys():
		emit_signal("change_value", key, Settings.setting_values[key])

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_HorizontalSpinBox_value_changed(value_name: String, new_value):
	Settings.setting_values[value_name] = new_value


func _on_BackButton_pressed():
	var prev_scene = SceneSwitcher.get_param("prev_scene")
	if prev_scene:
		Settings.save_settings_file()
		SceneSwitcher.change_scene(prev_scene)


func _on_VolumeSpinBox_value_changed(value_name, new_value):
	AudioServer.set_bus_volume_db(1, linear2db(new_value/100.0))
	ShinobuGlobals.set_music_volume(new_value/100.0)
