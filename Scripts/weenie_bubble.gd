extends RigidBody2D

@export var to_scene: String

var activated := false

func end_level(_body: Node):
	if not activated:
		activated = true
		get_tree().call_deferred("change_scene_to_file", to_scene)
