extends Node

enum sfx_enums {SFX_NONE, SFX_CLICK, SFX_SWIPE}

# Declare member variables here. Examples:
var music_group: ShinobuGroup
var sfx_group: ShinobuGroup
var spectrum_analyzer: ShinobuSpectrumAnalyzerEffect

var sfx_sources: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	Shinobu.initialize()
	
	sfx_group = Shinobu.create_group("sfx_group", null)
	music_group = Shinobu.create_group("music", null)
	
	# load the note sound effects
	var click_file = File.new()
	click_file.open("res://sound/click.wav", File.READ)
	var buffer = click_file.get_buffer(click_file.get_len())
	click_file.close()
	var click_source = Shinobu.register_sound_from_memory("click", buffer)
	
	var swipe_file = File.new()
	swipe_file.open("res://sound/swipe.wav", File.READ)
	var buffer2 = swipe_file.get_buffer(swipe_file.get_len())
	swipe_file.close()
	var swipe_source = Shinobu.register_sound_from_memory("swipe", buffer2)
	
	sfx_sources.resize(sfx_enums.size())
	sfx_sources[sfx_enums.SFX_CLICK] = click_source
	sfx_sources[sfx_enums.SFX_SWIPE] = swipe_source
	
	# audio spectrum analyzer
	spectrum_analyzer = Shinobu.instantiate_spectrum_analyzer_effect()
	spectrum_analyzer.connect_to_endpoint()
	music_group.connect_to_effect(spectrum_analyzer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_music_volume(linear_volume: float):
	music_group.set_volume(linear_volume)
	
func set_sfx_volume(linear_volume: float):
	sfx_group.set_volume(linear_volume)
