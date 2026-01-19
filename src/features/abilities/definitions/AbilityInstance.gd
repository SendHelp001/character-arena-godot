extends Node
class_name AbilityInstance

# ------------------------------------------------------------------------------
# CASTING STATE MACHINE (Dota 2 Pattern)
# ------------------------------------------------------------------------------
enum CastState {
	IDLE,           # Not casting
	TURNING,        # Rotating to face target (if requires_turn)
	CAST_POINT,     # Windup before effect fires
	CHANNELING,     # Locked channeling after effect
	COMPLETED       # Cast finished, going back to IDLE
}

# ------------------------------------------------------------------------------
# References
# ------------------------------------------------------------------------------
var ability: Ability = null          # Reference to the ability template
var caster: Node = null             # Reference to the unit casting
var casting_bar: Control = null     # UI element for casting/channeling

# Casting bar scene
const CASTING_BAR_SCENE = preload("res://src/ui/components/CastingBar.tscn")

# ------------------------------------------------------------------------------
# Runtime State
# ------------------------------------------------------------------------------
var current_level: int = 1
var current_cooldown: float = 0.0

var cast_state: CastState = CastState.IDLE
var pending_target: Vector3 = Vector3.ZERO

# Timing
var cast_point_timer: float = 0.0
var channel_timer: float = 0.0
var channel_elapsed: float = 0.0

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal cooldown_changed(remaining: float, total: float)
signal level_changed(new_level: int)
signal ability_used(ability_name: String)

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------
func _init(ability_resource: Ability = null, owner_unit: Node = null):
	ability = ability_resource
	caster = owner_unit

# ------------------------------------------------------------------------------
# Process Loop
# ------------------------------------------------------------------------------
func _process(delta: float):
	# Cooldown Management
	if current_cooldown > 0.0:
		current_cooldown = max(0.0, current_cooldown - delta)
		cooldown_changed.emit(current_cooldown, ability.cooldown if ability else 1.0)
		
		if current_cooldown <= 0.0 and ability:
			ability.on_cooldown_ready.emit(caster)
	
	# Casting State Machine
	match cast_state:
		CastState.TURNING:
			_process_turning()
		
		CastState.CAST_POINT:
			# Check for interruptions (movement cancels cast point)
			if _should_interrupt_channel():  # Reuse same checks
				cancel_cast()
				return
			
			cast_point_timer -= delta
			
			# Update casting bar
			if casting_bar:
				casting_bar.update_timer(cast_point_timer)
			
			if cast_point_timer <= 0:
				_finish_cast_point()
		
		CastState.CHANNELING:
			# Check for interruptions
			if _should_interrupt_channel():
				cancel_cast()
				return
			
			channel_timer -= delta
			channel_elapsed += delta
			
			# Update casting bar
			if casting_bar:
				casting_bar.update_timer(channel_timer)
			
			if ability:
				ability.on_channel_tick.emit(caster, channel_elapsed, current_level)
			
			if channel_timer <= 0:
				_finish_channel()

# ------------------------------------------------------------------------------
# Public API - Casting
# ------------------------------------------------------------------------------
func cast(target_pos: Vector3) -> bool:
	"""Start casting the ability at target position"""
	if not can_cast():
		return false
	
	if not ability:
		return false
	
	# Emit cast begin event
	ability.on_cast_begin.emit(caster, target_pos, current_level)
	
	# Check Turn Rate Requirement
	if ability.requires_turn and caster.has_method("get_movement"):
		var move = caster.get_movement()
		if move:
			# Start turning phase
			cast_state = CastState.TURNING
			pending_target = target_pos
			move.look_at_point(target_pos)
			return true
	
	# No turn required, proceed to cast point
	_start_cast_point(target_pos)
	return true

func cancel_cast():
	"""Cancel the current cast"""
	if cast_state == CastState.CAST_POINT:
		# Cancelled during windup - no mana spent, no cooldown
		cast_state = CastState.IDLE
		pending_target = Vector3.ZERO
		_hide_casting_bar()
		print("⭕ Cast point cancelled")
		
	elif cast_state == CastState.CHANNELING:
		# Interrupted during channel
		if ability:
			ability.on_channel_interrupted.emit(caster, current_level)
		_complete_cast()
		print("❌ Channel interrupted")

# ------------------------------------------------------------------------------
# State Transitions
# ------------------------------------------------------------------------------
func _process_turning():
	"""Check if facing target and transition to cast point"""
	if not caster:
		return
	
	var caster_forward = -caster.global_transform.basis.z
	var dir_to_target = (pending_target - caster.global_position).normalized()
	dir_to_target.y = 0
	
	var alignment = caster_forward.dot(dir_to_target)
	
	# Threshold: 0.98 is roughly 11 degrees
	if alignment > 0.98:
		# Facing complete!
		cast_state = CastState.IDLE
		if caster.has_method("get_movement"):
			var move = caster.get_movement()
			if move and move.has_method("stop_looking"):
				move.stop_looking()
		
		_start_cast_point(pending_target)

