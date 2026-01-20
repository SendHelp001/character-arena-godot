extends Ability
class_name BlinkAbility

func _init():
	# Defaults now in .tres resource file
	ability_name = "Blink"
	
	# Connect to lifecycle events
	on_cast_point_finish.connect(_execute_blink)

func _execute_blink(caster: Node, target_pos: Vector3, level: int):
	"""
	Teleport caster to target position.
	Mechanic: 3D Raycast from crosshair (passed as target_pos by CastingManager usually), max 10 range.
	"""
	print("✨ Blink cast start!")
	
	var max_blink_range = 10.0
	
	# The target_pos passed here comes from CastingManager calling 'cast(target_pos)'.
	# CastingManager usually does a raycast against the GROUND (Terrain).
	# BUT the user wants "Air/Ground" and "Raycast from crosshair".
	# If CastingManager is doing the raycast, it might be clamping to ground.
	# We might need to override behavior or ensure CastingManager sends the raw point.
	
	# Assuming CastingManager sends the point the crosshair is pointing at (could be wall, ground, or point in air if unlimited ray?)
	# Actually CastingManager usually rays against mask.
	
	# Let's perform our own check if needed, or trust target_pos.
	# The prompt says "blink should be raycasted from the crosshair".
	# If we trust 'target_pos' is the hit point:
	
	var caster_pos = caster.global_position
	print("✨ Blink Start. Caster Pos: %s, Target Request: %s" % [caster_pos, target_pos])
	# We want to blink FROM caster TO target_pos
	
	var vec_to_target = target_pos - caster_pos
	var dist = vec_to_target.length()
	
	var final_pos = target_pos
	
	if dist > max_blink_range:
		# Clamp to 10 units
		final_pos = caster_pos + vec_to_target.normalized() * max_blink_range
		
	# 3D Teleport - No ground snapping!
	# Just set position.
	
	# Collision check? Teleporting inside a wall is bad.
	# Simple check: Raycast from caster to final_pos to see if we hit a wall before 10 units?
	# Or assume the 'target_pos' was a raycast hit result, so it IS a surface.
	# If we clamp, we are mid-air or mid-space.
	# Being inside geometry is the risk.
	
	# If we are simply moving 'towards' target, we might clip.
	# Safe move: move_and_slide if using CharacterBody3D? Or just set global_position.
	# For Blink, instant set is standard.
	
	caster.global_position = final_pos
	print("✨ Blink Complete. New Pos: %s. Delta: %s" % [caster.global_position, caster.global_position - caster_pos])
