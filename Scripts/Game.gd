extends Spatial

var audio

var offset: float
var note_speed: float # speed range: 1.0 - 16.0
var lane_depth: float
var base_note_screen_time: float

var notes_to_spawn: Array = []
var scrollmod_list: Array = []
var onscreen_notes: Array = []
var onscreen_slides: Array = []

var starting_bpm: float
var bpm_velocity: float = 1.0
var sv_velocity: float = 1.0
var last_timestamp: float = 0.0
var chart_position: float = 0.0

# Preload objects
var ObjNoteTap = preload("res://Scenes/Note_Tap.tscn")
var ObjNoteTapSide = preload("res://Scenes/Note_Tap_Side.tscn")
var ObjNoteTapUpper = preload("res://Scenes/Note_Tap_Upper.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	######## TODO: set options by passing them in
	note_speed = 9.0
	lane_depth = 24.0
	
	########
	base_note_screen_time = (12.0 - note_speed) / 2.0 # TODO: find formula that scales better
	
	var chart_data = SceneSwitcher.get_param("chart_data")
	if chart_data == null :
		print("failed to load chart data!")
		return
	starting_bpm = chart_data["starting_bpm"]
	notes_to_spawn = chart_data["notes"]
	scrollmod_list = chart_data["timing_points"]
	
	$Conductor.set_bpm(starting_bpm)
	$Conductor.stream = load("res://Songs/audio.mp3")
	$Conductor.volume_db = -10.0

	$Conductor.play_from_beat(0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var timestamp = $Conductor.song_position
	for sv in scrollmod_list:
		if timestamp >= sv["time"]:
			apply_timing_point(sv)
		else:
			break
	
	chart_position += (timestamp - last_timestamp) * bpm_velocity * sv_velocity
	
	for note_data in notes_to_spawn:
		if chart_position >= note_data["position"] - base_note_screen_time:
			spawn_note(note_data)
		else:
			break # assumes all notes are stored in ascending time
			
	for note in onscreen_notes:
		note.render(chart_position, lane_depth, base_note_screen_time)
	last_timestamp = timestamp

func apply_timing_point(sv: Dictionary):
	# account for any bit of the old scrollmod that was missed
	chart_position += (sv["time"]-last_timestamp)*bpm_velocity*sv_velocity 
	if sv["type"] == "bpm":
		var new_bpm: float = (1.0 / sv["beat_length"]) * 60000.0
		bpm_velocity = new_bpm/starting_bpm
	elif sv["type"] == "velocity":
		sv_velocity = sv["velocity"]
	last_timestamp = sv["time"] # set up to add remaining part under new scrollmod
	scrollmod_list.erase(sv)
	
func spawn_note(note_data: Dictionary):
	var note_instance: Note
	if note_data["type"] == "tap":
		if note_data["lane"] == 0 || note_data["lane"] == 7:
			note_instance = ObjNoteTapSide.instance()
		elif note_data["lane"] > 9:
			note_instance = ObjNoteTapUpper.instance()
		else:
			note_instance = ObjNoteTap.instance()
	else:
		return
	note_instance.time = note_data["time"]
	note_instance.chart_position = note_data["position"]
	note_instance.lane = note_data["lane"]
	notes_to_spawn.erase(note_data)
	onscreen_notes.append(note_instance)
	if note_instance.lane <= 7:
		$Lanes_lower.add_child(note_instance)
	else:
		$Lanes_upper.add_child(note_instance)

func _on_Conductor_finished():
	pass # Replace with function body.
