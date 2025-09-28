@tool
class_name LaserEmitter

extends Hazard 

@export var rgb_color: Color=Color(1, 0, 0, 1)
@export_range(1, 10000, 1) var distance: int
@export_range(1, 10000, 1) var width: int
@onready var shape: Node = $Hitbox/CollisionShape2D
@onready var area_2D: Area2D = $Hitbox as Area2D
@onready var ray: RayCast2D = $RayCast2D as RayCast2D
var rect: RectangleShape2D = RectangleShape2D.new()
	
func _draw() -> void:
	var _direction: Vector2 = Vector2.from_angle(global_rotation)
	if Engine.is_editor_hint():
		draw_set_transform_matrix(global_transform.affine_inverse())
		draw_line(global_position, global_position + _direction * distance, modulate, 4)

func _process(_delta: float):
	queue_redraw()
	modulate = rgb_color
	if not Engine.is_editor_hint():
		
		var _red_bit: int = floori(rgb_color.r)
		var _green_bit: int = floori(rgb_color.g)
		var _blue_bit: int = floori(rgb_color.b)
		var _color_mask: int = _red_bit + (_green_bit<<1) + (_blue_bit<<2)
		area_2D.collision_layer = (_color_mask << 8)
			
		ray.collision_mask |= 0b111 << 8
		ray.collision_mask &= ~(_color_mask << 8)
		ray.target_position = Vector2(distance, 0)
		var _ray_dist = distance
		if ray.is_colliding():
			_ray_dist = (ray.get_collision_point() - global_position).length()
		
		var _col_shape: CollisionShape2D = shape as CollisionShape2D
		rect.size = Vector2(_ray_dist, width)
		_col_shape.shape = rect
		@warning_ignore("integer_division")
		_col_shape.position = Vector2(_ray_dist/2, 0)
		
		var _light: Sprite2D = $Light as Sprite2D
		_light.scale = Vector2(randf_range(0.4, 1.5), _ray_dist)
		@warning_ignore("integer_division")
		_light.position = Vector2(_ray_dist/2, 0)
		
	
