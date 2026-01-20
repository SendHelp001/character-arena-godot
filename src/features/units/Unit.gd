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
# Component references
# ------------------------------
var movement: Node
var combat: UnitCombat
var selection: UnitSelection
var ui: UnitUI
var abilities: UnitAbilities
var inventory: UnitInventory

var ring: Node3D
var stats_label: Node3D

# UI Components
# const HEALTH_BAR_SCENE = preload("res://Scenes/UI/UnitHealthBar.tscn")
# const DAMAGE_NUMBER_SCENE = preload("res://Scenes/UI/DamageNumber.tscn")
const HEALTH_BAR_SCENE = preload("res://src/ui/components/UnitHealthBar.tscn")
const DAMAGE_NUMBER_SCENE = preload("res://src/ui/components/DamageNumber.tscn")
var health_bar: Node3D = null

# ------------------------------
# Initialization
# ------------------------------
func _ready():
	add_to_group("unit")
	
	# Resolve components safely
	ring = get_node_or_null("SelectionRing")
	stats_label = get_node_or_null("StatsLabel")
	movement = get_node_or_null("UnitMovement")
	combat = get_node_or_null("UnitCombat")
	selection = get_node_or_null("UnitSelection")
	ui = get_node_or_null("UnitUI")
	abilities = get_node_or_null("UnitAbilities")
	inventory = get_node_or_null("UnitInventory")
	
	# Initialize Stats component
	stats = Stats.new()
	stats.stat_data = stats_resource
	add_child(stats)
	stats._ready()
	
	if not stats_resource:
		push_warning("Unit has no StatData assigned!")
	
	# Create health bar
	_create_health_bar()
	
	# Connect to damage signal for damage numbers
	if stats:
		stats.damage_taken.connect(_on_damage_taken)
	
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

	# Setup Inventory
	if inventory:
		inventory.setup(self, stats)
		inventory.artifact_equipped.connect(_on_artifact_equipped)
		inventory.artifact_unequipped.connect(_on_artifact_unequipped)

# ------------------------------
# Inventory Callbacks
# ------------------------------
func _on_artifact_equipped(slot: int, artifact: Artifact):
	print("Unit %s equipped %s in slot %d" % [name, artifact.name, slot])
	if abilities and artifact.granted_ability:
		# Map inventory slot to ability slot directly for now
		abilities.equip_ability(slot, artifact.granted_ability)

func _on_artifact_unequipped(slot: int, artifact: Artifact):
	print("Unit %s unequipped %s from slot %d" % [name, artifact.name, slot])
	if abilities:
		abilities.remove_ability(slot)

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
	# combat.set_aggressive_mode(false) Removed in Brawler Refactor

func set_follow_target(target_unit: Node):
	"""Command this unit to follow another unit"""
	if movement:
		movement.set_follow_target(target_unit)
	# Following switches to passive mode
	# combat.set_aggressive_mode(false) Removed in Brawler Refactor

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
# UI Helpers
# ------------------------------
func _create_health_bar():
	"""Create and position health bar above unit"""
	# Don't show health bar for player (team 0)
	if team_id == 0:
		return

	if HEALTH_BAR_SCENE:
		health_bar = HEALTH_BAR_SCENE.instantiate()
		add_child(health_bar)
		health_bar.position = Vector3(0, 2.5, 0)  # Above head
		
		if stats:
			health_bar.setup(self)

func _on_damage_taken(amount: float, damage_type: String):
	"""Spawn damage number popup"""
	if DAMAGE_NUMBER_SCENE:
		var damage_num = DAMAGE_NUMBER_SCENE.instantiate()
		get_tree().current_scene.add_child(damage_num)
		damage_num.global_position = global_position + Vector3(0, 2, 0)
		damage_num.setup(amount, damage_type)

# ------------------------------
# Public API - Stats & Abilities
# ------------------------------
func get_stats() -> Stats:
	return stats

func get_team_id() -> int:
	return team_id

func get_abilities() -> UnitAbilities:
	return abilities

func get_movement():
	return movement
