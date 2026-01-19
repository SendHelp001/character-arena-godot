extends StaticBody3D

@onready var label_3d = $Label3D
var current_hp = 100

func take_damage(amount: int):
	current_hp -= amount
	_spawn_damage_number(amount)
	
	# Flash effect
	var mesh = $MeshInstance3D
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.05)
		tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func _spawn_damage_number(amount: int):
	# Simplified damage number for now
	if label_3d:
		label_3d.text = "-%d" % amount
		label_3d.modulate = Color.RED
		
		await get_tree().create_timer(0.5).timeout
		label_3d.text = "Dummy"
		label_3d.modulate = Color.WHITE
