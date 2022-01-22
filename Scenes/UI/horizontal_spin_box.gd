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
	current_value = stepify(current_value - step, step)
	if current_value <= min_value:
		current_value = min_value
	emit_signal("value_changed", value_name, current_value)


func _on_Increment_pressed():
	current_value = stepify(current_value + step, step)
	if current_value >= max_value:
		current_value = max_value
	emit_signal("value_changed", value_name, current_value)


func _on_HorizontalSpinBox_value_changed(value_name, new_value):
	if decimal_places <= 0:
		$MarginContainer/ValueDisplay.text = str(int(new_value))
	else:
		var formatstring = "%%.0%sf" % decimal_places
		$MarginContainer/ValueDisplay.text = formatstring % new_value


func _on_SuperDecrement_pressed():
	print(current_value)
	current_value = stepify(current_value - extra_step, step)
	if current_value <= min_value:
		current_value = min_value
	print(current_value)
	emit_signal("value_changed", value_name, current_value)


func _on_SuperIncrement_pressed():
	current_value = stepify(current_value + extra_step, step)
	if current_value >= max_value:
		current_value = max_value
	emit_signal("value_changed", value_name, current_value)
