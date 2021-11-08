extends Node2D
# Loads the chart data from a file into the chart_data object, then switches the scene to Game

var audio_path: String
var chart_path: String = "res://Songs/test.txt"
var current_section: String = ""
const NUM_LANES_IN_SOURCE: int = 14 # defaults to 14 key osu mania file, but supports anything 12 or above

class TimeSorter:
	static func sort_ascending(a: Dictionary, b: Dictionary) -> bool:
		if a["time"] < b["time"]:
			return true
		return false

# Called when the node enters the scene tree for the first time.
func _ready():
	load_chart(chart_path, $chart_data) # TODO: return to menu if load was unsuccessful
	# TODO: switch scene to Game, passing in audio and chart_data object

# loads the chart file and processes every line until the end. Returns true if successful.
func load_chart(file_path: String, receiver: Node) -> bool:
	# get data from file
	var file := File.new()
	if not file.file_exists(file_path):
		print("Missing chart file ", file_path)
		return false
	file.open(file_path, File.READ)
	while not file.eof_reached():
		var line := file.get_line()
		if line == "":
			continue
		if not process_chart_line(line, receiver):
			print("skipped invalid line: ", line)
	file.close()
	# ensure that the items are sorted in chronological order
	$chart_data.timing_points.sort_custom(TimeSorter, "sort_ascending")
	$chart_data.notes.sort_custom(TimeSorter, "sort_ascending")
	print("parsed %s hitobjects" % len($chart_data.notes))
	return true

# processes one line of the chart file. Returns true if the line was valid (even if skipped)
func process_chart_line(line: String, receiver: Node) -> bool:
	if line.begins_with("["): # indicates new data section
		if line == "[TimingPoints]" || line == "[HitObjects]":
			current_section = line
			print("parsing section ", line)
		else: # another section that we don't need
			current_section = ""
			print("skipping section ", line)
		return true
		
	if current_section == "[TimingPoints]":
		var timing_data: Array = line.split(",")
		if len(timing_data) != 8:
			print("timing point has %s values, was expecting 8" % len(timing_data))
			return false
		var timing_point: Dictionary = {
			"time": int(timing_data[0]),
			"beat_length": float(timing_data[1]), # beat length if type == 0, (-100)/x to get scroll speed if type == 1
			"meter": int(timing_data[2]), # ignored if type == 1
			"type": int(timing_data[6]) # 0 = BPM change, 1 = scroll speed change
		}
		$chart_data.timing_points.append(timing_point)
		return true
		
	if current_section == "[HitObjects]":
		var note_data: Array = line.split(",")
		if len(note_data) != 6:
			print("hitobject has %s values, was expecting 6" % len(note_data))
			return false
		var note_type: String = get_type(note_data)
		if note_type == "tap": # tap note
			var note: Dictionary = {
				"lane": get_lane(int(note_data[0])),
				"time": int(note_data[2]),
				"type": note_type
			}
			$chart_data.notes.append(note)
			return true
		elif note_type == "hold_start": # hold note
			var start: Dictionary = {
				"lane": get_lane(int(note_data[0])),
				"time": int(note_data[2]),
				"type": "hold_start"
			}
			var end: Dictionary = {
				"lane": start.lane,
				"time": int(note_data[5].split(":")[0]), # the first value of the comma-separated stuff at the end
				"type": "hold_end"
			}
			$chart_data.notes.append(start)
			$chart_data.notes.append(end)
			return true
		else:
			print("invalid note type ", note_type)
			return false
	return true

func get_lane(x: int) -> int:
	return int(floor(x * NUM_LANES_IN_SOURCE / 512))
	
func get_type(data: Array) -> String:
	var hold_flag: int = 1 << 7 # check the 7th bit, equivalent to 128
	var tap_flag: int = 1 # check the 0th bit
	if int(data[3]) & hold_flag != 0:
		return "hold_start"
	if int(data[3]) & tap_flag != 0:
		# possible extension: check hitsound to determine other types, which is why we pass in the whole array for this func
		return "tap"
	else: 
		return "other"

func prepare_conductor():
	pass
