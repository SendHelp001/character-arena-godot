@tool
extends Node3D
class_name AbilityRoot

# ------------------------------------------------------------------------------
# DATA & STATS
# ------------------------------------------------------------------------------
@export_group("Info")
@export var ability_name: String = "New Ability"
@export var icon: Texture2D = null
@export_enum("Q", "W", "E", "R", "D", "F") var suggested_hotkey: String = "Q"

@export_group("Stats")
@export var cooldown: float = 5.0
@export var mana_cost: float = 50.0
@export var max_level: int = 4

@export_group("Targeting")
@export_enum("NONE:0", "DIRECTIONAL:1", "CIRCULAR:2", "POINT:3") var targeting_mode: int = 1:
	set(value):
		targeting_mode = value
		_update_indicator()

@export var cast_range: float = 10.0:
	set(value):
		cast_range = value
		_update_indicator()

@export var cast_radius: float = 1.0:
	set(value):
		cast_radius = value
		_update_indicator()

@export_group("Mechanics")
@export var cast_point: float = 0.3
@export var requires_turn: bool = true

# ------------------------------------------------------------------------------
# EDITOR VISUALIZATION
# ------------------------------------------------------------------------------
func _ready():
	_update_indicator()

func _process(_delta):
	if Engine.is_editor_hint():
		# Keep indicator updated in editor
		_update_indicator()

func _update_indicator():
	var indicator = get_node_or_null("VisualIndicator")
	if indicator and indicator.has_method("update_visuals"):
		indicator.update_visuals(targeting_mode, cast_range, cast_radius)

# ------------------------------------------------------------------------------
# RUNTIME LOGIC
# ------------------------------------------------------------------------------
func cast(caster: Node, target_pos: Vector3, level: int) -> bool:
	print("✨ Casting Ability Scene: ", ability_name)
	
	# Logic to trigger child components (Damage, Projectiles, etc.)
	# For now, we'll just look for a "Hitbox" or "ProjectileSpawner" child
	
	var projectile_spawner = get_node_or_null("ProjectileSpawner")
	if projectile_spawner and projectile_spawner.has_method("spawn"):
		projectile_spawner.spawn(caster, target_pos, level)
		return true
		
	var hitbox = get_node_or_null("Hitbox")
	if hitbox and hitbox.has_method("activate"):
		hitbox.activate(caster, target_pos, level)
		return true
		
	return true
