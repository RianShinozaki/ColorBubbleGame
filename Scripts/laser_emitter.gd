@tool
class_name LaserEmitter

extends Hazard 

@onready var shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var area_2D: Area2D = $Hitbox as Area2D
@onready var ray: RayCast2D = $RayCast2D as RayCast2D
@onready var light: Sprite2D = $Light as Sprite2D
@export var enabled: bool = true
@export var rgb_color: Color=Color(1, 0, 0, 1)
@export var activation_interval: float
@export_range(1, 10000, 1) var distance: int
@export_range(1, 10000, 1) var width: int
var rect: RectangleShape2D = RectangleShape2D.new()
var activation_time: float = 0
@export_tool_button("Update Attributes") var update_attributes_action = update_attributes
@export_tool_button("Disable") var disable_action = disable
@export_tool_button("Enable") var enable_action = enable

func _ready() -> void:
	update_attributes()
	if !enabled:
		disable()
	
func _draw() -> void:
	var _direction: Vector2 = Vector2.from_angle(global_rotation)
	if Engine.is_editor_hint():
		draw_set_transform_matrix(global_transform.affine_inverse())
		draw_line(global_position, global_position + _direction * distance, modulate, 4)

func _process(_delta: float):
	queue_redraw()
	if not Engine.is_editor_hint():
		if activation_interval != 0:
			activation_time += _delta
			if activation_time >= activation_interval:
				activation_time = 0
				if enabled: disable()
				else: enable()
				
		if enabled:
			var _ray_dist = distance
			if ray.is_colliding():
				_ray_dist = (ray.get_collision_point() - global_position).length()
			
			rect.size = Vector2(_ray_dist, width)
			shape.shape = rect
			@warning_ignore("integer_division")
			shape.position = Vector2(_ray_dist/2, 0)

			light.scale = Vector2(randf_range(0.4, 1.5), _ray_dist)
			@warning_ignore("integer_division")
			light.position = Vector2(_ray_dist/2, 0)
		
func update_attributes():
	modulate = rgb_color
	var _red_bit: int = floori(rgb_color.r)
	var _green_bit: int = floori(rgb_color.g)
	var _blue_bit: int = floori(rgb_color.b)
	var _color_mask: int = _red_bit + (_green_bit<<1) + (_blue_bit<<2)
	area_2D.collision_layer = (_color_mask << 8)
		
	ray.collision_mask |= 0b111 << 8
	ray.collision_mask &= ~(_color_mask << 8)
	ray.target_position = Vector2(distance, 0)
	light.scale = Vector2(1, distance)
	@warning_ignore("integer_division")
	light.position = Vector2(distance/2, 0)

func enable():
	enabled = true
	light.visible = true
	shape.set_deferred("disabled", false)
	
func disable():
	enabled = false
	light.visible = false
	shape.set_deferred("disabled", true)
