@tool

class_name EnemyBubble

extends RigidBody2D

enum behavior_mode {IDLE, ATTACK}
@export var maximum_speed: float
@export var acceleration: float
@export var stretch_scale_factor: float
@onready var sprite: Sprite2D = $SpriteParent/Sprite2D as Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D
@onready var sprite_parent: Node2D = $SpriteParent as Node2D
@export var rgb_color: Color = Color.WHITE
@export var radius: float = 0.8
@export var add_color: bool = true
@export var behavior: behavior_mode = behavior_mode.IDLE
@export var detect_range: float
@export_tool_button("Update Attributes") var update_attributes_action = update_attributes

signal was_disabled
signal was_reset

var disable_position: Vector2 = Vector2(416, 0)
var disabled: bool
var spawn_position: Vector2
func _ready() -> void:
	update_attributes()
	spawn_position = global_position
	
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() && not disabled:
		var _input: Vector2 = Vector2.ZERO
		
		if behavior == behavior_mode.ATTACK:
			var _diff: Vector2 = BubbleController.instance.global_position - global_position
			if _diff.length() < detect_range:
				_input = _diff.normalized()
				if add_color and BubbleController.instance.to_scale >= radius:
					_input = -_input

		sprite_parent.scale = Vector2(radius, radius)
		shape.scale = Vector2(radius, radius)
		if _input.length() > 0: 
			if linear_velocity.length() < maximum_speed: 
				linear_velocity += _input * acceleration * _delta
		sprite.rotation = atan2(linear_velocity.y, linear_velocity.x)
		sprite.scale = Vector2(1+linear_velocity.length()/stretch_scale_factor, 1-(linear_velocity.length()/stretch_scale_factor))

func update_attributes():
	modulate = rgb_color
	var _red_bit: int = floori(rgb_color.r)
	var _green_bit: int = floori(rgb_color.g)
	var _blue_bit: int = floori(rgb_color.b)
	var _color_mask: int = _red_bit + (_green_bit<<1) + (_blue_bit<<2)
	collision_mask |= 0b111 << 8
	collision_mask &= ~(_color_mask << 8)
	
	# Always keep the RigidBody2D at scale 1 to avoid physics engine warnings
	scale = Vector2.ONE
	
	# Scale child nodes instead when in editor
	if Engine.is_editor_hint():
		if has_node("SpriteParent"):
			var _sprite_parent = get_node("SpriteParent")
			_sprite_parent.scale = Vector2(radius, radius)
		if has_node("CollisionShape2D"):
			var _shape = get_node("CollisionShape2D")
			_shape.scale = Vector2(radius, radius)

func disable():
	disabled = true
	shape.set_deferred("disabled", true)
	visible = false
	set_deferred("freeze", true)
	emit_signal("was_disabled")
	
func reset():
	disabled = false
	shape.set_deferred("disabled", false)
	visible = true
	set_deferred("freeze", false)
	PhysicsServer2D.body_set_state(
		get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		Transform2D.IDENTITY.translated(spawn_position)
	)
	linear_velocity = Vector2.ZERO
	emit_signal("was_reset")
	
