extends HBoxContainer

export var step: float = 1.0
export var min_value: float = 0.0
export var max_value: float = 10.0
export var default_value: float = 5.0
export var decimal_places: int = 0
export var value_name: String = ""

export var use_extra_buttons: bool = false
export var extra_step: float = 2.0

var current_value: float = default_value

signal value_changed(value_name, new_value)

# Called when the node enters the scene tree for the first time.
func _ready():
	if use_extra_buttons:
		$SuperDecrement.show()
		$SuperIncrement.show()
	current_value = default_value
	if decimal_places <= 0:
		$MarginContainer/ValueDisplay.text = str(int(current_value))
	else:
		var formatstring = "%%.0%sf" % decimal_places
		$MarginContainer/ValueDisplay.text = formatstring % current_value


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Decrement_pressed():
	update_value(stepify(current_value - step, step))


func _on_Increment_pressed():
	update_value(stepify(current_value + step, step))


func _on_HorizontalSpinBox_value_changed(value_name, new_value):
	if decimal_places <= 0:
		$MarginContainer/ValueDisplay.text = str(int(new_value))
	else:
		var formatstring = "%%.0%sf" % decimal_places
		$MarginContainer/ValueDisplay.text = formatstring % new_value


func _on_SuperDecrement_pressed():
	update_value(stepify(current_value - extra_step, step))


func _on_SuperIncrement_pressed():
	update_value(stepify(current_value + extra_step, step))
	
func _on_Options_change_value(input_value_name, new_value):
	if input_value_name == value_name:
		update_value(new_value)

func update_value(new_value):
	if new_value <= min_value:
		current_value = min_value
	elif new_value >= max_value:
		current_value = max_value
	else:
		current_value = new_value
	emit_signal("value_changed", value_name, current_value)
