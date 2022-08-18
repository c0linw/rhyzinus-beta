extends Spatial

# enums and constants
enum {CORRUPTED, CRACKED, DECRYPTED, FLAWLESS}

# audio stuff
var audio

# gameplay stuff
var audio_offset: float = 0.0
var note_speed: float # speed range: 1.0 - 10.0
var base_note_screen_time: float

var notes_to_spawn: Array = []
var scrollmod_list: Array = []
var barlines_to_spawn: Array = []
var beat_data: Array = []
var simlines_to_spawn: Array = []

var onscreen_notes: Array = []
var onscreen_barlines: Array = []
var onscreen_simlines: Array = []

var starting_bpm: float
var sv_velocity: float = 1.0
var last_timestamp: float = 0.0
var chart_position: float = 0.0
var notecount: int = 0

# Measurements, useful for positioning-related calculations
var lane_depth: float

var lower_lane_width: float
var lower_lane_left: Vector2
var lower_lane_right: Vector2

var upper_lane_width: float
var upper_lane_left: Vector2
var upper_lane_right: Vector2

# Preload objects
var ObjNoteTap = preload("res://scenes/game/notes/note_tap.tscn")
var ObjNoteTapSide = preload("res://scenes/game/notes/note_tap_side.tscn")
var ObjNoteTapUpper = preload("res://scenes/game/notes/note_tap_upper.tscn")
var ObjNoteHold = preload("res://scenes/game/notes/note_hold.tscn")
var ObjNoteHoldSide = preload("res://scenes/game/notes/note_hold_side.tscn")
var ObjNoteHoldUpper = preload("res://scenes/game/notes/note_hold_upper.tscn")
var ObjNoteSwipe = preload("res://scenes/game/notes/note_swipe.tscn")
var ObjNoteSwipeSide = preload("res://scenes/game/notes/note_swipe_side.tscn")
var ObjBarline = preload("res://scenes/game/entities/barline.tscn")
var ObjBarlineUpper = preload("res://scenes/game/entities/barline_upper.tscn")
var ObjNoteHitbox = preload("res://scenes/game/entities/note_hitbox.tscn")
var ObjJudgementTexture = preload("res://scenes/game/entities/judgement_texture.tscn")
var ObjSimline = preload("res://scenes/game/entities/simline.tscn")
var ObjNoteEffect = preload("res://scenes/game/effect/note_effect.tscn")

# Input-related stuff
var input_zones: Array = []
var lane_zones: Array = []
var touch_bindings: Array = [] # keeps track of touch input events
var input_offset: float = 0.0

const SWIPE_THRESHOLD_LANES: float = 0.5 # how many lanes of distance are required to activate a swipe
var swipe_threshold_px: float = 0 # set this value after lane dimensions are calculated

var judgement_sources: Dictionary = {
	"tap": 0,
	"release": 0,
	"end_miss": 0,
	"end_hit": 0,
	"start_hit": 0,
	"start_hit_tiebreaker": 0,
	"start_pass": 0,
	"note_pass": 0,
	"hold_tick": 0,
	"tiebreaker": 0,
}

# Effects
var lane_effects: Array = []
var judgement_textures: Array = []

