class_name SpikyEnemyBubble

extends Area2D

@export var rgb_color: Color=Color(1, 0, 0, 1)

func _process(_delta: float) -> void:
	modulate = rgb_color
	#do we need this if they don't change coo
