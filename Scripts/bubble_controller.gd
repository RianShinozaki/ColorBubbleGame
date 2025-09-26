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
var first_collision_occurred: bool = false



func _ready() -> void:
	#Connects a signal, basically means when PelletGrabber signals "area_entered", we run this "on_pellet_pickedup" function
	get_node("ItemCollision").area_entered.connect(on_item_pickup)
	#add_color(0)

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

#I use the same script for colored bubbles and growth pellets lol
func on_item_pickup(area: Area2D):
	#Check if it's a colored bubble and use add color script
	if area is ColorBubble:
		var _cb: ColorBubble = area as ColorBubble
		if !first_collision_occurred:
			rgb_color = Color.BLACK
			first_collision_occurred = true
		add_color(_cb.rgb_color)
	else:
		to_scale += 0.1
	#Destroy whatever item we got
	area.queue_free()
		

#continuous colors instead of bitmask
func add_color(rgb_add: Color):
	
	var _red: float = clamp(rgb_color.r + rgb_add.r, 0.0, 1.0)
	var _green: float = clamp(rgb_color.g + rgb_add.g, 0.0, 1.0)
	var _blue: float = clamp(rgb_color.b + rgb_add.b, 0.0, 1.0)
	rgb_color = Color(_red, _green, _blue, 1)
	modulate = rgb_color
	
	#We don't want the color to be totally black
	if modulate == Color.BLACK:
		modulate = Color(0.4, 0.4, 0.4)
