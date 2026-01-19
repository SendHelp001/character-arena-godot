extends Node
class_name UnitSelection

var unit: Node
var selection_ring: Node3D
var _selected: bool = false

func setup(p_unit: Node, p_ring: Node3D):
	unit = p_unit
	selection_ring = p_ring
	set_selected(false)

func set_selected(state: bool):
	_selected = state
	if selection_ring:
		selection_ring.visible = state

func is_selected() -> bool:
	return _selected
