extends Node
class_name UnitUI

# ------------------------------
# References
# ------------------------------
var stats  # Stats type
var stats_label  # Label3D type

# ------------------------------
# Initialization
# ------------------------------
func setup(p_stats, p_label):
	stats = p_stats
	stats_label = p_label

# ------------------------------
# Display Updates
# ------------------------------
func update_display():
	if not stats or not stats.stat_data or not stats_label:
		return
	
	var unit_name = stats.stat_data.name if stats.stat_data.name else "Unit"
	stats_label.text = "%s\nHP: %d/%d\nMP: %d/%d" % [
		unit_name,
		stats.current_hp, stats.stat_data.max_hp,
		int(stats.current_mana), stats.stat_data.mana
	]

func set_label_visible(visible: bool):
	if stats_label:
		stats_label.visible = visible
