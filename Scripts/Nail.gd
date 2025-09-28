extends Area2D

#func _ready() -> void:
	#body_entered.connect(_on_body_entered)
#
#func _on_body_entered(body: Node) -> void:
	## Works whether or not the bubble is in a "player" group
	#if body.has_method("hazard_hit"):
		#body.hazard_hit(self)