signal note_judged(result)
signal beat(measure, beat)
signal pause

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	
	var chart_data = SceneSwitcher.get_param("chart_data")
	if chart_data == null :
		print("failed to load chart data!")
		return
		
	var audio_path = SceneSwitcher.get_param("audio_path")
	if audio_path == null :
		print("failed to get audio path!")
		return
		
	var options = SceneSwitcher.get_param("options")
	if options == null :
		print("failed to load options!")
		return
	
	note_speed = options["note_speed"]
	lane_depth = 24.0
	
	######## SETUP OBJECTS
	base_note_screen_time = (3 + (10-note_speed)) / note_speed 
	
	if SceneSwitcher.get_param("song_title") != null:
		find_node("SongTitleLabel").text = SceneSwitcher.get_param("song_title")
		
	if SceneSwitcher.get_param("diff_name") != null && SceneSwitcher.get_param("diff_level") != null:
		find_node("DifficultyLabel").text = "%s %s" % [SceneSwitcher.get_param("diff_name"), SceneSwitcher.get_param("diff_level")]
	
	if SceneSwitcher.get_param("jacket_path") != null:
		find_node("SongJacket").texture = load(SceneSwitcher.get_param("jacket_path"))
	
	starting_bpm = chart_data["starting_bpm"]
	notes_to_spawn = chart_data["notes"].duplicate()
	scrollmod_list = chart_data["timing_points"].duplicate()
	barlines_to_spawn = chart_data["barlines"].duplicate()
	beat_data = chart_data["beats"].duplicate()
	notecount = chart_data["notecount"]
	$result_data.notecount = notecount
	simlines_to_spawn = chart_data["simlines"].duplicate()
	
	######## SETUP INPUT
	input_offset = options["input_offset"]
	setup_input()
	setup_lane_effects()
	setup_judgement_textures()
	setup_combo_counter()
	setup_timing_indicator()
	
	$Conductor.stream = load(audio_path)
	$Conductor.stream.loop = false
	$Conductor.volume_db = -10.0

	yield(get_tree(), "idle_frame")
	set_process(true)
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
	
	chart_position += (timestamp - last_timestamp) * sv_velocity
	
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
			
	for simline_data in simlines_to_spawn:
		if chart_position >= simline_data["position"] - base_note_screen_time:
			spawn_simline(simline_data)
		else:
			break # assumes all simlines are stored in ascending time
			
	for barline in onscreen_barlines:
		if chart_position >= barline.chart_position:
			remove_barline(barline)
		else:
			barline.render(chart_position, lane_depth, base_note_screen_time)
			
	for simline in onscreen_simlines:
		if chart_position >= simline.chart_position:
			remove_simline(simline)
		else:
			simline.render(chart_position, lane_depth, base_note_screen_time)
			
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
				judgement_sources["end_hit"] += 1
				delete_note(note)
			if !note.held and timestamp > note.end_time + note.late_cracked + input_offset:
				var result = {"judgement": CORRUPTED, "offset": 0}
				draw_judgement(result, note.lane)
				emit_signal("note_judged", result)
				judgement_sources["end_miss"] += 1
				delete_note(note)
		elif note.is_in_group("swipes") and note.activated and timestamp < note.time + note.late_cracked + input_offset:
			var result = {"judgement": FLAWLESS, "offset": 0}
			draw_judgement(result, note.lane)
			emit_signal("note_judged", result)
			delete_note(note)
		elif timestamp >= note.time + note.late_cracked + input_offset:
			if note.is_in_group("holds"):
				if !note.head_judged:
					if !note.activated:
						var result = {"judgement": CORRUPTED, "offset": 0}
						draw_judgement(result, note.lane)
						emit_signal("note_judged", result)
						judgement_sources["start_pass"] += 1
					note.head_judged = true
			else:
				var result = {"judgement": CORRUPTED, "offset": 0}
				draw_judgement(result, note.lane)
				emit_signal("note_judged", result)
				judgement_sources["note_pass"] += 1
				delete_note(note)
		
	# check hold ticks
	for hold in get_tree().get_nodes_in_group("holds"):
		for tick in hold.ticks:
			if timestamp >= tick:
				var result: Dictionary
				if hold.activated and hold.held:
					result = {"judgement": FLAWLESS, "offset": 0}
				else:
					result = {"judgement": CORRUPTED, "offset": 0}
				draw_judgement(result, hold.lane)
				emit_signal("note_judged", result)
				judgement_sources["hold_tick"] += 1
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
	chart_position += (sv["time"]-last_timestamp)*sv_velocity 
	if sv["type"] == "bpm":
		var new_bpm: float = (60.0 / sv["beat_length"])
		# TODO: keep or remove? might be useful later
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
	elif note_data["type"] == "swipe":
		if note_data["lane"] == 0 || note_data["lane"] == 7:
			note_instance = ObjNoteSwipeSide.instance()
		else:
			note_instance = ObjNoteSwipe.instance()
	else:
		return
	note_instance.time = note_data["time"]
	note_instance.chart_position = note_data["position"]
	note_instance.lane = note_data["lane"]
	notes_to_spawn.erase(note_data)
	onscreen_notes.append(note_instance)
	if note_instance.lane == 0:
		$Lanes_lower/Left.add_child(note_instance)
	elif note_instance.lane < 7:
		$Lanes_lower.add_child(note_instance)
	elif note_instance.lane == 7:
		$Lanes_lower/Right.add_child(note_instance)
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
	
func spawn_simline(simline_data: Dictionary):
	if len(simline_data.upper) == 0 or len(simline_data.lower) == 0:
		simlines_to_spawn.erase(simline_data)
		return
	for upper in simline_data.upper.keys():
		for lower in simline_data.lower.keys():
			var simline = ObjSimline.instance()
			simline.time = simline_data["time"]
			simline.chart_position = simline_data["position"]
			simlines_to_spawn.erase(simline_data)
			onscreen_simlines.append(simline)
			
			simline.set_ends(lower, upper, $Lanes_lower.translation, $Lanes_upper.translation)
			$Lanes_lower.add_child(simline)
	
