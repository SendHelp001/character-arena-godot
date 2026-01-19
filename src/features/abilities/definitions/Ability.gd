extends Resource
class_name Ability

# Import TargetingType enum
const CastingMode = preload("res://Scripts/AbilityCasting/CastingMode.gd")

# ------------------------------------------------------------------------------
# LIFECYCLE EVENT SIGNALS (Dota 2 Pattern: OnSpellStart, OnChannelFinish, etc.)
# ------------------------------------------------------------------------------
signal on_cast_begin(caster: Node, target_pos: Vector3, level: int)
signal on_cast_point_finish(caster: Node, target_pos: Vector3, level: int)
signal on_channel_tick(caster: Node, elapsed: float, level: int)
signal on_channel_finish(caster: Node, level: int)
signal on_channel_interrupted(caster: Node, level: int)
signal on_cooldown_ready(caster: Node)

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

@export_subgroup("Channel Behavior")
@export var can_move_while_channeling: bool = false  # E.g. Dota's Rearm
@export var can_cast_while_channeling: bool = false  # Rare, e.g. Invoker

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
# HELPER FUNCTIONS (Keep for utility)
# ------------------------------------------------------------------------------

func calculate_value(caster: Node, level: int) -> float:
	"""Calculate ability value based on level and scaling"""
	var total = base_amount + (amount_per_level * (level - 1))
	# Add scaling logic here later (e.g. total += caster.stats.ap * scaling_factor)
	return total

func can_cast(caster: Node, level: int) -> bool:
	"""Check if ability can be cast (mana, cooldown, etc.)"""
	if not caster.has_method("get_stats"): return false
	var stats = caster.get_stats()
	if not stats: return false
	if stats.current_mana < mana_cost: return false
	return true
