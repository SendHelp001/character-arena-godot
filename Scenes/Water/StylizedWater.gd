@tool
extends MeshInstance3D

@export_group("Colors")
@export var water_color := Color("0077bd") :
	set(value):
		water_color = value
		_update_shader("albedo", value)

@export var deep_water_color := Color("00296e") :
	set(value):
		deep_water_color = value
		_update_shader("albedo_deep", value)

@export var foam_color := Color.WHITE :
	set(value):
		foam_color = value
		_update_shader("foam_color", value)

@export_group("Properties")
@export_range(0.0, 1.0) var transparency := 0.2 :
	set(value):
		transparency = value
		_update_shader("beer_factor", value * 2.0) # Map to beer factor

@export_range(0.0, 1.0) var foam_amount := 0.5 :
	set(value):
		foam_amount = value
		_update_shader("foam_amount", value)

@export_range(0.0, 1.0) var wave_height := 0.2 :
	set(value):
		wave_height = value
		_update_shader("wave_height", value)

func _ready():
	# Initialize from shader defaults if needed
	if material_override and material_override is ShaderMaterial:
		var mat = material_override as ShaderMaterial
		# Apply current exports to shader to ensure match
		mat.set_shader_parameter("albedo", water_color)
		mat.set_shader_parameter("albedo_deep", deep_water_color)
		mat.set_shader_parameter("foam_color", foam_color)
		mat.set_shader_parameter("foam_amount", foam_amount)
		mat.set_shader_parameter("wave_height", wave_height)

func _update_shader(param: String, value):
	if material_override and material_override is ShaderMaterial:
		(material_override as ShaderMaterial).set_shader_parameter(param, value)
