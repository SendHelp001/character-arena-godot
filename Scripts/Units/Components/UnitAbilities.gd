extends Node
class_name UnitAbilities

# Ability slots (6 slots for QWERDF)
var ability_slots: Array[AbilityInstance] = []

# Unit reference
var unit: Node = null

signal ability_cast(slot_index: int)

# Hotkey mapping
const HOTKEYS = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_D, KEY_F]

func setup(owner_unit: Node):
	unit = owner_unit
	
	# Initialize 6 empty slots
	for i in range(6):
		ability_slots.append(null)

func load_abilities_from_resources(ability_resources: Array):
	"""Load abilities from an array of Ability resources"""
	for i in range(min(ability_resources.size(), 6)):
		if ability_resources[i] is Ability:
			equip_ability(i, ability_resources[i])

func equip_ability(slot: int, ability_resource: Ability):
	"""Equip an ability resource to a slot"""
	if slot < 0 or slot >= 6:
		return
	
	# Create instance
	var instance = AbilityInstance.new(ability_resource, unit)
	add_child(instance)
	ability_slots[slot] = instance

func _unhandled_input(event):
	if not unit or not unit.is_selected():
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		for i in range(HOTKEYS.size()):
			if event.keycode == HOTKEYS[i]:
				cast_ability(i)
				break

func cast_ability(slot: int) -> bool:
	if slot < 0 or slot >= 6:
		return false
	
	var ability_instance = ability_slots[slot]
	if not ability_instance:
		return false
	
	# For now, cast at unit's position (no targeting)
	# TODO: Add targeting system for ranged abilities
	var target_pos = unit.global_position
	
	var success = ability_instance.cast(target_pos)
	if success:
		ability_cast.emit(slot)
		print("Cast ability in slot %d: %s" % [slot, ability_instance.ability.ability_name])
	
	return success

func get_ability(slot: int) -> AbilityInstance:
	if slot >= 0 and slot < 6:
		return ability_slots[slot]
	return null
