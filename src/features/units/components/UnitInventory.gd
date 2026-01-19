extends Node
class_name UnitInventory

# Signals
signal artifact_equipped(slot_index: int, artifact: Artifact)
signal artifact_unequipped(slot_index: int, artifact: Artifact)
signal inventory_changed

# Constants
const MAX_SLOTS = 4

# Data
@export var artifacts: Array[Artifact] = []

# Dependencies
var unit: Node
var stats: Stats

func setup(p_unit: Node, p_stats: Stats):
	unit = p_unit
	stats = p_stats
	
	# Initialize slots
	if artifacts.size() != MAX_SLOTS:
		artifacts.resize(MAX_SLOTS)

func equip_artifact(artifact: Artifact, slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	
	# Unequip existing if any
	if artifacts[slot] != null:
		unequip_artifact(slot)
	
	artifacts[slot] = artifact
	inventory_changed.emit()
	artifact_equipped.emit(slot, artifact)
	
	_apply_stat_modifiers(artifact)
	return true

func unequip_artifact(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
		
	var artifact = artifacts[slot]
	if artifact == null:
		return false
		
	artifacts[slot] = null
	inventory_changed.emit()
	artifact_unequipped.emit(slot, artifact)
	
	_remove_stat_modifiers(artifact)
	return true

func _apply_stat_modifiers(artifact: Artifact):
	# TODO: Implement dynamic stat modification
	# Currently Stats.gd might need methods to add/remove modifiers
	pass

func _remove_stat_modifiers(artifact: Artifact):
	# TODO: Implement dynamic stat modification removal
	pass

func get_artifact(slot: int) -> Artifact:
	if slot < 0 or slot >= MAX_SLOTS:
		return null
	return artifacts[slot]
