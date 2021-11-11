extends Node
# This object receives the parsed chart data and passes it to the gameplay scene

var leadin_time: float = 0
var offset: float = 0
var starting_bpm: float
var notes: Array = []
var timing_points: Array = []

class TimeSorter:
	# denotes the order in which these should be sorted, if there are objects with the same time
	const type_enum: Dictionary = {
		"bpm": 0, 
		"velocity": 1,
		"tap": 2,
		"hold_start": 2,
		"hold_end": 2,
	}
	
	static func sort_ascending(a: Dictionary, b: Dictionary) -> bool:
		return a["time"] < b["time"]
		
	# use this after adding the timing points and notes into one array
	static func sort_ascending_with_type_priority(a: Dictionary, b: Dictionary) -> bool:
		if a["time"] < b["time"]:
			return true
		elif a["time"] == b["time"]:
			return type_enum[a["type"]] < type_enum[b["type"]]
		else:
			return false
		
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Generates "position" based on timing points
	# "position" refers to the displayed "time" of the note. 
	# "position" is used by the renderer, and is subject to scroll speed changes.
# replaces the notes and timing_points arrays with their updated versions
func process_objects_for_gameplay():
	timing_points.sort_custom(TimeSorter, "sort_ascending_with_type_priority")
	starting_bpm = (1.0 / timing_points[0].beat_length) * 60000.0
	# make a new (sorted) array containing all the objects
	var objects: Array = timing_points.duplicate()
	objects.append_array(notes)
	objects.sort_custom(TimeSorter, "sort_ascending_with_type_priority")
	
	# add position to each object, calculating scroll speed changes
	var bpm: float = starting_bpm
	var bpm_velocity: float = 1.0
	var sv_velocity: float = 1.0
	var curr_time: float = 0.0
	var curr_position: float = 0.0
	var processed_notes: Array = []
	var processed_timing_points: Array = []
	for object in objects:
		if object["type"] == "bpm":
			var new_bpm: float = (1.0 / object["beat_length"]) * 60000.0
			bpm_velocity = new_bpm/starting_bpm
			bpm = new_bpm
		elif object["type"] == "velocity":
			sv_velocity = object["velocity"]
		var time_delta: float = object["time"] - curr_time
		var position_delta: float = time_delta * bpm_velocity * sv_velocity
		curr_time += time_delta
		curr_position += position_delta
		object["position"] = curr_position
		if object["type"] == "bpm" || object["type"] == "velocity":
			processed_timing_points.append(object)
		else:
			processed_notes.append(object)
	
	notes = processed_notes
	timing_points = processed_timing_points
	
func export_data() -> Dictionary:
	process_objects_for_gameplay()
	return {
		"leadin_time": leadin_time,
		"offset": offset,
		"starting_bpm": starting_bpm,
		"notes": notes,
		"timing_points": timing_points
	}
