extends Label3D
class_name DamageNumber

const FLOAT_DURATION = 1.5
const FLOAT_DISTANCE = 2.0

func _ready():
	# Animate floating up and fading out
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Float up
	tween.tween_property(self, "position", position + Vector3(0, FLOAT_DISTANCE, 0), FLOAT_DURATION)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, FLOAT_DURATION)
	
	# Delete after animation
	tween.tween_callback(queue_free).set_delay(FLOAT_DURATION)

func setup(damage_amount: float, damage_type: String):
	"""Configure damage number appearance"""
	text = str(int(damage_amount))
	
	# Color based on damage type
	match damage_type:
		"PHYSICAL":
			modulate = Color(1, 0.3, 0.3)  # Red
		"MAGICAL":
			modulate = Color(0.7, 0.3, 1)  # Purple
		"TRUE":
			modulate = Color(1, 1, 1)      # White
		_:
			modulate = Color(1, 0.5, 0)    # Orange default
