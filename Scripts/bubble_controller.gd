class_name BubbleController

extends RigidBody2D

enum State { ALIVE, STUNNED, DEAD }
var state: State = State.ALIVE
var input_enabled := true

@export var maximum_speed: float
@export var acceleration: float
@export var stretch_scale_factor: float
@export var sprite: Sprite2D
@export var shape: CollisionShape2D
@export var sprite_parent: Node2D
@export var rgb_color: Color = Color.WHITE
@export var knockback_force: float
@onready var hurtbox: Area2D = $Area2Ds/Hurtbox

@onready var death_label: Label = get_tree().get_first_node_in_group("death_label")
@onready var restart_label: Label = get_tree().get_first_node_in_group("restart_label")

var start_position: Vector2
var start_color: Color
var is_dead: bool = false
@export var invincibility_time: float
@export var initial_scale: float = 0.8
@export var max_scale: float = 3.8

@export var color_animation_gradient: Gradient
@export var color_animation_gradient_position: float = 1

@onready var mat: ShaderMaterial = sprite.material as ShaderMaterial


var invincibility_counter: float = 0
var this_scale: float = 1
var to_scale: float = initial_scale
var grow_speed: float = 0.2
var no_color: bool = true
var color_shift_multiple: float = 1.0 #this gives us the option to adjust the intensity of the color shift for boards with more collisions
#to do: change color_shift_multiple to be proportionate to bubble size if we do dif. bubble sizes
#The color to use instead of pure black
var iridesence_speed: float = 0.5

const null_color: Color = Color(0.4, 0.4, 0.4, 1)
static var instance: BubbleController

func _ready() -> void:
	if !(sprite.material is ShaderMaterial):
		var sh: Shader = preload("res://Shaders/player_bubble_shader.gdshader")
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = sh
		mat = sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("base_color", rgb_color)  
		mat.set_shader_parameter("time", 0.0)
	#Connects a signal, basically means when PelletGrabber signals "area_entered", we run this "on_pellet_pickedup" function
	get_node("Area2Ds/ItemCollision").area_entered.connect(on_item_pickup)
	get_node("Area2Ds/ItemCollision").body_entered.connect(on_bubble_collision)
	get_node("Area2Ds/Hurtbox").area_entered.connect(on_hurtbox_entered)
	modulate = null_color
	set_color(Color(0, 0, 0, 1))
	if start_position == Vector2.ZERO: start_position = global_position
	if death_label: death_label.set_anchors_preset(Control.PRESET_CENTER)
	if restart_label: restart_label.set_anchors_preset(Control.PRESET_CENTER)
	instance = self


func _process(delta):
	if mat:
		var current_time = mat.get_shader_parameter("time")
		mat.set_shader_parameter("time", current_time+delta*iridesence_speed)
		
		# Update light position based on screen position
		var viewport_size = get_viewport_rect().size
		var bubble_pos = global_position
		
		
		# Convert to normalized coordinates (0-1)
		var normalized_pos = bubble_pos / viewport_size
		
		mat.set_shader_parameter("bubble_screen_pos", normalized_pos)
	
	
func _physics_process(_delta: float) -> void:
	#For respawn check
	if state == State.DEAD:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		if Input.is_action_just_pressed("respawn") or Input.is_action_just_pressed("ui_accept"):
			_do_respawn()
		return
		
	if not input_enabled:
		return
		
	#Get movement input vector from API Call
	var _input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if _input.length() > 0: #Check if there is any input
		if linear_velocity.length() < maximum_speed: #Check if we're below maximum speed
			linear_velocity += _input * acceleration * _delta
	#This is some silly stuff to make the bubble stretchy and squishy
	#The squishing and rotation only happens to the sprite so it doesn't affect collision
	sprite.rotation = atan2(linear_velocity.y, linear_velocity.x)
	
	#compensate for rotation in shader
	if mat:
		mat.set_shader_parameter("sprite_rotation", sprite.rotation)
	
	sprite.scale = Vector2(1+linear_velocity.length()/stretch_scale_factor, 1-(linear_velocity.length()/stretch_scale_factor))
	#We can't change the scale of this root node bc you can't scale a rigidbody
	to_scale = clamp(to_scale, initial_scale, max_scale)
	this_scale = lerp(this_scale, to_scale, grow_speed)
	#I put a layer between the sprite and this root node to make life easier
	sprite_parent.scale = Vector2(this_scale, this_scale)
	#Just change the scale of the shape directly
	shape.scale = Vector2(this_scale, this_scale)
	get_node("Area2Ds").scale = Vector2(this_scale, this_scale)
	
	#Slowly shift the color to the desired one
	color_animation_gradient_position = move_toward(color_animation_gradient_position, 1, _delta*5)
	modulate = color_animation_gradient.sample(color_animation_gradient_position)
	
	visible = true
	if invincibility_counter > 0:
		invincibility_counter = move_toward(invincibility_counter, 0, _delta)
		if floori(invincibility_counter * 10) % 2 == 0:
			visible = false

func on_bubble_collision(body: Node2D):
	if state == State.DEAD:
		return
		
	if body is EnemyBubble:
		var _cb: EnemyBubble = body as EnemyBubble
		if _cb.radius > to_scale:
			bubble_die()
		else:
			var _new_area = to_scale
			if _cb.add_color:
				add_color(_cb.rgb_color)
				_new_area = get_area(to_scale) + get_area(_cb.radius)
			else:
				subtract_color(_cb.rgb_color)
				_new_area = get_area(to_scale) - get_area(_cb.radius)
			to_scale = get_radius(_new_area)
			_soft_disable_body_generic(_cb)
			
