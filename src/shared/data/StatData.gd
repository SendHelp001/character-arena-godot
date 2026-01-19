extends Resource
class_name StatData

# Allow editing in the inspector
@export var name: String = "Generic Unit"
@export var max_hp: float = 100.0
@export var max_mana: float = 100.0
@export var mana_regen: float = 1.0      # Mana per second
@export var move_speed: float = 300.0

# Combat Stats
@export var attack_damage: int = 10
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.0
@export var attack_point: float = 0.3    # Windup time before damage (seconds)
@export var armor: float = 0.0

# UI
@export var portrait_icon: Texture2D     # Hero portrait for scoreboard

# Abilities
@export var abilities: Array[Resource] = []  # Array of Ability resources
@export var gold_worth: int = 0
