extends Node3D
class_name GridRegion

# --------------------------------------------------------------------
# GRID REGION
# Defines the area that the GridManager should scan for pathfinding.
# Place this in your scene and resize the gizmo/values.
# --------------------------------------------------------------------

@export var map_size: Vector3 = Vector3(100, 10, 100)
@export var cell_size: float = 1.0
@export var scan_on_ready: bool = true

func _ready():
	# Register this region as the active map for the GridManager
	if GridManager:
		GridManager.register_region(self)
	else:
		push_error("GridManager not found (Autoload missing?)")

func _draw():
	# Debug visualization (Only visible in Editor if tool, or use DebugDraw3D)
	pass
