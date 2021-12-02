extends Node
# This object receives the parsed chart data and passes it to the gameplay scene

var leadin_time: float = 2.000
var offset: float = 0
var starting_bpm: float
var notes: Array = []
var timing_points: Array = []
var barlines: Array = []
var beat_data: Array = []

class TimeSorter:
	# denotes the order in which these should be sorted, if there are objects with the same time
	const type_enum: Dictionary = {
		"bpm": 0, 
		"velocity": 1,
		"barline": 2,
		"tap": 3,
		"hold_start": 3,
		"hold_end": 3,
		"hold": 3
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

# Automatically adds 2 secs of lead-in time by default, but this can be changed
# Generates "position" based on timing points
	# "position" refers to the displayed "time" of the note. 
	# "position" is used by the renderer, and is subject to scroll speed changes.
# replaces the notes and timing_points arrays with their updated versions
func process_objects_for_gameplay():
	timing_points = generate_barlines(timing_points)
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
	var processed_barlines: Array = []
	for object in objects:
		var time_delta: float = object["time"] - curr_time
		var position_delta: float = time_delta * bpm_velocity * sv_velocity
		curr_time += time_delta
		curr_position += position_delta
		if object["type"] == "bpm":
			var new_bpm: float = (1.0 / object["beat_length"]) * 60000.0
			bpm_velocity = new_bpm/starting_bpm
			bpm = new_bpm
		elif object["type"] == "velocity":
			sv_velocity = object["velocity"]
		object["position"] = curr_position + offset
		object["time"] = object["time"] + offset
		if object["type"] == "bpm" || object["type"] == "velocity":
			processed_timing_points.append(object)
		elif object["type"] == "barline":
			processed_barlines.append(object)
		else:
			processed_notes.append(object)
	
	# merge hold ends with hold starts
	var processed_notes_with_holds: Array = []
	for i in processed_notes.size():
		var note: Dictionary = processed_notes[i]
		if note["type"] == "hold_start":
			var new_note: Dictionary = {
				"lane": note["lane"],
				"time": note["time"],
				"type": "hold",
				"position": note["position"],
				"end_time": note["end_time"] + offset,
				"end_position": get_end_position(note, i, processed_notes)
			}
			processed_notes_with_holds.append(new_note)
		else:
			processed_notes_with_holds.append(note)
	
	notes = processed_notes_with_holds
	timing_points = processed_timing_points
	barlines = processed_barlines
	
	generate_beats(processed_timing_points)
	
func export_data() -> Dictionary:
	process_objects_for_gameplay()
	return {
		"leadin_time": leadin_time,
		"offset": offset,
		"starting_bpm": starting_bpm,
		"notes": notes,
		"timing_points": timing_points,
		"barlines": barlines,
		"beats": beat_data
	}

func get_end_position(note: Dictionary, start_index: int, array_to_search: Array):
	var i: int = start_index + 1
	while i < array_to_search.size():
		var note_to_compare: Dictionary = array_to_search[i]
		i += 1
		if note_to_compare["lane"] != note["lane"]:
			continue
		if note_to_compare["type"] != "hold_end":
			continue
		if note_to_compare["time"] >= note["time"]:
			return note_to_compare["position"]
		i += 1
	return null
	
func generate_barlines(data: Array) -> Array:
	data.sort_custom(TimeSorter, "sort_ascending_with_type_priority")
	var return_data: Array = data.duplicate()
	var timestamp: float = data[0]["time"]
	var beat_length: float = data[0].beat_length / 1000.0
	var meter: int = data[0]["meter"]
	var beat: int = 0
	var index: int = 0
	while timestamp <= data[len(data)-1]["time"]:
		if beat % meter == 0:
			return_data.append({
				"time": timestamp,
				"type": "barline"
			})
		var next_beat_time: float = timestamp + beat_length
		if index+1 < len(data) && data[index+1]["type"] == "bpm" && next_beat_time >= data[index+1]:
			timestamp = data[index+1]["time"]
			beat_length = data[index+1]["beat_length"]
			meter = data[index+1]["meter"]
			beat = 0
			index += 1
		else:
			timestamp = next_beat_time
			beat += 1
			index += 1
	return return_data

func generate_beats(timing_points: Array):
	var data: Array = timing_points.duplicate()
	data.sort_custom(TimeSorter, "sort_ascending_with_type_priority")
	var beat_output: Array = []
	var timestamp: float = data[0]["time"]
	var beat_length: float = data[0].beat_length / 1000.0
	var meter: int = data[0]["meter"]
	var measure: int = 1
	var beat = 1
	beat_output.append({
			"time": timestamp,
			"measure": measure,
			"beat": beat
		})
	var index: int = 0
	while timestamp <= data[len(data)-1]["time"]:
		if beat % meter == 0:
			measure += 1
			beat = 0
		var next_beat_time: float = timestamp + beat_length
		if index+1 < len(data) && data[index+1]["type"] == "bpm" && next_beat_time >= data[index+1]:
			timestamp = data[index+1]["time"]
			beat_length = data[index+1]["beat_length"]
			meter = data[index+1]["meter"]
			beat = 0
			index += 1
		else:
			timestamp = next_beat_time
			beat += 1
			index += 1
		beat_output.append({
			"time": timestamp,
			"measure": measure,
			"beat": beat
		})
	beat_data = beat_output