func remove_simline(simline_to_remove):
	onscreen_simlines.erase(simline_to_remove)
	simline_to_remove.queue_free()
	
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
	# lower limit is the same distance
	var lower_lane_bottom = lower_lane_left.y - (upper_lane_left.y - lower_lane_left.y) * 0.6
		
	for i in range(1, 7):
		var hitbox: NoteHitbox = ObjNoteHitbox.instance()
		var top_left = Vector2(lower_lane_left.x + lower_lane_width*(i-1.5), lower_lane_top)
		var bottom_right = Vector2(lower_lane_left.x + lower_lane_width*(i + 0.5), lower_lane_bottom)
		var center = Vector2(lower_lane_left.x + lower_lane_width*(i-0.5), lower_lane_left.y)
		hitbox.set_points(top_left, bottom_right, center)
		input_zones[i] = hitbox
		$CanvasLayer.add_child(hitbox)
		
	upper_lane_width = (upper_lane_right.x - upper_lane_left.x) / 4
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
	var bottom_right = Vector2(lower_lane_left.x + lower_lane_width*0.5, lower_lane_bottom)
	var center = Vector2(lower_lane_left.x - lower_lane_width*0.25, lower_lane_left.y + (upper_lane_left.y - lower_lane_left.y)*0.3)
	left_hitbox.set_points(top_left, bottom_right, center)
	input_zones[0] = left_hitbox
	$CanvasLayer.add_child(left_hitbox)
	
	var right_hitbox: NoteHitbox = ObjNoteHitbox.instance()
	top_left = Vector2(lower_lane_right.x - lower_lane_width*0.5, upper_lane_right.y)
	bottom_right = Vector2(lower_lane_right.x + lower_lane_width*1.5, lower_lane_bottom)
	center = Vector2(lower_lane_right.x + lower_lane_width*0.25, lower_lane_right.y + (upper_lane_right.y - lower_lane_right.y)*0.3)
	right_hitbox.set_points(top_left, bottom_right, center)
	input_zones[7] = right_hitbox
	$CanvasLayer.add_child(right_hitbox)
	
	swipe_threshold_px = lower_lane_width * SWIPE_THRESHOLD_LANES
	
func setup_judgement_textures():
	judgement_textures.resize(4)
	var pics: Array = [
		load("res://textures/gameplay/corrupted.png"), 
		load("res://textures/gameplay/cracked.png"),
		load("res://textures/gameplay/decrypted.png"),
		load("res://textures/gameplay/flawless.png")
		]
	for i in len(judgement_textures):
		judgement_textures[i] = ImageTexture.new()
		judgement_textures[i].create_from_image(pics[i].get_data())
		
func setup_combo_counter():
	var fontSize = (lower_lane_left.y - upper_lane_left.y) * 0.37
	var outline = fontSize * 0.02
	var comboPosY = upper_lane_left.y + (lower_lane_left.y - upper_lane_left.y)*0.35
	$CanvasLayer/ComboCounter/ComboCounterLabel.get_font("font").size = fontSize
	$CanvasLayer/ComboCounter.margin_top = comboPosY
	
func setup_timing_indicator():
	var fontSize = (lower_lane_left.y - upper_lane_left.y) * 0.13
	var outline = fontSize * 0.02
	var timingPosY = $CanvasLayer/ComboCounter.get_global_position().y - get_viewport().size.y * 0.1
	$CanvasLayer/TimingIndicator/TimingLabel.get_font("font").size = fontSize
	$CanvasLayer/TimingIndicator.margin_top = timingPosY
	

func _input(event):
	if event is InputEventScreenTouch:
		var event_time = $Conductor.song_position - input_offset
		if event.pressed: # tap
			# intercept pause button if available
			if $CanvasLayer/PauseContainer/PauseButton.get_global_rect().has_point(event.position):
				pause_game()
				return
			
			# otherwise, process for gameplay
			touch_bindings[event.index] = event
			var candidate_notes: Array # use this to improve hit registration for notes with overlapping hitboxes
			var first_note_time = null
			# multiple notes can be candidates if they have the same timestamp and have a hitbox that covers the touch
			for note in onscreen_notes:
				if note.can_judge(event_time) and not note.is_in_group("swipes"):
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
					var result = note.judge(event_time)
					if result != null:
						draw_judgement(result, note.lane)
						emit_signal("note_judged", result)
						if note.is_in_group("holds"):
							judgement_sources["start_hit"] += 1
						else:
							judgement_sources["tap"] += 1
					if not note.is_in_group("holds"):
						delete_note(note)
					return
				_:
					# tiebreaker for notes with same time and overlapping zone
					var closest_note = pop_nearest_note(event, candidate_notes)
					if closest_note == null:
						return
					var result = closest_note.judge(event_time)
					if result != null:
						draw_judgement(result, closest_note.lane)
						emit_signal("note_judged", result)
						if closest_note.is_in_group("holds"):
							judgement_sources["start_hit_tiebreaker"] += 1
						else:
							judgement_sources["tiebreaker"] += 1
					if not closest_note.is_in_group("holds"):
						delete_note(closest_note)
					return
		else: # touch release
			var candidate_holds: Array
			for note in onscreen_notes:
				if note.is_in_group("holds") and event_time >= note.end_time - note.early_release + input_offset and note.activated:
					candidate_holds.append(note)
			var judged_note = pop_nearest_note(event, candidate_holds)
			if judged_note != null:
				var result = {"judgement": FLAWLESS, "offset": 0}
				draw_judgement(result, judged_note.lane)
				emit_signal("note_judged", result)
				judgement_sources["release"] += 1
				delete_note(judged_note)
			touch_bindings[event.index] = null
			return
	elif event is InputEventScreenDrag:
		touch_bindings[event.index] = event # updates position
		var event_time = $Conductor.song_position - input_offset
		var candidate_notes: Array # use this to improve hit registration for notes with overlapping hitboxes
		var first_note_time = null
		# multiple notes can be candidates if they have the same timestamp and have a hitbox that covers the touch
		for note in onscreen_notes:
			if note.is_in_group("swipes") and note.can_judge(event_time):
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
				if note.start_position == null:
					note.start_position = event.position
				elif event.position.distance_to(note.start_position) > swipe_threshold_px:
					note.activated = true
				return
			_:
				# tiebreaker for notes with same time and overlapping zone
				var closest_note = pop_nearest_note(event, candidate_notes)
				if closest_note != null:
					if closest_note.start_position == null:
						closest_note.start_position = event.position
					elif event.position.distance_to(closest_note.start_position) > swipe_threshold_px:
						closest_note.activated = true
				return
		return
		
