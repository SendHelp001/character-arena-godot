extends Area3D
class_name ArtifactPickup

@export var artifact: Artifact
@onready var mesh = $MeshInstance3D

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Rotate for visual effect
	var tween = create_tween().set_loops()
	tween.tween_property(self, "rotation:y", deg_to_rad(360), 2.0).as_relative()

func setup(p_artifact: Artifact):
	artifact = p_artifact

func _on_body_entered(body: Node3D):
	if not artifact:
		return
		
	if body.has_method("get_team_id") and body.get_team_id() == 0: # Only player
		# Try to find inventory
		var inventory = body.get_node_or_null("UnitInventory")
		if inventory:
			# Find first empty slot or equip in slot 0/1 based on artifact type?
			# For testing: Auto-equip in first available slot
			for i in range(inventory.MAX_SLOTS):
				if inventory.get_artifact(i) == null:
					if inventory.equip_artifact(artifact, i):
						print("Picked up ", artifact.name)
						queue_free()
						return
			
			# If full, swap slot 0 (Testing logic)
			inventory.equip_artifact(artifact, 0)
			queue_free()
