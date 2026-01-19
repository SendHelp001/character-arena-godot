extends Node

# Path to the original scene
const DEMO_SCENE_PATH = "res://Scenes/demo_scene.tscn"

func _ready():
	# 1. Load Original Scene
	var demo_packed = load(DEMO_SCENE_PATH)
	if not demo_packed:
		push_error("MainSetup: Could not load demo_scene.tscn!")
		return

	# 2. Create Pixelation Structure
	# Structure:
	# Main (Self)
	#   -> SubViewportContainer (Full Screen, Stretch, Nearest Filter)
	#      -> SubViewport (Resolution 640x360)
	#         -> World (Demo Scene Instance)
	#   -> UI (Extracted from Demo Scene)

	var container = SubViewportContainer.new()
	container.name = "PixelContainer"
	container.anchors_preset = Control.PRESET_FULL_RECT
	container.set_anchors_preset(Control.PRESET_FULL_RECT) # Ensure it covers screen
	container.stretch = true
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # Key for pixel look!
	add_child(container)

	var viewport = SubViewport.new()
	viewport.name = "PixelViewport"
	# Target resolution (e.g., 640x360 for roughly 3x scale on 1080p)
	viewport.size = Vector2(640, 360)
	viewport.size_2d_override = Vector2i(640, 360)
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# For 3D Pixel Art, we usually want the 3D viewport to be low res
	container.add_child(viewport)

	# 3. Instantiate World into Viewport
	var world = demo_packed.instantiate()
	viewport.add_child(world)

	# 4. Extract UI (CanvasLayer) to High Res Root
	# We look for "CanvasLayer" inside the instantiated world
	var canvas_layer = world.find_child("CanvasLayer", false, false) # Non-recursive first
	
	if canvas_layer:
		# Reparent to Self (Root) to keep it high-res
		print("MainSetup: Extracting UI to High Res layer")
		canvas_layer.get_parent().remove_child(canvas_layer)
		add_child(canvas_layer)
	else:
		push_warning("MainSetup: Custom UI 'CanvasLayer' not found in demo_scene.")

	print("MainSetup: Pixelation hierarchy established.")
