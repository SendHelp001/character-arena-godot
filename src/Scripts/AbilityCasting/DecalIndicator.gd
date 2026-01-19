extends Node3D

@onready var decal = $Decal

func set_texture(texture: Texture2D):
	if decal:
		decal.texture_albedo = texture

func set_size(size: Vector3):
	if decal:
		decal.size = size

func set_color(color: Color):
	if decal:
		decal.modulate = color
