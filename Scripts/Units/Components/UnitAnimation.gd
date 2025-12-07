extends Node
class_name UnitAnimation

# ------------------------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------------------------
@export var animation_player: AnimationPlayer
@export var movement_component: Node 
@export var combat_component: Node
@export var abilities_component: Node
@export var unit: CharacterBody3D

# ------------------------------------------------------------------------------
# Animation Names (Configurable)
# ------------------------------------------------------------------------------
@export_group("Animations")
@export var anim_idle: String = "standing idle"
@export var anim_run: String = "Running"
@export var anim_attack: String = "Standing 1H Magic Attack 01"
@export var anim_cast: String = "Standing 2H Cast Spell 01"
@export var anim_death: String = "Death" # Ensure this exists or use fallback

# ------------------------------------------------------------------------------
# State
# ------------------------------------------------------------------------------
var current_anim: String = ""
var is_locked: bool = false # For non-interruptible animations like Cast/Attack windup

func _ready():
	# Auto-find dependencies if not set
	if not unit: unit = get_parent()
	if not movement_component: movement_component = unit.get_node_or_null("UnitMovement")
	if not combat_component: combat_component = unit.get_node_or_null("UnitCombat")
	if not abilities_component: abilities_component = unit.get_node_or_null("UnitAbilities")
	
	# Connect signals
	if combat_component and combat_component.has_signal("attack_executed"):
		combat_component.attack_executed.connect(func(target): play_attack())
		
	if abilities_component and abilities_component.has_signal("ability_cast"):
		abilities_component.ability_cast.connect(func(slot): play_cast())
	
	if animation_player:
		play_animation(anim_idle)

func _process(_delta):
	if not animation_player: return
	if is_locked: return # Don't interrupt locked animations
	
	# Priority 1: Movement
	if unit.velocity.length() > 0.1:
		play_animation(anim_run)
	else:
		play_animation(anim_idle)

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------
func play_attack():
	play_animation(anim_attack, true, 0.2) # Lock for windup? Or let combat unlock it?
	# Typically attack anims should play fully or until backswing.
	# For now, let's just play it and unlock after a timer or use signal.
	# Actually, best to just play it and let movement override if user cancels?
	# If we use 'is_locked', we need a way to unlock.
	
	# Let's keep it simple: Attack overrides Idle/Run, but moving overrides Attack (cancellation).
	# So we don't lock for attack, unless we want to forced visual.
	# But user wants "Stop" to cancel, so NOT locking is better.
	play_animation(anim_attack)

func play_cast():
	play_animation(anim_cast)

func play_animation(anim_name: String, lock: bool = false, duration: float = 0.0):
	if current_anim == anim_name and not is_locked: return
	
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name, 0.2) # 0.2 blend time
		current_anim = anim_name
		
		if lock:
			is_locked = true
			if duration > 0:
				await get_tree().create_timer(duration).timeout
				is_locked = false
	else:
		# Warn once
		# print_once("Animation missing: " + anim_name)
		pass
