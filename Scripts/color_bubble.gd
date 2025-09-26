@tool

class_name ColorBubble

extends Area2D

@export var rgb_color: Color=Color(1, 0, 0, 1)

func _process(_delta: float) -> void:
	modulate = rgb_color
