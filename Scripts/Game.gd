extends Spatial

# audio stuff
var audio

# gameplay stuff
var offset: float
var note_speed: float # speed range: 1.0 - 16.0
var lane_depth: float
var base_note_screen_time: float

var notes_to_spawn: Array = []
var scrollmod_list: Array = []
var barlines_to_spawn: Array = []

var onscreen_notes: Array = []
var onscreen_slides: Array = []
var onscreen_barlines: Array = []

var starting_bpm: float
var bpm_velocity: float = 1.0
var sv_velocity: float = 1.0
var last_timestamp: float = 0.0
var chart_position: float = 0.0

# Preload objects
var ObjNoteTap = preload("res://Scenes/Note_Tap.tscn")
var ObjNoteTapSide = preload("res://Scenes/Note_Tap_Side.tscn")
var ObjNoteTapUpper = preload("res://Scenes/Note_Tap_Upper.tscn")
var ObjNoteHold = preload("res://Scenes/Note_Hold.tscn")
var ObjNoteHoldSide = preload("res://Scenes/Note_Hold_Side.tscn")
var ObjNoteHoldUpper = preload("res://Scenes/Note_Hold_Upper.tscn")
var ObjBarline = preload("res://Scenes/Barline.tscn")
var ObjBarlineUpper = preload("res://Scenes/Barline_Upper.tscn")
var ObjNoteHitbox = preload("res://Scenes/Note_Hitbox.tscn")

# Input-related stuff
var input_zones: Array = []
var lane_zones: Array = []
var lane_effects: Array = []
var touch_bindings: Array = [] # keeps track of touch input events

