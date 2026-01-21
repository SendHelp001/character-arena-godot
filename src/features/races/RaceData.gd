extends Resource
class_name RaceData

@export_group("Identity")
@export var id: String = "human"
@export var display_name: String = "Human"
@export_multiline var description: String = "The Adaptables."

@export_group("Stats")
## Base stats for this race (Speed, HP, Mana)
@export var base_stats_template: StatData

@export_group("Physics")
@export var jump_velocity: float = 12.0
@export var air_control: float = 0.3
## Multiplier for gravity. 1.0 = Standard.
@export var gravity_multiplier: float = 1.0
## Check to see if the race can glide when holding jump
## Check to see if the race can glide when holding jump
@export var can_glide: bool = false
## Check to see if the race can dash
@export var can_dash: bool = true

@export_group("Passives")
## TODO: Add passive ability resources or script references here
@export var passive_features: Array[String] = []
