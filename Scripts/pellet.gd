extends Area2D

@export var radius: float = 0.3

func disable():
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func reset():
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
