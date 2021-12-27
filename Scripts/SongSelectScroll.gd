extends ScrollContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_SongSelectScroll_scroll_started():
	print("scrolling!")


func _on_SongSelectScroll_scroll_ended():
	var max_value = max(0, $VBoxContainer.rect_size.y - rect_size.y)
	print("scroll ended! v_scroll = %s, max = %s" % [get_v_scroll(), max_value])
	
	# 1. get center of scroll box using height of scroll container
	# 2. get coordinate of center, relative to the VBoxContainer
	# 3. find the item with a center nearest to this number
	# 4. set the v_scroll with some math