func draw_judgement(data: Dictionary, lane: int):
	if input_zones[lane] == null:
		return
	var judgement = ObjJudgementTexture.instance()
	var tex: ImageTexture
	
	var play_effect := false
	match data["judgement"]:
		FLAWLESS: 
			tex = judgement_textures[FLAWLESS]
			play_effect = true
		DECRYPTED:
			tex = judgement_textures[DECRYPTED]
			play_effect = true
		CRACKED:
			tex = judgement_textures[CRACKED]
			play_effect = true
		CORRUPTED:
			tex = judgement_textures[CORRUPTED]
	judgement.setup(tex, lower_lane_width)
	judgement.position = Vector2(input_zones[lane].center.x - lower_lane_width/2, input_zones[lane].center.y - lower_lane_width/2)
	$CanvasLayer.add_child(judgement)
	
	if play_effect:
		play_effect(lane)
		

func play_effect(lane: int):
	var fx = ObjNoteEffect.instance()
	fx.position = input_zones[lane].center
	var width = upper_lane_width if lane >= 10 else lower_lane_width
	fx.scale_to_width(width * 1.5)
	if lane == 0:
		fx.rotation_degrees = 90
	elif lane == 7:
		fx.rotation_degrees = -90
	$CanvasLayer.add_child(fx)
		
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
	$Conductor.stop()
	for key in judgement_sources:
		print("%s: %d" % [key, judgement_sources[key]])
	var data: Dictionary = {
		"result_data": $result_data.results, 
		"best_combo": $CanvasLayer/ComboCounter/ComboCounterLabel.best_combo,
		"score": $result_data.score,
		"song_title": SceneSwitcher.get_param("song_title"),
		"difficulty": SceneSwitcher.get_param("difficulty"),
		"jacket_path": SceneSwitcher.get_param("jacket_path")
		}
	SceneSwitcher.change_scene("res://scenes/results/results.tscn", data)
	
func pause_game():
	if not get_tree().paused:
		emit_signal("pause")
		get_tree().paused = true
		print($Conductor.song_position)
		$CanvasLayer/PausePopup.show()
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		pause_game()


func _on_PausePopup_restart():
	$Conductor.stop()
	set_process(false)
	
	var chart_data = SceneSwitcher.get_param("chart_data")
	notes_to_spawn = chart_data["notes"].duplicate()
	scrollmod_list = chart_data["timing_points"].duplicate()
	barlines_to_spawn = chart_data["barlines"].duplicate()
	beat_data = chart_data["beats"].duplicate()
	simlines_to_spawn = chart_data["simlines"].duplicate()
	
	for barline in onscreen_barlines:
		barline.queue_free()
	onscreen_barlines = []
	
	for simline in onscreen_simlines:
		simline.queue_free()
	onscreen_simlines = []
	
	for note in onscreen_notes:
		note.queue_free()
	onscreen_notes = []
	
	######## RESET STUFF
	$result_data.reset()
	$CanvasLayer/ComboCounter/ComboCounterLabel.reset()

	yield(get_tree(), "idle_frame")
	set_process(true)
	$Conductor.play_from_beat(0,0)


func _on_PausePopup_quit():
	SceneSwitcher.change_scene("res://scenes/song_select/song_select.tscn")
