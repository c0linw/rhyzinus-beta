extends Spatial

var offset: float
var note_speed: float
var lane_depth: float
var note_screen_time: float
var note_units_per_sec: float

var notes_to_spawn: Array = []
var scrollmod_list: Array = []
var onscreen_notes: Array = []
var onscreen_slides: Array = []

var bpm_velocity: float = 1.0
var sv_velocity: float = 1.0
var last_timestamp: float = 0.0
var chart_position: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	var chart_data = SceneSwitcher.get_param("chart_data")
	if chart_data == null :
		print("failed to load chart data!")
		return
	notes_to_spawn = chart_data["notes"]
	scrollmod_list = chart_data["timing_points"]
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
