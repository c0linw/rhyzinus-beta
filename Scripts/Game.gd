extends Spatial

# enums and constants
enum {ENCRYPTED, CRACKED, DECRYPTED, FLAWLESS}

# audio stuff
var audio

# gameplay stuff
var audio_offset: float = 0.0
var note_speed: float # speed range: 1.0 - 16.0
var base_note_screen_time: float

var notes_to_spawn: Array = []
var scrollmod_list: Array = []
var barlines_to_spawn: Array = []
var beat_data: Array = []

var onscreen_notes: Array = []
var onscreen_barlines: Array = []

var starting_bpm: float
var bpm_velocity: float = 1.0
var sv_velocity: float = 1.0
var last_timestamp: float = 0.0
var chart_position: float = 0.0

# Measurements, useful for positioning-related calculations
var lane_depth: float

var lower_lane_width: float
var lower_lane_left: Vector2
var lower_lane_right: Vector2

var upper_lane_width: float
var upper_lane_left: Vector2
var upper_lane_right: Vector2

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
var ObjJudgementTexture = preload("res://Scenes/Judgement_Texture.tscn")

# Input-related stuff
var input_zones: Array = []
var lane_zones: Array = []
var touch_bindings: Array = [] # keeps track of touch input events
var input_offset: float = 0.0

# Effects
var lane_effects: Array = []
var judgement_textures: Array = []

signal note_judged(result)
signal beat(measure, beat)

