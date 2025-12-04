extends Camera3D

@export var pan_speed := 20.0        # Camera movement speed
@export var zoom_speed := 5.0        # Scroll wheel zoom speed
@export var min_height := 5.0        # Min Y
@export var max_height := 50.0       # Max Y
@export var edge_scroll_margin := 20 # Pixels from screen edge to start scrolling

func _process(delta):
	var input_dir = Vector3.ZERO
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size

	# EDGE SCROLL
	if mouse_pos.x <= edge_scroll_margin:
		input_dir.x -= 1
	elif mouse_pos.x >= viewport_size.x - edge_scroll_margin:
		input_dir.x += 1

	if mouse_pos.y <= edge_scroll_margin:
		input_dir.z -= 1
	elif mouse_pos.y >= viewport_size.y - edge_scroll_margin:
		input_dir.z += 1

	# KEYBOARD SCROLL (optional)
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1

	if input_dir != Vector3.ZERO:
		# Move in XZ plane
		var move = input_dir.normalized() * pan_speed * delta
		global_position += Vector3(move.x, 0, move.z)

func _unhandled_input(event):
	# Zoom
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			global_position.y = max(min_height, global_position.y - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			global_position.y = min(max_height, global_position.y + zoom_speed)
