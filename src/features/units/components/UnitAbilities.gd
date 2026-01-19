extends Node
class_name UnitAbilities

var ability_slots: Array[AbilityInstance] = []
var unit: Node = null

signal ability_cast(slot_index: int)

const HOTKEYS = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_D, KEY_F]

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
		# output a debug message? "Removing ability X"
		existing.queue_free()
		ability_slots[slot] = null
	


func _get_casting_manager():
	var managers = get_tree().get_nodes_in_group("casting_manager")
	if managers.size() > 0:
		return managers[0]
	return null

func _input(event):
	if not unit or not unit.is_selected():
		return
	
	var casting_mgr = _get_casting_manager()
	if casting_mgr and casting_mgr.is_casting:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		for i in range(HOTKEYS.size()):
			if event.keycode == HOTKEYS[i]:
				try_cast_ability(i)
				get_viewport().set_input_as_handled()
				break

func try_cast_ability(slot: int):
	if slot < 0 or slot >= 6:
		return
	
	var ability_instance = ability_slots[slot]
	if not ability_instance or not ability_instance.can_cast():
		print("❌ Cannot cast ability in slot %d" % slot)
		return
	
	var casting_mgr = _get_casting_manager()
	if casting_mgr:
		casting_mgr.start_casting(ability_instance, unit)

func get_ability(slot: int) -> AbilityInstance:
	if slot >= 0 and slot < 6:
		return ability_slots[slot]
	return null
