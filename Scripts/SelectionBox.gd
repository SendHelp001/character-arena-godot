extends Control

# Colors for the selection box
@export var box_color := Color(0, 0, 0, 0)  # Transparent green background
@export var border_color := Color(0, 1, 0, 1.0) # Solid green border

var is_dragging := false
var drag_start := Vector2.ZERO
var current_mouse_pos := Vector2.ZERO

func _input(event):
	# Skip if casting (check via group)
	var casting_mgr = get_tree().get_first_node_in_group("casting_manager")
	if casting_mgr and casting_mgr.is_casting:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check if mouse is over UI before starting drag
				var mouse_pos = get_viewport().get_mouse_position()
				var player_ui = get_tree().get_first_node_in_group("player_ui")
				if player_ui and player_ui is CanvasLayer:
					for child in player_ui.get_children():
						if child is Control and child.visible:
							var rect = child.get_global_rect()
							if rect.has_point(mouse_pos):
								return # Ignore click, mouse is over UI
				
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

	elif event is InputEventMouseMotion:
		if is_dragging:
			# Only update if mouse actually moved significantly
			var delta = event.position - current_mouse_pos
			if delta.length() > 2.0:  # Only redraw if moved more than 2 pixels
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
	
	var units = get_tree().get_nodes_in_group("unit")
	var selected_count = 0
	
	# Check for Shift key (Multi-select)
	var keep_existing = Input.is_key_pressed(KEY_SHIFT)
	
	if not keep_existing and rect.size.length() > 5.0:
		# Deselect all if making a new box selection
		get_tree().call_group("selected_unit", "set_selected", false)
	
	if rect.size.length() < 5.0:
		# Too small, treat as single click
		var controller = get_tree().root.find_child("SelectionController", true, false)
		var world = get_parent().get_parent()
		var selection_controller = world.get_node("SelectionController")
		
		if selection_controller and selection_controller.has_method("try_select_at"):
			selection_controller.try_select_at(drag_start, keep_existing)
		return
	
	# Track which units we've already processed to avoid duplicates
	var processed_units = []
	
	for unit in units:
		# Skip if already processed
		if unit in processed_units:
			continue
			
		if not unit.is_visible_in_tree():
			continue
			
		var screen_pos = cam.unproject_position(unit.global_position)
		if rect.has_point(screen_pos):
			# Only select if not already selected (prevents spam)
			if not unit.is_selected():
				unit.set_selected(true)
				selected_count += 1
			processed_units.append(unit)
	
	if selected_count > 0:
		print("Box selected %d units" % selected_count)
