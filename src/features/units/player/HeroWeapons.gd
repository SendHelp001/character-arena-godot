extends Node
class_name HeroWeapons

enum WeaponMode { GUN, SWORD }
var current_weapon: WeaponMode = WeaponMode.GUN
var sword_hitbox_size: Vector3 = Vector3(2.0, 2.0, 3.0)

var gun_mesh: MeshInstance3D
var sword_mesh: MeshInstance3D
var character: CharacterBody3D
var unit_combat # Should hold UnitCombat type reference

func setup(p_character: CharacterBody3D, p_combat):
	character = p_character
	unit_combat = p_combat
	_create_weapon_visuals()
	_update_weapon_visuals()

func handle_input(camera: Camera3D, abilities_component):
	if _check_is_casting(abilities_component): return

	if Input.is_action_pressed("fire"):
		_fire(camera)
		
	if Input.is_action_just_pressed("alt_fire"):
		if abilities_component and character.get("active_slot_index") != null:
			# Cast ability from the currently selected slot
			abilities_component.try_cast_ability(character.active_slot_index)

func try_attack_primary(camera: Camera3D):
	_fire(camera)

func swap_weapon():
	if current_weapon == WeaponMode.GUN:
		current_weapon = WeaponMode.SWORD
		print("⚔️ Swapped to SWORD")
	else:
		current_weapon = WeaponMode.GUN
		print("🔫 Swapped to GUN")
	_update_weapon_visuals()

func _fire(camera: Camera3D):
	if not unit_combat: return
	
	var origin = character.global_position + Vector3(0, 1.5, 0)
	if current_weapon == WeaponMode.GUN and gun_mesh:
		origin = gun_mesh.global_position
	elif current_weapon == WeaponMode.SWORD and sword_mesh:
		origin = sword_mesh.global_position
		
	var aim_target = _get_camera_aim_point(camera)
	var aim_dir = (aim_target - origin).normalized()
	
	if current_weapon == WeaponMode.GUN:
		unit_combat.execute_manual_attack(origin, aim_dir)
	elif current_weapon == WeaponMode.SWORD:
		unit_combat.execute_manual_melee_box(origin, aim_dir, sword_hitbox_size)

func _check_is_casting(abilities) -> bool:
	var casting_mgr = get_tree().get_first_node_in_group("casting_manager")
	if casting_mgr and casting_mgr.is_casting: return true
	if abilities and abilities.is_any_ability_casting(): return true
	return false

func _get_camera_aim_point(camera: Camera3D) -> Vector3:
	if not camera: return character.global_position + character.transform.basis.z * 10.0
	
	var viewport = get_viewport()
	var center = viewport.get_visible_rect().size / 2.0
	var ray_len = 1000.0
	var from = camera.project_ray_origin(center)
	var to = from + camera.project_ray_normal(center) * ray_len
	
	var space = character.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [character]
	query.collision_mask = 1 | 4 
	
	var result = space.intersect_ray(query)
	if result: return result.position
	return to

func _create_weapon_visuals():
	gun_mesh = MeshInstance3D.new()
	var gun_box = BoxMesh.new()
	gun_box.size = Vector3(0.1, 0.1, 0.5)
	gun_mesh.mesh = gun_box
	var gun_mat = StandardMaterial3D.new()
	gun_mat.albedo_color = Color.CYAN
	gun_mesh.material_override = gun_mat
	
	sword_mesh = MeshInstance3D.new()
	var sword_box = BoxMesh.new()
	sword_box.size = Vector3(0.1, 0.05, 1.2)
	sword_mesh.mesh = sword_box
	var sword_mat = StandardMaterial3D.new()
	sword_mat.albedo_color = Color.ORANGE
	sword_mesh.material_override = sword_mat
	
	character.add_child(gun_mesh)
	character.add_child(sword_mesh)
	
	# Initial offset (approximate)
	gun_mesh.position = Vector3(0.6, 1.0, -0.5)
	sword_mesh.position = Vector3(0.6, 1.0, -0.5)

func _update_weapon_visuals():
	if gun_mesh: gun_mesh.visible = (current_weapon == WeaponMode.GUN)
	if sword_mesh: sword_mesh.visible = (current_weapon == WeaponMode.SWORD)
