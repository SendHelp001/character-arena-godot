extends Label3D

var velocity: Vector3 = Vector3(0, 2, 0)
var duration: float = 1.0
var timer: float = 0.0

func setup(amount: float, type: String):
	text = str(int(amount))
	
	# Color coding
	match type:
		"PHYSICAL":
			modulate = Color(1, 1, 1) # White
		"MAGIC":
			modulate = Color(0.5, 0.5, 1) # Blueish
		"TRUE":
			modulate = Color(1, 1, 1) # White (maybe distinct later)
		"CRIT":
			modulate = Color(1, 0, 0) # Red
			font_size = 48 # Check if font_size property exists or needs distinct property
			outline_modulate = Color(0, 0, 0)
			
	# Randomize horizontal velocity slightly
	velocity.x = randf_range(-1, 1)
	velocity.z = randf_range(-1, 1)

func _process(delta):
	timer += delta
	if timer >= duration:
		queue_free()
		return
		
	# Move
	position += velocity * delta
	
	# Fade out
	var alpha = 1.0 - (timer / duration)
	modulate.a = alpha
