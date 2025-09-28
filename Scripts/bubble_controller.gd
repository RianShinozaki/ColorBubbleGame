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
var is_dead: bool = false
var this_scale: float = 1
var to_scale: float = 1
var grow_speed: float = 0.2
var no_color: bool = true
var color_shift_multiple: float = 1.0 #this gives us the option to adjust the intensity of the color shift for boards with more collisions
#to do: change color_shift_multiple to be proportionate to bubble size if we do dif. bubble sizes
@export var color_animation_gradient: Gradient #Used to make the color switch smoother
@export var color_animation_gradient_position: float = 1
#The color to use instead of pure black
const null_color: Color = Color(0.4, 0.4, 0.4, 1)

func _ready() -> void:
	#Connects a signal, basically means when PelletGrabber signals "area_entered", we run this "on_pellet_pickedup" function
	get_node("Area2Ds/ItemCollision").area_entered.connect(on_item_pickup)
	get_node("Area2Ds/Hurtbox").area_entered.connect(on_hurtbox_entered)
	modulate = null_color
	set_color(Color(0, 0, 0, 1))
	start_position = global_position
	if death_label: death_label.set_anchors_preset(Control.PRESET_CENTER)
	if restart_label: restart_label.set_anchors_preset(Control.PRESET_CENTER)
	
	
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
	sprite.scale = Vector2(1+linear_velocity.length()/stretch_scale_factor, 1-(linear_velocity.length()/stretch_scale_factor))
	#We can't change the scale of this root node bc you can't scale a rigidbody
	this_scale = lerp(this_scale, to_scale, grow_speed)
	#I put a layer between the sprite and this root node to make life easier
	sprite_parent.scale = Vector2(this_scale, this_scale)
	#Just change the scale of the shape directly
	shape.scale = Vector2(this_scale, this_scale)
	get_node("Area2Ds").scale = Vector2(this_scale, this_scale)
	
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
	# area.queue_free()
	_soft_disable_item(area)
	
	
func _soft_disable_item(a: Area2D) -> void:
	#Hide visuals (Area2D is a CanvasItem, so it has `visible`)
	a.visible = false
	#If the sprite/mesh is on the parent or a sibling, also hide the parent if it's a CanvasItem
	var p := a.get_parent()
	if p and p is CanvasItem:
		(p as CanvasItem).visible = false

	# Stop future overlap callbacks
	a.set_deferred("monitoring",  false)
	a.set_deferred("monitorable", false)

	# Mark it so we can restore later
	if not a.is_in_group("collectible_soft_disabled"):
		a.add_to_group("collectible_soft_disabled")


#For things that really hurt the bubble (lasers, screws)
func on_hurtbox_entered(_area: Area2D):
	if _area.get_parent() is Hazard:
		if rgb_color == Color.BLACK:
			bubble_die()
		else:
			set_color(Color.BLACK)
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
	for a in get_tree().get_nodes_in_group("collectible_soft_disabled"):
		if not is_instance_valid(a):
			continue
		# show again
		a.visible = true
		var p := a.get_parent()
		if p and p is CanvasItem:
			(p as CanvasItem).visible = true
		# re-enable overlaps
		a.set_deferred("monitoring",  true)
		a.set_deferred("monitorable", true)
		# let item reset any internal state if it has such a method
		if a.has_method("reset"):
			a.reset()

		a.remove_from_group("collectible_soft_disabled")

func _do_respawn() -> void:
	state = State.ALIVE
	input_enabled = true
	modulate = Color(1, 1, 1, 1)
	
	global_position = start_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
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

func set_checkpoint(pos: Vector2) -> void:
	start_position = pos
