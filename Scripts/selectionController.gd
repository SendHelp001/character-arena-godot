extends Node3D

@export var selectable_group := "unit"

func _unhandled_input(event):
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
		var multi_select = Input.is_key_pressed(KEY_SHIFT)

		if result:
			var collider = result.collider
			if event.button_index == MOUSE_BUTTON_LEFT:
				if collider.is_in_group(selectable_group):
					# Deselect all others if not multi-selecting
					if not multi_select:
						_deselect_all_except(collider)
					collider.set_selected(true)
					print("Selected:", collider.name)
				else:
					# Clicked on non-selectable object (ground, etc.) - deselect all
					_deselect_all()
					print("Deselected all units (clicked on ground)")
			elif event.button_index == MOUSE_BUTTON_RIGHT:
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
							print("Can't attack friendly unit:", collider.name)
					else:
						print("Right-clicked unit:", collider.name)
				else:
					# Move command for selected units
					for u in selected:
						u.set_move_target(result.position)
		else:
			# Clicked on empty space (no collision) - deselect all if left click
			if event.button_index == MOUSE_BUTTON_LEFT:
				_deselect_all()
				print("Deselected all units (clicked on empty space)")

# Deselect all units
func _deselect_all():
	var selected = get_tree().get_nodes_in_group("selected_unit")
	for u in selected:
		u.set_selected(false)

# Deselect all units except the specified one
func _deselect_all_except(keep_selected):
	var selected = get_tree().get_nodes_in_group("selected_unit")
	for u in selected:
		if u != keep_selected:
			u.set_selected(false)
