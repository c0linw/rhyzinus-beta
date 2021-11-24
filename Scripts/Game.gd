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

var onscreen_notes: Array = []
var onscreen_slides: Array = []
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

# Called when the node enters the scene tree for the first time.
func _ready():
	######## TODO: set options by passing them in
	note_speed = 3.0
	lane_depth = 24.0
	
	######## SETUP OBJECTS
	base_note_screen_time = (12.0 - note_speed) / 2.0 # TODO: find formula that scales better
	
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
	
	######## SETUP INPUT
	input_offset = options["input_offset"]
	setup_input()
	setup_lane_effects()
	setup_judgement_textures()
	
	var view_coords = get_viewport().size
	var comboPosX = view_coords.x/2 - $CanvasLayer/ComboCounter.get_rect().size.x/2
	var comboPosY = upper_lane_left.y + (lower_lane_left.y - upper_lane_left.y)*0.3 - $CanvasLayer/ComboCounter.get_rect().size.y/2
	$CanvasLayer/ComboCounter.set_global_position(Vector2(comboPosX, comboPosY))
	
	$Conductor.set_bpm(starting_bpm)
	$Conductor.stream = load("res://Songs/neutralizeptbmix/neutralizeptbmix.mp3")
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
			
	for note in onscreen_notes:
		if timestamp >= note.time + note.late_cracked:
			var result = {"judgement": ENCRYPTED, "offset": 0}
			draw_judgement(result, note.lane)
			emit_signal("note_judged", result)
			delete_note(note)
		else:
			note.render(chart_position, lane_depth, base_note_screen_time)
		
	# reset then update
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

func _input(event):
	if event is InputEventScreenTouch:
		$Conductor.update_song_position()
		var event_time = $Conductor.song_position
		if event.pressed: # tap
			touch_bindings[event.index] = event
			for note in onscreen_notes:
				if note.can_judge(event_time):
					var result: Dictionary = note.judge(event_time)
					draw_judgement(result, note.lane)
					emit_signal("note_judged", result)
					delete_note(note)
					return
		else: # touch release
			touch_bindings[event.index] = null
			return
	elif event is InputEventScreenDrag:
		touch_bindings[event.index] = event
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

func _on_Conductor_finished():
	pass # Replace with function body.
