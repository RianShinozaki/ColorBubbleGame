@tool

class_name ColorBubble

extends EnemyBubble


@export var rgb_color: Color=Color(1, 1, 1, 1)

func _process(_delta: float) -> void:
	modulate = rgb_color
