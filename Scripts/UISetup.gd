extends Node

# Dynamic UI setup - tracks whatever unit is selected

@onready var player_ui = $PlayerUI

var currently_tracked_unit: Unit = null
var connected_units: Dictionary = {}  # Track which units we've connected to

func _ready():
	# Hide UI initially (nothing selected)
	if player_ui:
		player_ui.visible = false
	
	# Wait a frame for all nodes to be ready
	await get_tree().process_frame
	
	# Connect to existing units
	_connect_to_existing_units()
	
	# Connect to future units
	get_tree().node_added.connect(_on_node_added)

func _connect_to_existing_units():
	# Find all existing units and connect to their selection signals
	var units = get_tree().get_nodes_in_group("unit")
	for unit in units:
		if unit is Unit:
			_connect_to_unit(unit)

func _on_node_added(node):
	# Connect to newly added units
	if node is Unit:
		_connect_to_unit(node)

func _connect_to_unit(unit: Unit):
	# Check if already connected using dictionary
	if connected_units.has(unit):
		return
	
	var selection_component = unit.get_selection()
	if selection_component:
		selection_component.selection_changed.connect(_on_unit_selection_changed)
		connected_units[unit] = true
		print("Connected to unit: ", unit.name, " (Team: ", unit.team_id, ")")

func _on_unit_selection_changed(unit: Unit, is_selected: bool):
	if is_selected:
		# Show UI and track this unit (any team, like Dota 2)
		if player_ui:
			player_ui.visible = true
			player_ui.track_unit(unit)
			currently_tracked_unit = unit
			print("UI now tracking: ", unit.name, " (Team: ", unit.team_id, ")")
	else:
		# If this was our tracked unit, hide UI
		if unit == currently_tracked_unit:
			if player_ui:
				player_ui.visible = false
				currently_tracked_unit = null
			print("UI hidden (unit deselected)")
