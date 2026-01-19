@tool
extends Node3D

@export var texture: Texture2D = null:
	set(value):
		texture = value
		if decal: decal.texture_albedo = value

@onready var decal = $Decal

func _ready():
	if not decal:
		decal = Decal.new()
		add_child(decal)
		decal.cull_mask = 1 # Ground only usually
		# Rotate decal to project downwards
		decal.rotation_degrees.x = -90 

	if texture:
		decal.texture_albedo = texture

func update_visuals(mode: int, range_val: float, radius_val: float):
	if not decal: return
	
	# Ensure texture is set (if not set in inspector, use default)
	if not decal.texture_albedo and texture:
		decal.texture_albedo = texture
	
	if mode == 1: # DIRECTIONAL
		# Arrow/Line
		# Z is length, X is width
		decal.size = Vector3(radius_val * 2, 10.0, range_val)
		
		# Position: Starts at 0, extends forward -Z
		# Decal center is at (0,0,0) locally.
		# We want the "start" of the decal to be at (0,0,0).
		# So we move the decal center forward by half length.
		decal.position = Vector3(0, 0, -range_val / 2.0)
		
	elif mode == 2: # CIRCULAR
		# Circle
		var diameter = radius_val * 2
		decal.size = Vector3(diameter, 10.0, diameter)
		decal.position = Vector3.ZERO
		
	elif mode == 3: # POINT
		# Small circle
		decal.size = Vector3(2.0, 10.0, 2.0)
		decal.position = Vector3.ZERO
