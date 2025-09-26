extends RigidBody2D

@export var maximum_speed: float
@export var acceleration: float
@export var stretch_scale_factor: float
@export var sprite: Sprite2D
@export var shape: CollisionShape2D
@export var sprite_parent: Node2D
var this_scale: float = 1
var to_scale: float = 1
var grow_speed: float = 0.2

func _ready() -> void:
	get_node("PelletGrabber").area_entered.connect(on_pellet_pickedup)

func _physics_process(_delta: float) -> void:
	var _input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if _input.length() > 0:
		if linear_velocity.length() < maximum_speed:
			linear_velocity += _input * acceleration * _delta
	sprite.rotation = atan2(linear_velocity.y, linear_velocity.x)
	sprite.scale = Vector2(1+linear_velocity.length()/stretch_scale_factor, 1-(linear_velocity.length()/stretch_scale_factor))
	this_scale = lerp(this_scale, to_scale, grow_speed)
	sprite_parent.scale = Vector2(this_scale, this_scale)
	shape.scale = Vector2(this_scale, this_scale)

func on_pellet_pickedup(area: Area2D):
	if area is ColorBubble:
		var _cb: ColorBubble = area as ColorBubble
		collision_mask &= ~(_cb.color_mask << 8)
		modulate = area.modulate
	else:
		to_scale += 0.1
	area.queue_free()
		
	
