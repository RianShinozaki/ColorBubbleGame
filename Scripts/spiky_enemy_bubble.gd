@tool

class_name SpikyEnemyBubble

extends Area2D
@export var radius: float = 1
@export var rgb_color: Color=Color(1, 0, 0, 1)

func _process(_delta: float) -> void:
	modulate = rgb_color
	scale = Vector2(radius, radius)

	#do we need this if they don't change coo
