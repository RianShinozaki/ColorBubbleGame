class_name ColorBubble

extends Area2D

@export_flags("Red", "Green", "Blue") var color_mask: int

func _process(_delta: float) -> void:
	var _red: int = color_mask & 0b1
	var _green: int = (color_mask & 0b10) >> 1
	var _blue: int = (color_mask & 0b100) >> 2
	
	modulate = Color(_red, _green, _blue, 1)
