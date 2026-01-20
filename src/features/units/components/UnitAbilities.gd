extends Node
class_name UnitAbilities

var ability_slots: Array[AbilityInstance] = []
var unit: Node = null

signal ability_cast(slot_index: int)

func setup(owner_unit: Node):
	unit = owner_unit
	for i in range(6):
		ability_slots.append(null)

func load_abilities_from_resources(ability_resources: Array):
	for i in range(min(ability_resources.size(), 6)):
		if ability_resources[i] is Ability:
			equip_ability(i, ability_resources[i])

func equip_ability(slot: int, ability_resource: Ability):
	if slot < 0 or slot >= 6:
		return
		
	# Cleanup existing ability in this slot
	remove_ability(slot)
	
	if ability_resource == null:
		return

	var instance = AbilityInstance.new(ability_resource, unit)
	add_child(instance)
	ability_slots[slot] = instance
	
	# Connect signal to relay
	instance.ability_used.connect(func(aname): ability_cast.emit(slot))

func remove_ability(slot: int):
	if slot < 0 or slot >= 6:
		return
	
	var existing = ability_slots[slot]
	if existing:
		existing.queue_free()
# Removed const preload to avoid cyclic dependency parser errors
# const CASTING_MANAGER_SCRIPT = preload(...)

func _get_casting_manager():
	var managers = get_tree().get_nodes_in_group("casting_manager")
	if managers.size() > 0:
		return managers[0]
	
	# Fallback: Auto-spawn
	print("⚠️ No CastingManager found in scene. Auto-spawning one...")
	var manager_script = load("res://src/features/abilities/casting/CastingManager.gd")
	if manager_script:
		var new_manager = manager_script.new()
		new_manager.name = "CastingManager"
		get_tree().root.add_child(new_manager)
		
		# Ensure it's in the group
		if not new_manager.is_in_group("casting_manager"):
			new_manager.add_to_group("casting_manager")
			
		return new_manager
	
	print("❌ Failed to load CastingManager script!")
	return null

# Input handling removed. HeroController should call try_cast_ability(slot) directly.

func try_cast_ability(slot: int):
	if slot < 0 or slot >= 6:
		return
	
	var ability_instance = ability_slots[slot]
	if not ability_instance or not ability_instance.can_cast():
		print("❌ Cannot cast ability in slot %d" % slot)
		return
	
	var casting_mgr = _get_casting_manager()
	if casting_mgr:
		print("✅ UnitAbilities: CastingManager found. Requesting cast...")
		casting_mgr.start_casting(ability_instance, unit)
	else:
		print("❌ UnitAbilities: CastingManager NOT FOUND in group 'casting_manager'")

func get_ability(slot: int) -> AbilityInstance:
	if slot >= 0 and slot < 6:
		return ability_slots[slot]
	return null

func is_any_ability_casting() -> bool:
	"""Check if any ability is currently in cast point or channeling"""
	for slot in ability_slots:
		if slot and slot.is_casting():
			return true
	return false
