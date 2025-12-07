@tool
extends EditorPlugin

# Ability preview overlay
var overlay: Control = null
var current_ability: Ability = null

func _enter_tree():
	# Create overlay for ability visualization
	overlay = AbilityPreviewOverlay.new()
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_BOTTOM, overlay)
	
	# Connect to editor resource selection
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
	
	print("✨ Ability Visualizer Plugin loaded!")

func _exit_tree():
	if overlay:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_BOTTOM, overlay)
		overlay.queue_free()

func _on_selection_changed():
	var selected = get_editor_interface().get_edited_scene_root()
	if selected:
		# Check if any selected node has Ability resources
		_check_for_abilities(selected)

func _check_for_abilities(node: Node):
	# Check if node is a Unit with abilities
	if node.has_method("get_stats"):
		var stats = node.get("stats_resource")
		if stats and stats is StatData and stats.abilities.size() > 0:
			overlay.show_abilities(stats.abilities)
			return
	
	# Recursively check children
	for child in node.get_children():
		_check_for_abilities(child)

# ------------------------------------------------------------------------------
# Preview Overlay
# ------------------------------------------------------------------------------
class AbilityPreviewOverlay extends Control:
	var abilities: Array = []
	
	func _ready():
		set_anchors_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
	
	func show_abilities(ability_list: Array):
		abilities = ability_list
		queue_redraw()
	
	func _draw():
		if abilities.is_empty():
			return
		
		# Draw ability ranges as colored circles
		var colors = [
			Color(1, 0.3, 0.3, 0.3),  # Red
			Color(0.3, 0.3, 1, 0.3),  # Blue
			Color(0.3, 1, 0.3, 0.3),  # Green
			Color(1, 1, 0.3, 0.3),    # Yellow
		]
		
		var center = size / 2
		var scale_factor = 20.0  # Pixels per game unit
		
		for i in range(min(abilities.size(), 4)):
			var ability = abilities[i]
			if ability and ability is Ability:
				# Draw cast range
				if ability.cast_range > 0:
					var radius = ability.cast_range * scale_factor
					draw_arc(center, radius, 0, TAU, 64, colors[i], 2.0)
					draw_string(ThemeDB.fallback_font, center + Vector2(0, -radius - 10),
								ability.ability_name + " Range: " + str(ability.cast_range),
								HORIZONTAL_ALIGNMENT_CENTER, -1, 12, colors[i])
				
				# Draw AoE radius
				if ability.cast_radius > 0:
					var aoe_radius = ability.cast_radius * scale_factor
					draw_circle(center, aoe_radius, Color(colors[i], 0.5))