func _soft_disable_body_generic(n: Node) -> void:
	
	# Try to find the Area2D that actually triggers collisions
	n.disable()
	if not n.is_in_group("collectible_soft_disabled"):
		n.add_to_group("collectible_soft_disabled")
		
#I use the same script for colored bubbles and growth pellets lol
func on_item_pickup(area: Area2D):
	if state == State.DEAD:
		return
	#Check if it's a colored bubble and use add color script
	var _new_area = get_area(to_scale) + get_area(area.radius)
	to_scale = get_radius(_new_area)
	#Destroy whatever item we got
	# area.queue_free()
	_soft_disable_generic(area)
	
	
func _soft_disable_generic(a: Area2D) -> void:
	a.disable()

	# Mark it so we can restore later
	if not a.is_in_group("collectible_soft_disabled"):
		a.add_to_group("collectible_soft_disabled")


#For things that really hurt the bubble (lasers, screws)
func on_hurtbox_entered(_area: Area2D):
	if state == State.DEAD:
		return
		
	var is_hazard := _area.is_in_group("Hazard")
	#if _area.get_parent() is Hazard:
	if is_hazard:
		if rgb_color == Color.BLACK and to_scale == initial_scale:
			if invincibility_counter == 0:
				bubble_die()
		else:
			if invincibility_counter == 0:
				set_color(Color.BLACK)
				invincibility_counter = invincibility_time
				to_scale = initial_scale
			var _laser_forward = Vector2.from_angle(_area.global_rotation)
			var _diff: Vector2 = global_position - _area.global_position
			var _angle_to: float = _laser_forward.angle_to(_diff)
			var _knockback_vec = Vector2.from_angle(_area.global_rotation + deg_to_rad(90))
			linear_velocity = knockback_force * _knockback_vec * sign(_angle_to)

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
	
	#We don't want the color to be totally black
	var _to_color: Color = rgb_color
	if rgb_color == Color.BLACK:
		no_color = true
		_to_color = null_color
	else:
		no_color = false
		
	collision_mask |= 0b111 << 8
	collision_mask &= ~(_color_mask << 8)
	get_node("Area2Ds/Hurtbox").collision_mask |= 0b111 << 8
	get_node("Area2Ds/Hurtbox").collision_mask &= ~(_color_mask << 8)
	#Basically we make a gradient object and sample along it to get the color transition
	color_animation_gradient = Gradient.new()
	color_animation_gradient.add_point(0, modulate)
	color_animation_gradient.add_point(1, _to_color)
	color_animation_gradient.remove_point(0)
	color_animation_gradient.remove_point(0)
	color_animation_gradient_position = 0

func bubble_die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	input_enabled = false
	
	# stop motion (RigidBody2D)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	# gray tint to show “dead” state
	modulate = Color(0.6, 0.6, 0.6, 1.0)
	

	# ignore hits while dead
	if is_instance_valid(hurtbox):
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	if death_label:
		death_label.text = "You died!"
		death_label.visible = true
	else:
		print("DeathLabel not found (check group 'death_label').")
	if restart_label:
		restart_label.text = "Press Enter to restart"
		restart_label.visible = true
	else:
		print("RestartLabel not found (check group 'restart_label').")
	
	#_debug_check_labels("after_die")
		
#Is this used?
func hazard_hit(hazard: Node) -> void:
	match state:
		State.ALIVE:
			state = State.STUNNED
			input_enabled = false
			modulate = Color(0.6, 0.6, 0.6, 1.0)

			if has_method("on_hurtbox_entered"):
				on_hurtbox_entered(hazard)

			if is_instance_valid(hurtbox):
				hurtbox.set_deferred("monitoring",  true)
				hurtbox.set_deferred("monitorable", true)
		State.STUNNED:
			bubble_die()
		State.DEAD:
			pass
			
func _reset_collected_items() -> void:
	var to_restore := get_tree().get_nodes_in_group("Game Entity")
	#for a in get_tree().get_nodes_in_group("collectible_soft_disabled"):
	for a in to_restore:
		if not is_instance_valid(a):
			continue
		if a.has_method("reset"):
			a.reset()
		else:
			print(a.name + " is missing a reset function!")

	await get_tree().create_timer(0.05).timeout
	for a in to_restore:
		if is_instance_valid(a):
			a.remove_from_group("collectible_soft_disabled")

func _do_respawn() -> void:
	state = State.ALIVE
	input_enabled = true
	rgb_color = start_color
	to_scale = initial_scale
	
	GameState.respawn_player(self)
	global_position = start_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	is_dead = false
	set_meta("dead", false)
	
	if death_label:
		death_label.visible = false
	if restart_label:
		restart_label.visible = false

	if is_instance_valid(hurtbox):
		hurtbox.set_deferred("monitoring",  true)
		hurtbox.set_deferred("monitorable", true)
		
	_reset_collected_items()

#func _debug_check_labels(prefix: String) -> void:
	#print(prefix, " death_label=", death_label, " vis=", death_label and death_label.visible)
	#print(prefix, " restart_label=", restart_label, " vis=", restart_label and restart_label.visible)

func set_checkpoint(pos: Vector2, col: Color) -> void:
	start_position = pos
	start_color = col

func get_area(_radius: float) -> float:
	return pow(_radius, 2) * PI

func get_radius(_area: float) -> float:
	return sqrt(_area / PI)
