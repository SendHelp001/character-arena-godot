extends Resource
class_name Ability

# Import TargetingType enum
const CastingMode = preload("res://Scripts/AbilityCasting/CastingMode.gd")

# ------------------------------------------------------------------------------
# 1. VISUALS & INFO
# ------------------------------------------------------------------------------
@export_group("Visuals")
@export var ability_name: String = "Unnamed Ability"
@export_multiline var description: String = "No description"
@export var icon: Texture2D = null
@export_enum("Q", "W", "E", "R", "D", "F") var suggested_hotkey: String = "Q"

# ------------------------------------------------------------------------------
# 2. CORE STATS
# ------------------------------------------------------------------------------
@export_group("Stats")
@export var cooldown: float = 5.0
@export var mana_cost: float = 50.0
@export var max_level: int = 4

# ------------------------------------------------------------------------------
# 3. TARGETING & RANGE
# ------------------------------------------------------------------------------
@export_group("Targeting")
@export_enum("NONE:0", "DIRECTIONAL:1", "CIRCULAR:2", "POINT:3", "UNIT_TARGET:4") 
var targeting_mode: int = 0  # Default: NONE

@export var cast_range: float = 10.0  # Max range
@export var cast_radius: float = 0.0  # AoE radius (for Circular/Point)
@export var projectile_scene: PackedScene = null # For Directional/Targeted projectiles

# ------------------------------------------------------------------------------
# 4. MECHANICS (Dota/League Hybrid)
# ------------------------------------------------------------------------------
@export_group("Mechanics")
@export var cast_point: float = 0.0  # Windup time
@export var requires_turn: bool = true  # Must face target?
@export var channel_duration: float = 0.0 # If > 0, is a channel

# ------------------------------------------------------------------------------
# 5. EFFECTS & SCALING
# ------------------------------------------------------------------------------
@export_group("Effects")
@export_enum("DAMAGE", "HEAL", "BUFF", "DEBUFF", "CC") var effect_type: String = "DAMAGE"
@export_enum("PHYSICAL", "MAGICAL", "TRUE") var damage_type: String = "MAGICAL"

@export_subgroup("Values")
@export var base_amount: float = 50.0 # Base Damage/Heal
@export var amount_per_level: float = 25.0 # Scaling per level
@export var scaling_factor: float = 0.0 # % of stats (e.g. 0.8 for 80% AP)

@export_subgroup("Crowd Control")
@export var cc_duration: float = 0.0
@export var cc_value: float = 0.0 # e.g. Slow %

# ------------------------------------------------------------------------------
# LOGIC
# ------------------------------------------------------------------------------

# Main entry point for casting
# If a derived script overrides this, it takes full control.
# Otherwise, this generic logic runs.
func _cast(caster: Node, target_pos: Vector3, level: int) -> bool:
	# 1. Handle Projectiles (Directional)
	if targeting_mode == CastingMode.TargetingType.DIRECTIONAL and projectile_scene:
		_spawn_projectile(caster, target_pos, level)
		return true
		
	# 2. Handle Instant AoE (Circular/Point)
	if targeting_mode == CastingMode.TargetingType.CIRCULAR or targeting_mode == CastingMode.TargetingType.POINT:
		_apply_aoe_effect(caster, target_pos, level)
		return true
		
	# 3. Handle Unit Target (Not implemented yet, but placeholder)
	if targeting_mode == CastingMode.TargetingType.UNIT_TARGET:
		# Logic to find unit at target_pos would go here
		pass
		
	return true

# --- Helper Functions ---

func _spawn_projectile(caster: Node, target_pos: Vector3, level: int):
	if not projectile_scene: return
	
	var projectile = projectile_scene.instantiate()
	caster.get_tree().root.add_child(projectile)
	
	# Setup projectile transform
	var spawn_pos = caster.global_position + Vector3(0, 1, 0) # Waist height
	projectile.global_position = spawn_pos
	projectile.look_at(Vector3(target_pos.x, spawn_pos.y, target_pos.z), Vector3.UP)
	
	# Pass data to projectile if it has a setup method
	if projectile.has_method("setup"):
		var dmg = calculate_value(caster, level)
		projectile.setup(caster, dmg, cast_range, 20.0) # Speed hardcoded for now or add export

func _apply_aoe_effect(caster: Node, center: Vector3, level: int):
	# Find units in radius
	var space_state = caster.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = cast_radius
	query.shape = shape
	query.transform = Transform3D(Basis(), center)
	query.collision_mask = 2 # Assume layer 2 is units, or use a variable
	
	var results = space_state.intersect_shape(query)
	var value = calculate_value(caster, level)
	
	for result in results:
		var unit = result.collider
		if _is_valid_target(caster, unit):
			_apply_to_unit(caster, unit, value)

func _apply_to_unit(caster: Node, target: Node, value: float):
	if effect_type == "DAMAGE":
		if target.has_method("take_damage"):
			target.take_damage(value)
			print("💥 Dealt %d %s damage to %s" % [value, damage_type, target.name])
	elif effect_type == "HEAL":
		# Implement heal logic
		pass

func _is_valid_target(caster: Node, target: Node) -> bool:
	if not target.is_in_group("unit"): return false
	if target == caster: return false # Don't hit self with damage usually
	
	# Check teams
	if caster.has_method("get_team_id") and target.has_method("get_team_id"):
		if effect_type == "DAMAGE" or effect_type == "DEBUFF" or effect_type == "CC":
			return caster.get_team_id() != target.get_team_id() # Enemy
		else:
			return caster.get_team_id() == target.get_team_id() # Ally
			
	return true

func calculate_value(caster: Node, level: int) -> float:
	var total = base_amount + (amount_per_level * (level - 1))
	# Add scaling logic here later (e.g. total += caster.stats.ap * scaling_factor)
	return total

# Can this ability be cast?
func can_cast(caster: Node, level: int) -> bool:
	if not caster.has_method("get_stats"): return false
	var stats = caster.get_stats()
	if not stats: return false
	if stats.current_mana < mana_cost: return false
	return true
