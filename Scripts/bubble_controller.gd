extends RigidBody2D

@export var maximum_speed: float
@export var acceleration: float
@export var stretch_scale_factor: float
@export var sprite: Sprite2D
@export var shape: CollisionShape2D
@export var sprite_parent: Node2D
@export var rgb_color: Color = Color.WHITE

var this_scale: float = 1
var to_scale: float = 1
var grow_speed: float = 0.2
var no_color: bool = true
var color_shift_multiple: float = 1.0 #this gives us the option to adjust the intensity of the color shift for boards with more collisions
#to do: change color_shift_multiple to be proportionate to bubble size if we do dif. bubble sizes
@export var color_animation_gradient: Gradient
@export var color_animation_gradient_position: float = 1
const null_color: Color = Color(0.4, 0.4, 0.4, 1)

func _ready() -> void:
	#Connects a signal, basically means when PelletGrabber signals "area_entered", we run this "on_pellet_pickedup" function
	get_node("ItemCollision").area_entered.connect(on_item_pickup)
	modulate = null_color
	set_color(Color(0, 0, 0, 1))
	
func _physics_process(_delta: float) -> void:
	#Get movement input vector from API Call
	var _input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if _input.length() > 0: #Check if there is any input
		if linear_velocity.length() < maximum_speed: #Check if we're below maximum speed
			linear_velocity += _input * acceleration * _delta
	#This is some silly stuff to make the bubble stretchy and squishy
	#The squishing and rotation only happens to the sprite so it doesn't affect collision
	sprite.rotation = atan2(linear_velocity.y, linear_velocity.x)
	sprite.scale = Vector2(1+linear_velocity.length()/stretch_scale_factor, 1-(linear_velocity.length()/stretch_scale_factor))
	#We can't change the scale of this root node bc you can't scale a rigidbody
	this_scale = lerp(this_scale, to_scale, grow_speed)
	#I put a layer between the sprite and this root node to make life easier
	sprite_parent.scale = Vector2(this_scale, this_scale)
	#Just change the scale of the shape directly
	shape.scale = Vector2(this_scale, this_scale)
	
	#Slowly shift the color to the desired one
	color_animation_gradient_position = move_toward(color_animation_gradient_position, 1, _delta*5)
	modulate = color_animation_gradient.sample(color_animation_gradient_position)

#I use the same script for colored bubbles and growth pellets lol
func on_item_pickup(area: Area2D):
	#Check if it's a colored bubble and use add color script
	if area is ColorBubble:
		var _cb: ColorBubble = area as ColorBubble
		if no_color:
			rgb_color = Color.BLACK
			no_color = false
		add_color(_cb.rgb_color)
	elif area is SpikyEnemyBubble:
		var _eb: SpikyEnemyBubble = area as SpikyEnemyBubble
		if !no_color:
			subtract_color(_eb.rgb_color)
	else:
		to_scale += 0.1
	#Destroy whatever item we got
	area.queue_free()

#continuous colors instead of bitmask
func add_color(rgb_add: Color):
	
	var _red: float = clamp(rgb_color.r + rgb_add.r*color_shift_multiple, 0.0, 1.0)
	var _green: float = clamp(rgb_color.g + rgb_add.g*color_shift_multiple, 0.0, 1.0)
	var _blue: float = clamp(rgb_color.b + rgb_add.b*color_shift_multiple, 0.0, 1.0)
	set_color(Color(_red, _green, _blue, 1))
	
func subtract_color(rgb_subtract: Color):
	
	var _red: float = clamp(rgb_color.r - rgb_subtract.r*color_shift_multiple, 0.0, 1.0)
	var _green: float = clamp(rgb_color.g - rgb_subtract.g*color_shift_multiple, 0.0, 1.0)
	var _blue: float = clamp(rgb_color.b - rgb_subtract.b*color_shift_multiple, 0.0, 1.0)
	set_color(Color(_red, _green, _blue, 1))
		
func set_color(_rgb_color: Color):
	rgb_color = _rgb_color
	
	var _red_bit: int = floori(rgb_color.r)
	var _green_bit: int = floori(rgb_color.g)
	var _blue_bit: int = floori(rgb_color.b)
	var _color_mask: int = _red_bit + (_green_bit<<1) + (_blue_bit<<2)
	
	var _to_color: Color = rgb_color
	if rgb_color == Color.BLACK:
		no_color = true
		_to_color = null_color
	collision_mask |= 0b111 << 8
	collision_mask &= ~(_color_mask << 8)
	color_animation_gradient = Gradient.new()
	color_animation_gradient.add_point(0, modulate)
	color_animation_gradient.add_point(1, _to_color)
	color_animation_gradient.remove_point(0)
	color_animation_gradient.remove_point(0)
	color_animation_gradient_position = 0
	#We don't want the color to be totally black
	
	
