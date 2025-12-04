extends Node

# This script automatically sets up the PlayerUI to track the first selected unit

@onready var player_ui = $PlayerUI

func _ready():
	# Wait a frame for everything to initialize
	await get_tree().process_frame
	
	# Find the Mage (or any player unit)
	var mage = get_tree().get_first_node_in_group("unit")
	
	if mage and player_ui:
		player_ui.track_unit(mage)
		print("PlayerUI tracking: ", mage.name)
	else:
		print("Warning: Could not find unit or PlayerUI")

# Alternative: Track whatever unit gets selected
func _on_unit_selected(unit):
	if player_ui:
		player_ui.track_unit(unit)