# Called when the node enters the scene tree for the first time.
func _ready():
	######## TODO: set options by passing them in
	note_speed = 10.0
	lane_depth = 24.0
	
	######## SETUP OBJECTS
	base_note_screen_time = (12.0 - note_speed) / 2.0 # TODO: find formula that scales better
	
	var chart_data = SceneSwitcher.get_param("chart_data")
	if chart_data == null :
		print("failed to load chart data!")
		return
	starting_bpm = chart_data["starting_bpm"]
	notes_to_spawn = chart_data["notes"]
	scrollmod_list = chart_data["timing_points"]
	barlines_to_spawn = chart_data["barlines"]
	
	######## SETUP INPUT
	setup_input()
	setup_lane_effects()
	
	$Conductor.set_bpm(starting_bpm)
	$Conductor.stream = load("res://Songs/neutralizeptbmix/neutralizeptbmix.mp3")
	$Conductor.volume_db = -10.0

	$Conductor.play_from_beat(0, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Conductor.update_song_position()
	var timestamp = $Conductor.song_position
	for sv in scrollmod_list:
		if timestamp >= sv["time"]:
			apply_timing_point(sv)
		else:
			break
	
	chart_position += (timestamp - last_timestamp) * bpm_velocity * sv_velocity
	
	for barline_data in barlines_to_spawn:
		if chart_position >= barline_data["position"] - base_note_screen_time:
			spawn_barline(barline_data)
		else:
			break # assumes all barlines are stored in ascending time
	
	for note_data in notes_to_spawn:
		if chart_position >= note_data["position"] - base_note_screen_time:
			spawn_note(note_data)
		else:
			break # assumes all notes are stored in ascending time
			
	for barline in onscreen_barlines:
		if chart_position >= barline.chart_position:
			remove_barline(barline)
		else:
			barline.render(chart_position, lane_depth, base_note_screen_time)
			
	for note in onscreen_notes:
		note.render(chart_position, lane_depth, base_note_screen_time)
		
	# reset then update
	for effect in lane_effects:
		if effect != null:
			effect.visible = false
		
	for event in touch_bindings:
		if event != null:
			for i in len(lane_zones):
				var lane = lane_zones[i]
				if lane != null and lane.area.has_point(event.position):
					var effect: MeshInstance = lane_effects[i]
					if effect != null:
						effect.visible = true
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
	elif note_data["type"] == "hold":
		if note_data["lane"] == 0 || note_data["lane"] == 7:
			note_instance = ObjNoteHoldSide.instance()
		elif note_data["lane"] > 9:
			note_instance = ObjNoteHoldUpper.instance()
		else:
			note_instance = ObjNoteHold.instance()
		note_instance.end_time = note_data["end_time"]
		note_instance.end_position = note_data["end_position"]
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
		
func spawn_barline(barline_data: Dictionary):
	var barline_instance = ObjBarline.instance()
	barline_instance.time = barline_data["time"]
	barline_instance.chart_position = barline_data["position"]
	barlines_to_spawn.erase(barline_data)
	onscreen_barlines.append(barline_instance)
	$Lanes_lower.add_child(barline_instance)
	
func remove_barline(barline_to_remove):
	$Lanes_lower.remove_child(barline_to_remove)
	onscreen_barlines.erase(barline_to_remove)
	barline_to_remove.queue_free()
	
func setup_lane_effects():
	lane_effects.resize(14)
	lane_effects[1] = $Lanes_lower/LaneEffect1
	lane_effects[2] = $Lanes_lower/LaneEffect2
	lane_effects[3] = $Lanes_lower/LaneEffect3
	lane_effects[4] = $Lanes_lower/LaneEffect4
	lane_effects[5] = $Lanes_lower/LaneEffect5
	lane_effects[6] = $Lanes_lower/LaneEffect6
	
	for o in lane_effects:
		if o != null:
			o.visible = false
	
func setup_input():
	var view_coords = get_viewport().size
	input_zones.resize(14)
	lane_zones.resize(14)
	touch_bindings.resize(20)
	
	var a = $Lanes_lower.global_transform.origin
	var lower_left: Vector2 = $Camera.unproject_position($Lanes_lower.global_transform.origin)
	var lower_right: Vector2 = $Camera.unproject_position(Vector3(a.x + 6, a.y, a.z))
	
	var b = $Lanes_upper.global_transform.origin
	var upper_left: Vector2 = $Camera.unproject_position(b)
	var upper_right: Vector2 = $Camera.unproject_position(Vector3(b.x + 5, b.y, b.z))
	
	# actual width of a single lane
	var lower_lane_width = (lower_right.x - lower_left.x) / 6
	# upper limit for floor note will be 60% of the way to the upper notes
	var lower_lane_top = lower_left.y + (upper_left.y - lower_left.y) * 0.6
	
	# hitboxes for lane effects on non-note tap
	for i in range(1, 7):
		var hitbox: NoteHitbox = ObjNoteHitbox.instance()
		var top_left = Vector2(lower_left.x + lower_lane_width*(i-1), lower_lane_top)
		var bottom_right = Vector2(lower_left.x + lower_lane_width*i, view_coords.y)
		var center = Vector2(lower_left.x + lower_lane_width*(i-0.5), lower_left.y)
		hitbox.set_points(top_left, bottom_right, center)
		lane_zones[i] = hitbox
		$CanvasLayer.add_child(hitbox)
		
	for i in range(1, 7):
		var hitbox: NoteHitbox = ObjNoteHitbox.instance()
		var top_left = Vector2(lower_left.x + lower_lane_width*(i-1.5), lower_lane_top)
		var bottom_right = Vector2(lower_left.x + lower_lane_width*(i + 0.5), view_coords.y)
		var center = Vector2(lower_left.x + lower_lane_width*(i-0.5), lower_left.y)
		hitbox.set_points(top_left, bottom_right, center)
		input_zones[i] = hitbox
		$CanvasLayer.add_child(hitbox)
		
	var upper_lane_width = (upper_right.x - upper_left.x) / 4
	var upper_lane_top = upper_left.y - upper_lane_width*0.67
	for i in range(10, 14):
		var hitbox: NoteHitbox = ObjNoteHitbox.instance()
		var top_left = Vector2(upper_left.x + upper_lane_width*(i-10.25), upper_lane_top)
		var bottom_right = Vector2(upper_left.x + upper_lane_width*(i-8.75), lower_lane_top + 1)
		var center = Vector2(upper_left.x + upper_lane_width*(i-9.5), upper_left.y)
		hitbox.set_points(top_left, bottom_right, center)
		input_zones[i] = hitbox
		$CanvasLayer.add_child(hitbox)
		
	var left_hitbox: NoteHitbox = ObjNoteHitbox.instance()
	var top_left = Vector2(lower_left.x - lower_lane_width*1.5, upper_left.y)
	var bottom_right = Vector2(lower_left.x + lower_lane_width*0.5, view_coords.y)
	var center = Vector2(lower_left.x - lower_lane_width*0.4, lower_left.y + (upper_left.y - lower_left.y)*0.4)
	left_hitbox.set_points(top_left, bottom_right, center)
	input_zones[0] = left_hitbox
	$CanvasLayer.add_child(left_hitbox)
	
	var right_hitbox: NoteHitbox = ObjNoteHitbox.instance()
	top_left = Vector2(lower_right.x - lower_lane_width*0.5, upper_right.y)
	bottom_right = Vector2(lower_right.x + lower_lane_width*1.5, view_coords.y)
	center = Vector2(lower_right.x + lower_lane_width*0.4, lower_right.y + (upper_right.y - lower_right.y)*0.4)
	right_hitbox.set_points(top_left, bottom_right, center)
	input_zones[8] = right_hitbox
	$CanvasLayer.add_child(right_hitbox)

func _input(event):
	if event is InputEventScreenTouch:
		$Conductor.update_song_position()
		var event_time = $Conductor.song_position
		if event.pressed: # tap
			touch_bindings[event.index] = event
			for note in onscreen_notes:
				if note.can_judge(event_time):
					print("note hit! time = ", event_time)
					# return
		else: # touch release
			touch_bindings[event.index] = null
			return
	elif event is InputEventScreenDrag:
		touch_bindings[event.index] = event
		return

func _on_Conductor_finished():
	pass # Replace with function body.
