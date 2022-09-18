extends Control

# based on Gonkee's audio visualiser for Godot 3.2
onready var spectrum = AudioServer.get_bus_effect_instance(1, 0)

var definition = 20
var min_freq = 20
var max_freq = 20000

var max_db = 0
var min_db = -40

var accel = 20
var histogram = []

func _ready():
	yield(get_tree(), "idle_frame")
	for i in range(definition):
		var bar_instance = ColorRect.new()
		bar_instance.color = Color(1, 1, 1, 0.1)
		bar_instance.rect_min_size = Vector2(rect_size.x/definition - $HBoxContainer.get_constant("separation"), 0)
		bar_instance.size_flags_vertical = SIZE_SHRINK_CENTER
		$HBoxContainer.add_child(bar_instance)
		histogram.append(0)

func _process(delta):
	if spectrum == null:
		return
	var freq = min_freq
	var interval = (max_freq - min_freq) / definition
	var bar_instances = $HBoxContainer.get_children()
	
	for i in range(definition):
		var freqrange_low = float(freq - min_freq) / float(max_freq - min_freq)
		freqrange_low = freqrange_low * freqrange_low * freqrange_low * freqrange_low
		freqrange_low = lerp(min_freq, max_freq, freqrange_low)
		
		freq += interval
		
		var freqrange_high = float(freq - min_freq) / float(max_freq - min_freq)
		freqrange_high = freqrange_high * freqrange_high * freqrange_high * freqrange_high
		freqrange_high = lerp(min_freq, max_freq, freqrange_high)
		
		var mag = spectrum.get_magnitude_for_frequency_range(freqrange_low, freqrange_high)
		mag = linear2db(mag.length())
		mag = (mag - min_db) / (max_db - min_db)
		
		mag += 0.3 * (freq - min_freq) / (max_freq - min_freq)
		mag = clamp(mag, 0.05, 1)
		
		histogram[i] = lerp(histogram[i], mag, accel * delta)
		if i < len(bar_instances):
			bar_instances[i].rect_min_size.y = histogram[i] * rect_size.y * 0.75	
