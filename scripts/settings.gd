extends Node

const settings_file = "user://settings.cfg"
var setting_defaults: Dictionary = {
	"note_speed": 5.0,
	"audio_offset": 0,
	"input_offset": 0,
	"bg_dim": 3,
	"music_volume": 70,
	"sfx_volume": 0,
}
var setting_values: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	setting_values = setting_defaults
	read_settings_file()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func read_settings_file():
	var config = ConfigFile.new()
	var err = config.load(settings_file)
	if err != OK:
		return null
	if config.has_section("options"):
		for key in config.get_section_keys("options"):
			if setting_values.has(key):
				#print("setting found: %s = %s" % [key, config.get_value("options", key)])
				setting_values[key] = config.get_value("options", key)
	
	
func save_settings_file():
	var config = ConfigFile.new()
	for key in setting_values.keys():
		config.set_value("options", key, setting_values[key])
	config.save(settings_file)