# Called when the node enters the scene tree for the first time.
func _ready():
	######## TODO: set options by passing them in
	note_speed = 8.7
	lane_depth = 24.0
	
	######## SETUP OBJECTS
	base_note_screen_time = (3 + (10-note_speed)) / note_speed 
	
	var chart_data = SceneSwitcher.get_param("chart_data")
	if chart_data == null :
		print("failed to load chart data!")
		return
	var options = SceneSwitcher.get_param("options")
	if options == null :
		print("failed to load options!")
		return
	starting_bpm = chart_data["starting_bpm"]
	notes_to_spawn = chart_data["notes"]
	scrollmod_list = chart_data["timing_points"]
	barlines_to_spawn = chart_data["barlines"]
	beat_data = chart_data["beats"]
	
	######## SETUP INPUT
	input_offset = options["input_offset"]
	setup_input()
	setup_lane_effects()
	setup_judgement_textures()
	setup_combo_counter()
	setup_timing_indicator()
	
	$Conductor.stream = load("res://Songs/neutralizeptbmix/neutralizeptbmix.mp3")
	$Conductor.stream.loop = false
	$Conductor.volume_db = -10.0

	$Conductor.play_from_beat(0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$Conductor.update_song_position()
	var space_state := get_world().direct_space_state
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
			
	# reset, then update hold status		
	var candidate_holds: Array = []
	for hold in get_tree().get_nodes_in_group("holds"):
		hold.held = false
		if hold.activated:
			candidate_holds.append(hold)
	for input in touch_bindings:
		if input != null:
			var nearest_hold: NoteHold = pop_nearest_note(input, candidate_holds)
			if nearest_hold != null:
				nearest_hold.held = true
	
	# check for notes that are too late, then render the rest
	for note in onscreen_notes:
		note.render(chart_position, lane_depth, base_note_screen_time)
		if note.is_in_group("holds") and timestamp > note.end_time + input_offset:
			if note.held:
				var result = {"judgement": FLAWLESS, "offset": 0}
				draw_judgement(result, note.lane)
				emit_signal("note_judged", result)
				delete_note(note)
			if !note.held and timestamp > note.end_time + note.late_cracked + input_offset:
				var result = {"judgement": ENCRYPTED, "offset": 0}
				draw_judgement(result, note.lane)
				emit_signal("note_judged", result)
				delete_note(note)
		elif timestamp >= note.time + note.late_cracked + input_offset:
			if note.is_in_group("holds"):
				if !note.head_passed:
					if !note.activated:
						var result = {"judgement": ENCRYPTED, "offset": 0}
						draw_judgement(result, note.lane)
						emit_signal("note_judged", result)
					note.head_passed = true
			else:
				var result = {"judgement": ENCRYPTED, "offset": 0}
				draw_judgement(result, note.lane)
				emit_signal("note_judged", result)
				delete_note(note)
		
	# check hold ticks
	for hold in get_tree().get_nodes_in_group("holds"):
		for tick in hold.ticks:
			if timestamp >= tick:
				var result: Dictionary
				if hold.activated and hold.held:
					result = {"judgement": FLAWLESS, "offset": 0}
				else:
					result = {"judgement": ENCRYPTED, "offset": 0}
				draw_judgement(result, hold.lane)
				emit_signal("note_judged", result)
				hold.ticks.erase(tick)
			else:
				break
		
	for beat in beat_data:
		if timestamp >= beat["time"]:
			emit_signal("beat", beat["measure"], beat["beat"])
			beat_data.erase(beat)
		else: 
			break
		
	# reset then update lane effects
	for effect in lane_effects:
		if effect != null:
			effect.visible = false
						
	for event in touch_bindings:
		if event != null:
			var camera = $Camera
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 1000
			var result = space_state.intersect_ray(from, to, [], 32, false, true)
			if result:
				for i in len(lane_zones):
					if lane_zones[i] != null and lane_zones[i].get_instance_id() == result["collider_id"]:
						if lane_effects[i] != null:
							lane_effects[i].visible = true
							break
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
		note_instance.ticks = note_data["ticks"]
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
	var barline_lower = ObjBarline.instance()
	barline_lower.time = barline_data["time"]
	barline_lower.chart_position = barline_data["position"]
	barlines_to_spawn.erase(barline_data)
	onscreen_barlines.append(barline_lower)
	$Lanes_lower.add_child(barline_lower)
	
	var barline_upper = ObjBarlineUpper.instance()
	barline_upper.time = barline_data["time"]
	barline_upper.chart_position = barline_data["position"]
	barlines_to_spawn.erase(barline_data)
	onscreen_barlines.append(barline_upper)
	$Lanes_upper.add_child(barline_upper)
	
func remove_barline(barline_to_remove):
	onscreen_barlines.erase(barline_to_remove)
	barline_to_remove.queue_free()
	
func setup_lane_effects():
	lane_effects.resize(14)
	lane_effects[0] = $Lanes_lower/LaneEffect0
	lane_effects[1] = $Lanes_lower/LaneEffect1
	lane_effects[2] = $Lanes_lower/LaneEffect2
	lane_effects[3] = $Lanes_lower/LaneEffect3
	lane_effects[4] = $Lanes_lower/LaneEffect4
	lane_effects[5] = $Lanes_lower/LaneEffect5
	lane_effects[6] = $Lanes_lower/LaneEffect6
	lane_effects[7] = $Lanes_lower/LaneEffect7
	
	for o in lane_effects:
		if o != null:
			o.visible = false
			
	var view_coords = get_viewport().size
	
	# hitboxes for lane effects on non-note tap
	lane_zones[0] = $Lanes_lower/LaneArea0
	lane_zones[1] = $Lanes_lower/LaneArea1
	lane_zones[2] = $Lanes_lower/LaneArea2
	lane_zones[3] = $Lanes_lower/LaneArea3
	lane_zones[4] = $Lanes_lower/LaneArea4
	lane_zones[5] = $Lanes_lower/LaneArea5
	lane_zones[6] = $Lanes_lower/LaneArea6
	lane_zones[7] = $Lanes_lower/LaneArea7

func setup_input():
	var view_coords = get_viewport().size
	input_zones.resize(14)
	lane_zones.resize(14)
	touch_bindings.resize(20)
	
	var a = $Lanes_lower.global_transform.origin
	lower_lane_left = $Camera.unproject_position($Lanes_lower.global_transform.origin)
	lower_lane_right = $Camera.unproject_position(Vector3(a.x + 6, a.y, a.z))
	
	var b = $Lanes_upper.global_transform.origin
	upper_lane_left = $Camera.unproject_position(b)
	upper_lane_right = $Camera.unproject_position(Vector3(b.x + 5, b.y, b.z))
	
	# actual width of a single lane
	lower_lane_width = (lower_lane_right.x - lower_lane_left.x) / 6
	# upper limit for floor note will be 60% of the way to the upper notes
	var lower_lane_top = lower_lane_left.y + (upper_lane_left.y - lower_lane_left.y) * 0.6
		
	for i in range(1, 7):
		var hitbox: NoteHitbox = ObjNoteHitbox.instance()
		var top_left = Vector2(lower_lane_left.x + lower_lane_width*(i-1.5), lower_lane_top)
		var bottom_right = Vector2(lower_lane_left.x + lower_lane_width*(i + 0.5), view_coords.y)
		var center = Vector2(lower_lane_left.x + lower_lane_width*(i-0.5), lower_lane_left.y)
		hitbox.set_points(top_left, bottom_right, center)
		input_zones[i] = hitbox
		$CanvasLayer.add_child(hitbox)
		
	var upper_lane_width = (upper_lane_right.x - upper_lane_left.x) / 4
	var upper_lane_top = upper_lane_left.y - upper_lane_width*0.67
	for i in range(10, 14):
		var hitbox: NoteHitbox = ObjNoteHitbox.instance()
		var top_left = Vector2(upper_lane_left.x + upper_lane_width*(i-10.25), upper_lane_top)
		var bottom_right = Vector2(upper_lane_left.x + upper_lane_width*(i-8.75), lower_lane_top + 1)
		var center = Vector2(upper_lane_left.x + upper_lane_width*(i-9.5), upper_lane_left.y)
		hitbox.set_points(top_left, bottom_right, center)
		input_zones[i] = hitbox
		$CanvasLayer.add_child(hitbox)
		
	var left_hitbox: NoteHitbox = ObjNoteHitbox.instance()
	var top_left = Vector2(lower_lane_left.x - lower_lane_width*1.5, upper_lane_left.y)
	var bottom_right = Vector2(lower_lane_left.x + lower_lane_width*0.5, view_coords.y)
	var center = Vector2(lower_lane_left.x - lower_lane_width*0.4, lower_lane_left.y + (upper_lane_left.y - lower_lane_left.y)*0.4)
	left_hitbox.set_points(top_left, bottom_right, center)
	input_zones[0] = left_hitbox
	$CanvasLayer.add_child(left_hitbox)
	
	var right_hitbox: NoteHitbox = ObjNoteHitbox.instance()
	top_left = Vector2(lower_lane_right.x - lower_lane_width*0.5, upper_lane_right.y)
	bottom_right = Vector2(lower_lane_right.x + lower_lane_width*1.5, view_coords.y)
	center = Vector2(lower_lane_right.x + lower_lane_width*0.4, lower_lane_right.y + (upper_lane_right.y - lower_lane_right.y)*0.4)
	right_hitbox.set_points(top_left, bottom_right, center)
	input_zones[7] = right_hitbox
	$CanvasLayer.add_child(right_hitbox)
	
func setup_judgement_textures():
	judgement_textures.resize(4)
	var pics: Array = [
		load("res://Textures/Gameplay/encrypted.png"),
		load("res://Textures/Gameplay/cracked.png"),
		load("res://Textures/Gameplay/decrypted.png"),
		load("res://Textures/Gameplay/flawless.png")
		]
	for i in len(pics):
		judgement_textures[i] = ImageTexture.new()
		judgement_textures[i].create_from_image(pics[i].get_data())
		
func setup_combo_counter():
	var view_coords = get_viewport().size
	var fontSize = get_viewport().size.y * 0.15
	var outline = fontSize * 0.02
	var comboPosX = view_coords.x/2
	var comboPosY = upper_lane_left.y + (lower_lane_left.y - upper_lane_left.y)*0.35
	$CanvasLayer/ComboCounter/ComboCounterLabel.get_font("font").size = fontSize
	$CanvasLayer/ComboCounter.set_global_position(Vector2(comboPosX, comboPosY))
	
func setup_timing_indicator():
	var view_coords = get_viewport().size
	var fontSize = get_viewport().size.y * 0.05
	var outline = fontSize * 0.02
	var comboPosX = view_coords.x/2
	var comboPosY = upper_lane_left.y + (lower_lane_left.y - upper_lane_left.y)*0.35 - get_viewport().size.y * 0.1
	$CanvasLayer/TimingIndicator/TimingLabel.get_font("font").size = fontSize
	$CanvasLayer/TimingIndicator.set_global_position(Vector2(comboPosX, comboPosY))
	

func _input(event):
	if event is InputEventScreenTouch:
		$Conductor.update_song_position()
		var event_time = $Conductor.song_position - input_offset
		if event.pressed: # tap
			touch_bindings[event.index] = event
			var candidate_notes: Array # use this to improve hit registration for notes with overlapping hitboxes
			var first_note_time = null
			# multiple notes can be candidates if they have the same timestamp and have a hitbox that covers the touch
			for note in onscreen_notes:
				if note.can_judge(event_time):
					if input_zones[note.lane].area.has_point(event.position):
						if first_note_time == null:
							first_note_time = note.time
						elif note.time > first_note_time:
							break
						candidate_notes.append(note)
				elif note.time > event_time:
					break
			
			match len(candidate_notes):
				0:
					return
				1:
					var note = candidate_notes[0]
					var result: Dictionary = note.judge(event_time)
					draw_judgement(result, note.lane)
					emit_signal("note_judged", result)
					if note.is_in_group("holds"):
						note.activated = true
					else:
						delete_note(note)
					return
				_:
					# tiebreaker for notes with same time and overlapping zone
					var min_dist_sq = null
					var closest_note = null
					for note in candidate_notes:
						if closest_note == null:
							min_dist_sq = event.position.distance_squared_to(input_zones[note.lane].center)
							closest_note = note
						else:
							var curr_dist_sq = event.position.distance_squared_to(input_zones[note.lane].center)
							if curr_dist_sq < min_dist_sq:
								min_dist_sq = curr_dist_sq
								closest_note = note
					var result: Dictionary = closest_note.judge(event_time)
					draw_judgement(result, closest_note.lane)
					emit_signal("note_judged", result)
					if closest_note.is_in_group("holds"):
						closest_note.activated = true
					else:
						delete_note(closest_note)
					return
		else: # touch release
			var candidate_holds: Array
			for note in onscreen_notes:
				if note.is_in_group("holds") and event_time >= note.end_time - note.early_cracked + input_offset and note.activated:
					candidate_holds.append(note)
			var judged_note = pop_nearest_note(event, candidate_holds)
			if judged_note != null:
				var result = {"judgement": FLAWLESS, "offset": 0}
				draw_judgement(result, judged_note.lane)
				emit_signal("note_judged", result)
				delete_note(judged_note)
			touch_bindings[event.index] = null
			return
	elif event is InputEventScreenDrag:
		touch_bindings[event.index] = event # updates position
		return
		
func draw_judgement(data: Dictionary, lane: int):
	var judgement = ObjJudgementTexture.instance()
	var tex: ImageTexture
	match data["judgement"]:
		FLAWLESS: 
			tex = judgement_textures[FLAWLESS]
		DECRYPTED:
			tex = judgement_textures[DECRYPTED]
		CRACKED:
			tex = judgement_textures[CRACKED]
		ENCRYPTED:
			tex = judgement_textures[ENCRYPTED]
	judgement.setup(tex, lower_lane_width)
	if input_zones[lane] == null:
		return
	judgement.position = Vector2(input_zones[lane].center.x - lower_lane_width/2, input_zones[lane].center.y - lower_lane_width/2)
	$CanvasLayer.add_child(judgement)
		
func delete_note(note: Note):
	onscreen_notes.erase(note)
	note.queue_free()
	
# returns and removes the nearest note that can judge the input, or returns null otherwise
func pop_nearest_note(input: InputEvent, candidates: Array):
	if input == null:
		return null
	var min_dist_sq = null
	var closest_note = null
	for note in candidates:
		if !input_zones[note.lane].area.has_point(input.position):
			continue
		if closest_note == null:
			min_dist_sq = input.position.distance_squared_to(input_zones[note.lane].center)
			closest_note = note
		else:
			var curr_dist_sq = input.position.distance_squared_to(input_zones[note.lane].center)
			if curr_dist_sq < min_dist_sq:
				min_dist_sq = curr_dist_sq
				closest_note = note
	if closest_note != null:
		candidates.erase(closest_note)
	return closest_note

func _on_Conductor_finished():
	print("Conductor finished!")
	$Conductor.stop()
	SceneSwitcher.change_scene("res://Scenes/Results.tscn", {"result_data": $result_data.results})
