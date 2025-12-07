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
	if combat_component:
		if combat_component.has_signal("attack_windup_started"):
			combat_component.attack_windup_started.connect(func(target): play_attack())
		
	# Connect to ability lifecycle events
	if abilities_component:
		# Get all ability slots and connect to their events
		for slot_idx in range(6):
			var ability_inst = abilities_component.get_ability(slot_idx)
			if ability_inst and ability_inst.ability:
				# Connect to cast_begin to play casting animation
				ability_inst.ability.on_cast_begin.connect(_on_ability_cast_begin)
	
	if animation_player:
		play_animation(anim_idle)

func _on_ability_cast_begin(caster: Node, target_pos: Vector3, level: int):
	"""Play cast animation when ability casting begins"""
	play_cast()

func _process(_delta):
	if not animation_player: return
	if is_locked: return # Don't interrupt locked animations
	
	# Priority 1: Movement
	if unit.velocity.length() > 0.1:
		play_animation(anim_run)
	else:
		# If we are not moving, we might be attacking (winding up).
		# We need to be careful not to switch to IDLE if we are winding up.
		# UnitCombat manages windup_timer, but UnitMovement manages velocity.
		# If windup is active, velocity should be 0 (we stop movement).
		# So we need to know if we are in windup to avoid overriding with Idle.
		# Or, play_attack sets a flag?
		
		# For now, let's rely on 'current_anim' priority or explicit state.
		# Ideally, play_attack sets 'current_anim' to attack.
		# If velocity is 0, we fall through here.
		# We should only play idle if NOT playing attack.
		# But 'play_animation' checks 'if current_anim == anim_name'.
		# The issue is _process runs every frame.
		
		# If we just started attack, current_anim is 'attack'.
		# velocity is 0.
		# this else block runs.
		# calls play_animation(anim_idle).
		# checks if current_anim == anim_idle? No.
		# Plays idle. Overrides attack immediately.
		
		# Fix: Check if attack animation is playing and still valid?
		# Or just check if combat is aggressive/winding up?
		
		var is_winding_up = false
		if combat_component and "windup_timer" in combat_component and combat_component.windup_timer > 0:
			is_winding_up = true
			
		if not is_winding_up and current_anim != anim_attack: # Basic check
			play_animation(anim_idle)
		# If winding up, do nothing (let attack play)
		# If attack anim finished but still winding up (unlikely for short anims), loop?
		# Usually anim duration > windup.

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------
func play_attack():
	# Play attack animation.
	# We don't lock it because we want it cancellable by movement (velocity > 0 check in _process).
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
