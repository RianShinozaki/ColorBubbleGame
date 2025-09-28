extends Node2D

@export var spin_speed: float

func _process(delta: float) -> void:
	rotate(spin_speed * delta)
