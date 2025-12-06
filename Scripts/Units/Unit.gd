extends CharacterBody3D
class_name Unit

# ------------------------------
# Stats & Team
# ------------------------------
@export var stats_resource: StatData    # assign StatData resource in inspector
@export var team_id: int = 0            # 0 = player, 1 = enemy, 2 = neutral

var stats: Stats                         # runtime Stats component

# ------------------------------
# Node references
# ------------------------------
@onready var ring := $SelectionRing
@onready var stats_label := $StatsLabel

# Component references
# ------------------------------
@onready var movement = $UnitMovement
@onready var combat: UnitCombat = $UnitCombat
@onready var selection: UnitSelection = $UnitSelection
@onready var ui: UnitUI = $UnitUI
@onready var abilities: UnitAbilities = $UnitAbilities


# ------------------------------
# Initialization
# ------------------------------
func _ready():
	add_to_group("unit")
	
	# Initialize Stats component
	stats = Stats.new()
	stats.stat_data = stats_resource
	add_child(stats)
	stats._ready()
	
	if not stats_resource:
		push_warning("Unit has no StatData assigned!")
	
	# Setup components
	if movement:
		movement.setup(self, stats, null) # Agent is handled internally or removed
	
	if combat:
		combat.setup(self, stats, movement)
	
	if selection:
		selection.setup(self, ring)
	
	if ui:
		ui.setup(stats, stats_label, team_id)
	
	# Setup abilities
	if abilities:
		abilities.setup(self)
		# Load abilities from stats resource
		if stats_resource and stats_resource.abilities.size() > 0:
			abilities.load_abilities_from_resources(stats_resource.abilities)

# ------------------------------
# Physics Process
# ------------------------------
func _physics_process(delta):
	if movement:
		movement.process_movement(delta)
	
	if combat:
		combat.process_combat(delta)
	
	if ui:
		ui.update_display()

# ------------------------------
# Public API - Movement
# ------------------------------
func set_move_target(pos: Vector3):
	if movement:
		movement.set_target_position(pos)
	# Moving switches to passive mode (stops auto-attacking)
	if combat:
		combat.set_aggressive_mode(false)

func set_follow_target(target_unit: Node):
	"""Command this unit to follow another unit"""
	if movement:
		movement.set_follow_target(target_unit)
	# Following switches to passive mode
	if combat:
		combat.set_aggressive_mode(false)

func stop_all_actions():
	"""Stop all movement and combat actions"""
	if movement:
		movement.stop_movement()
	if combat:
		combat.stop_all_actions()

# ------------------------------
# Public API - Selection
# ------------------------------
func set_selected(state: bool):
	if selection:
		selection.set_selected(state)

func is_selected() -> bool:
	return selection.is_selected() if selection else false

func get_selection():
	return selection

# ------------------------------
# Public API - Combat
# ------------------------------
func set_combat_target(target_node: Node):
	if combat:
		combat.set_target(target_node)

func get_current_target() -> Node:
	return combat.get_current_target() if combat else null

# ------------------------------
# Damage Handling
# ------------------------------
func take_damage(amount):
	if stats:
		stats.take_damage(amount)
		print("Unit %s took %d damage, HP now: %d" % [name, amount, stats.current_hp])
		if stats.current_hp <= 0:
			queue_free()

# ------------------------------
# Public API - Stats & Abilities
# ------------------------------
func get_stats() -> Stats:
	return stats

func get_abilities() -> UnitAbilities:
	return abilities

func get_team_id() -> int:
	return team_id
