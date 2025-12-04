extends Node
class_name UnitSelection

# ------------------------------
# Signals
# ------------------------------
signal selection_changed(unit, is_selected: bool)

# ------------------------------
# References
# ------------------------------
var unit        # Node type
var ring        # Node3D type

# ------------------------------
# State
# ------------------------------
var selected := false

# ------------------------------
# Initialization
# ------------------------------
func setup(p_unit: Node, p_ring: Node3D):
	unit = p_unit
	ring = p_ring
	if ring:
		ring.visible = false

# ------------------------------
# Selection Management
# ------------------------------
func set_selected(state: bool):
	if selected == state:
		return  # No change

	selected = state

	if ring:
		ring.visible = state

	# Add/remove from group for global selection
	if state:
		unit.add_to_group("selected_unit")
	else:
		unit.remove_from_group("selected_unit")

	# Emit signal with unit reference
	selection_changed.emit(unit, state)

# ------------------------------
# Utility Methods
# ------------------------------
func is_selected() -> bool:
	return selected

func toggle_selection():
	set_selected(not selected)

func deselect():
	set_selected(false)