func _start_cast_point(target_pos: Vector3):
	"""Begin cast point windup"""
	pending_target = target_pos
	
	if not ability:
		return
	
	cast_point_timer = ability.cast_point
	
	if cast_point_timer <= 0:
		# Instant cast (no windup)
		_finish_cast_point()
	else:
		cast_state = CastState.CAST_POINT
		_show_casting_bar(ability.ability_name, cast_point_timer, false)

func _finish_cast_point():
	"""Cast point finished, execute ability effect"""
	if not ability or not caster:
		return
	
	# Spend mana
	if caster.has_method("get_stats"):
		var stats = caster.get_stats()
		if stats and not stats.spend_mana(ability.mana_cost):
			_complete_cast()
			return
	
	# EMIT THE MAIN EVENT - Ability scripts handle actual effect
	ability.on_cast_point_finish.emit(caster, pending_target, current_level)
	ability_used.emit(ability.ability_name)
	
	# Check if channeling is required
	if ability.channel_duration > 0:
		_start_channel()
	else:
		_complete_cast()

func _start_channel():
	"""Begin channeling phase"""
	if not ability:
		return
	
	cast_state = CastState.CHANNELING
	channel_timer = ability.channel_duration
	channel_elapsed = 0.0
	
	# Show channeling bar
	_show_casting_bar(ability.ability_name, channel_timer, true)
	
	# Lock unit in place
	if caster.has_method("get_movement"):
		var move = caster.get_movement()
		if move and move.has_method("stop_movement"):
			move.stop_movement()

func _finish_channel():
	"""Channel completed successfully"""
	if ability:
		ability.on_channel_finish.emit(caster, current_level)
	_complete_cast()

func _complete_cast():
	"""Finish entire cast sequence and start cooldown"""
	cast_state = CastState.IDLE
	pending_target = Vector3.ZERO
	cast_point_timer = 0.0
	channel_timer = 0.0
	channel_elapsed = 0.0
	
	# Hide casting bar
	_hide_casting_bar()
	
	# Start cooldown
	if ability:
		current_cooldown = ability.cooldown
		cooldown_changed.emit(current_cooldown, ability.cooldown)

# ------------------------------------------------------------------------------
# Public API - Queries
# ------------------------------------------------------------------------------
func can_cast() -> bool:
	if not ability:
		return false
	
	if current_cooldown > 0.0:
		return false
	
	if cast_state != CastState.IDLE:
		return false
	
	return ability.can_cast(caster, current_level)

func is_ready() -> bool:
	return current_cooldown <= 0.0 and cast_state == CastState.IDLE

func is_casting() -> bool:
	return cast_state != CastState.IDLE

func level_up():
	if ability and current_level < ability.max_level:
		current_level += 1
		level_changed.emit(current_level)

func get_cooldown_ratio() -> float:
	if ability and ability.cooldown > 0:
		return current_cooldown / ability.cooldown
	return 0.0

# ------------------------------------------------------------------------------
# Casting Bar Management
# ------------------------------------------------------------------------------
func _show_casting_bar(ability_name: String, duration: float, is_channel: bool):
	"""Create and show casting bar"""
	if not casting_bar:
		casting_bar = CASTING_BAR_SCENE.instantiate()
		# Add to HUD layer (assumes canvas layer exists)
		var canvas = get_tree().root.get_node_or_null("World/CanvasLayer")
		if canvas:
			canvas.add_child(casting_bar)
		else:
			# Fallback: add to root
			get_tree().root.add_child(casting_bar)
	
	if is_channel:
		casting_bar.show_channel(ability_name, duration)
	else:
		casting_bar.show_cast_point(ability_name, duration)

func _hide_casting_bar():
	"""Hide and clean up casting bar"""
	if casting_bar:
		casting_bar.hide_cast()

# ------------------------------------------------------------------------------
# Channel Interruption Detection
# ------------------------------------------------------------------------------
func _should_interrupt_channel() -> bool:
	"""Check if channel should be interrupted"""
	if not ability or not caster:
		return false
	
	# 1. Check movement (CRITICAL - always interrupts unless explicitly allowed)
	if not ability.can_move_while_channeling:
		if caster.has_method("get_velocity") or "velocity" in caster:
			var vel = caster.velocity if "velocity" in caster else caster.get_velocity()
			if vel.length() > 0.1:  # Moving
				print("⚠️ Channel interrupted: Movement detected")
				return true
	
	# 2. Check if unit is attacking (always interrupts)
	if caster.has_method("get_combat"):
		var combat = caster.get_combat()
		if combat and "windup_timer" in combat and combat.windup_timer > 0:
			print("⚠️ Channel interrupted: Attack started")
			return true
	
	# 3. Check CC/Stun status (always interrupts)
	if caster.has_method("is_stunned") and caster.is_stunned():
		print("⚠️ Channel interrupted: Stunned")
		return true
	
	# Future: Check death, silence, etc.
	
	return false
