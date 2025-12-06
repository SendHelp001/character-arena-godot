extends Node3D

@export var selectable_group := "unit"

func _unhandled_input(event):
	# Skip if casting (check via group)
	var casting_mgr = get_tree().get_first_node_in_group("casting_manager")
	if casting_mgr and casting_mgr.is_casting:
		return
	
	# Handle Stop command (S key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		var selected = get_tree().get_nodes_in_group("selected_unit")
		if selected.size() > 0:
			for u in selected:
				if u.has_method("stop_all_actions"):
					u.stop_all_actions()
			print("Stopped all actions for %d unit(s)" % selected.size())
		return
	
	if event is InputEventMouseButton and event.pressed:
		var cam = get_viewport().get_camera_3d()
		if cam == null:
			return

		var mouse_pos = get_viewport().get_mouse_position()
		var origin = cam.project_ray_origin(mouse_pos)
		var dir = cam.project_ray_normal(mouse_pos)

		var ray = PhysicsRayQueryParameters3D.new()
		ray.from = origin
		ray.to = origin + dir * 2000

		var result = get_viewport().get_world_3d().direct_space_state.intersect_ray(ray)

		# Check if shift is held for multi-select
		var _multi_select = Input.is_key_pressed(KEY_SHIFT)

		if result:
			var collider = result.collider

			# RIGHT-CLICK COMMANDS
			if event.button_index == MOUSE_BUTTON_RIGHT:
				var selected = get_tree().get_nodes_in_group("selected_unit")
				if selected.size() == 0:
					return
				
				if collider.is_in_group(selectable_group):
					# Right-clicked on a unit - check if it's an enemy
					if selected[0].has_method("get_team_id") and collider.has_method("get_team_id"):
						var team_id = selected[0].get_team_id()
						var target_team_id = collider.get_team_id()
						
						if target_team_id != team_id:
							# Attack command - enemy unit
							for u in selected:
								if u.has_method("set_combat_target"):
									u.set_combat_target(collider)
							print("Attack command issued on:", collider.name)
						else:
							# Follow command - friendly unit
							for u in selected:
								if u.has_method("set_follow_target"):
									u.set_follow_target(collider)
							print("Follow command issued on ally:", collider.name)
					else:
						print("Right-clicked unit:", collider.name)
				else:
					# Move command for selected units
					_move_units_with_formation(selected, result.position)

# -----------------------------
# SELECTION (Single Click)
# -----------------------------
func try_select_at(screen_pos: Vector2, multi_select: bool = false):
	var cam = get_viewport().get_camera_3d()
	if cam == null: 
		return

	var origin = cam.project_ray_origin(screen_pos)
	var dir = cam.project_ray_normal(screen_pos)

	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = origin
	ray.to = origin + dir * 2000

	var result = get_viewport().get_world_3d().direct_space_state.intersect_ray(ray)
	
	if result:
		var collider = result.collider
		if collider.is_in_group(selectable_group):
			# Deselect all others if not multi-selecting
			if not multi_select:
				_deselect_all_except(collider)
			collider.set_selected(true)
			print("Selected:", collider.name)
		else:
			if not multi_select:
				_deselect_all()
				print("Deselected all units (clicked on ground)")
	else:
		if not multi_select:
			_deselect_all()
			print("Deselected all units (clicked on empty space)")

# -----------------------------
# MOVEMENT WITH FORMATION
# -----------------------------
func _move_units_with_formation(units: Array, center_pos: Vector3):
	if units.size() == 0:
		return
	
	if units.size() == 1:
		units[0].set_move_target(center_pos)
		return
	
	var spread_radius = 0.9
	var angle_step = TAU / units.size()
	
	for i in range(units.size()):
		var angle = angle_step * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * spread_radius
		var target_pos = center_pos + offset
		units[i].set_move_target(target_pos)

# -----------------------------
# DESELECTION HELPERS
# -----------------------------
func _deselect_all():
	var selected = get_tree().get_nodes_in_group("selected_unit")
	for u in selected:
		u.set_selected(false)

func _deselect_all_except(keep_selected):
	var selected = get_tree().get_nodes_in_group("selected_unit")
	for u in selected:
		if u != keep_selected:
			u.set_selected(false)
