extends Control

const SLOT_SCENE = preload("res://src/ui/components/InventorySlot.tscn")

@onready var grid_container = $GridContainer

var inventory_ref: UnitInventory

func setup(inventory: UnitInventory):
	inventory_ref = inventory
	if inventory_ref:
		inventory_ref.artifact_equipped.connect(_on_artifact_equipped)
		inventory_ref.artifact_unequipped.connect(_on_artifact_unequipped)
		_initialize_slots()

func _initialize_slots():
	# Clear existing
	for child in grid_container.get_children():
		child.queue_free()
	
	# Create slots based on inventory size
	if inventory_ref:
		for i in range(inventory_ref.MAX_SLOTS):
			var slot = SLOT_SCENE.instantiate()
			grid_container.add_child(slot)
			slot.update_slot(inventory_ref.get_artifact(i))

func _on_artifact_equipped(slot_index: int, artifact: Artifact):
	_update_slot_at(slot_index)

func _on_artifact_unequipped(slot_index: int, artifact: Artifact):
	_update_slot_at(slot_index)

func select_slot(index: int):
	var slots = grid_container.get_children()
	for i in range(slots.size()):
		if i == index:
			slots[i].set_selected(true)
		else:
			slots[i].set_selected(false)

func _update_slot_at(index: int):
	var slots = grid_container.get_children()
	if index >= 0 and index < slots.size():
		var artifact = inventory_ref.get_artifact(index)
		slots[index].update_slot(artifact)
