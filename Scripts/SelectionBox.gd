extends Control

# Colors for the selection box
@export var box_color := Color(0, 1, 0, 0.2)  # Transparent green background
@export var border_color := Color(0, 1, 0, 1.0) # Solid green border

var is_dragging := false
var drag_start := Vector2.ZERO
var current_mouse_pos := Vector2.ZERO

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				is_dragging = true
				drag_start = event.position
				current_mouse_pos = event.position
			else:
				# Stop dragging and select units
				if is_dragging:
					is_dragging = false
					queue_redraw()
					_select_units_in_box()

	elif event is InputEventMouseMotion and is_dragging:
		current_mouse_pos = event.position
		queue_redraw()

func _draw():
	if is_dragging:
		var rect = _get_selection_rect()
		draw_rect(rect, box_color)
		draw_rect(rect, border_color, false, 2.0) # Border

func _get_selection_rect() -> Rect2:
	var min_x = min(drag_start.x, current_mouse_pos.x)
	var min_y = min(drag_start.y, current_mouse_pos.y)
	var max_x = max(drag_start.x, current_mouse_pos.x)
	var max_y = max(drag_start.y, current_mouse_pos.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func _select_units_in_box():
	var rect = _get_selection_rect()
	var cam = get_viewport().get_camera_3d()
	
	# If the box is too small, treat it as a single click (handled by raycast in selectionController)
	# BUT, if we want to replace selectionController's left click, we should handle it here.
	# Let's try to handle everything here for consistency, OR delegate single clicks.
	# For now, let's assume if rect area is small, we might want to let raycast handle it?
	# Actually, the user wants "improve unit selection".
	# Let's select all units whose screen position is inside the rect.
	
	var units = get_tree().get_nodes_in_group("unit")
	var selected_count = 0
	
	# Check for Shift key (Multi-select)
	var keep_existing = Input.is_key_pressed(KEY_SHIFT)
	
	if not keep_existing and rect.size.length() > 5.0:
		# Deselect all if making a new box selection
		get_tree().call_group("selected_unit", "set_selected", false)
	
	# If box is tiny, ignore it here and let selectionController handle the precise raycast?
	# The issue is conflict. If I handle Left Click here, selectionController also handles it.
	# I should probably disable Left Click in selectionController if I implement it here.
	# OR, only handle "Box" selection here, and let "Click" selection stay in selectionController.
	
	if rect.size.length() < 5.0:
		# Too small, treat as single click
		# Find the selection controller
		var controller = get_tree().root.find_child("SelectionController", true, false) # Assuming it's named Node3D in World.tscn or we find by script
		# Better way: get it from a known group or path. In World.tscn it is "Node3D".
		# Let's try to find it by type or group if possible.
		# Or just get parent's parent's child? CanvasLayer -> World -> Node3D
		var world = get_parent().get_parent()
		var selection_controller = world.get_node("SelectionController")
		
		if selection_controller and selection_controller.has_method("try_select_at"):
			selection_controller.try_select_at(drag_start, keep_existing)
		return
		
	for unit in units:
		if not unit.is_visible_in_tree():
			continue
			
		var screen_pos = cam.unproject_position(unit.global_position)
		if rect.has_point(screen_pos):
			unit.set_selected(true)
			selected_count += 1
	
	print("Box selected %d units" % selected_count)
