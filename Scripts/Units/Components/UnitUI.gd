extends Node
class_name UnitUI

# -------------------------------------------------------------------
# CONSTANTS — Team Colors (adjust as you like)
# -------------------------------------------------------------------
const TEAM_COLORS := {
	0: Color(0.2, 0.8, 1.0),   # Player Team - Cyan
	1: Color(1.0, 0.3, 0.3),   # Enemy Team  - Red
	2: Color(1.0, 1.0, 1.0),   # Neutral     - White
}

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------
var stats              # Stats component
var stats_label        # Label3D (floating HP text)
var team_id: int = 0

# Cached (for optimization)
var team_color := Color.WHITE

# -------------------------------------------------------------------
# Initialization
# -------------------------------------------------------------------
func setup(p_stats, p_label: Label3D, p_team_id: int):
	stats = p_stats
	stats_label = p_label
	team_id = p_team_id

	team_color = TEAM_COLORS.get(team_id, Color.WHITE)

	if stats_label:
		stats_label.modulate = team_color
		stats_label.visible = true   # hidden until selected or hovered

	update_display() # initialize UI immediately

# -------------------------------------------------------------------
# UI Updating
# -------------------------------------------------------------------
func update_display():
	if not stats or not stats.stat_data or not stats_label:
		return

	stats_label.text = _build_stats_text()

func _build_stats_text() -> String:
	if not stats or not stats.stat_data:
		return ""
	
	var stat_data = stats.stat_data
	var unit_name = stat_data.name if stat_data.name else "Unit"
	
	return "%s\nHP: %.0f/%.0f\nMP: %.0f/%.0f" % [
		unit_name,
		stats.current_hp, stat_data.max_hp,
		stats.current_mana, stat_data.max_mana
	]


# -------------------------------------------------------------------
# Visibility Control
# -------------------------------------------------------------------
func set_label_visible(visible: bool):
	if stats_label:
		stats_label.visible = visible

# -------------------------------------------------------------------
# Reactions to Damage / Healing
# -------------------------------------------------------------------
func on_health_changed():
	update_display()

func on_mana_changed():
	update_display()
