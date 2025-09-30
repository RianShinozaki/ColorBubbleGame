extends Area2D
class_name Checkpoint

@onready var star_sprite: Sprite2D = $StarSprite


@export var inactive_texture: Texture2D
@export var active_texture: Texture2D
@export var make_unique := true      # only one active at a time
@export var inactive_color: Color = Color(1.0, 0.9, 0.3)     # Golden yellow for inactive
@export var active_color: Color = Color(0.0, 0.0, 0.0)       # Green for active

const null_color: Color = Color(0.4, 0.4, 0.4, 1)

var activated := false
@export var saved_scale: float = 0.8

func _ready() -> void:
	# show correct initial texture
	star_sprite.scale = Vector2(0.5, 0.5)  # Makes it 50% size

	_apply_texture()
	


	# connect signal if not connected in the editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	if not is_in_group("checkpoint"):
		add_to_group("checkpoint")

func _apply_texture() -> void:
	# Apply the appropriate color based on activation state
	if activated:
		star_sprite.modulate = active_color
	else:
		star_sprite.modulate = inactive_color
		
	
	# Different rotation speeds for active/inactive
	var rotation_duration = 6.0 if not activated else 3.0  # Faster when active
	
	# Create the rotation animation
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(star_sprite, "rotation", TAU, rotation_duration).from(0)
	
	# Different scale ranges for active/inactive
	var scale_max = Vector2(0.5, 0.5) if not activated else Vector2(0.55, 0.55)
	var scale_min = Vector2(0.45, 0.45) if not activated else Vector2(0.48, 0.48)
	var scale_duration = 2.0 if not activated else 1.2  # Faster pulse when active
	
	# Pulsing scale animation
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.set_trans(Tween.TRANS_SINE)
	scale_tween.set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(star_sprite, "scale", scale_max, scale_duration)
	scale_tween.tween_property(star_sprite, "scale", scale_min, scale_duration)
	
	# Pulsing modulate for glow effect (only animate alpha to preserve color)
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.set_trans(Tween.TRANS_SINE)
	glow_tween.set_ease(Tween.EASE_IN_OUT)
	var current_color = active_color if activated else inactive_color
	var alpha_min = 0.7 if not activated else 0.85  # More visible when active
	var glow_duration = 2.0 if not activated else 1.2  # Faster glow when active
	glow_tween.tween_property(star_sprite, "modulate", Color(current_color.r, current_color.g, current_color.b, alpha_min), glow_duration)
	glow_tween.tween_property(star_sprite, "modulate", Color(current_color.r, current_color.g, current_color.b, 1.0), glow_duration)


func _on_body_entered(body: Node) -> void:
	if not activated:
		if body.rgb_color == Color.BLACK:
			active_color = null_color
		else:
			active_color = body.rgb_color

		# If already active, still set the player's spawn
	if body and body.has_method("set_checkpoint"):
		if active_color == null_color:
			body.set_checkpoint(global_position, Color.BLACK, body.to_scale)
		else:
			body.set_checkpoint(global_position, active_color, body.to_scale)
			# Don't play the collected animation as it causes the checkpoint to disappear

	# Swap texture if this is the first time
	if not activated:
		_activate()

func _activate() -> void:
	activated = true
	
	# Play activation effects
	_play_activation_effect()
	
	_apply_texture()

	if make_unique:
		# Deactivate all other checkpoints in the scene
		for cp in get_tree().get_nodes_in_group("checkpoint"):
			if cp == self:
				continue
			if cp is Checkpoint:
				cp.deactivate()

func _play_activation_effect() -> void:
	# Size pop animation - grow then shrink back
	var pop_tween = create_tween()
	pop_tween.set_trans(Tween.TRANS_BACK)
	pop_tween.set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(star_sprite, "scale", Vector2(0.8, 0.8), 0.15)
	pop_tween.set_trans(Tween.TRANS_BOUNCE)
	pop_tween.set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(star_sprite, "scale", Vector2(0.55, 0.55), 0.3)
	
	# Create a pulse effect by temporarily brightening the star
	var pulse_tween = create_tween()
	pulse_tween.set_trans(Tween.TRANS_EXPO)
	pulse_tween.set_ease(Tween.EASE_OUT)
	# Make it bright white briefly
	pulse_tween.tween_property(star_sprite, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
	# Then fade to the active color
	pulse_tween.tween_property(star_sprite, "modulate", active_color, 0.4)
	
	# Optional: Create an expanding ring effect (would need additional node)
	# This is a visual indicator that spreads outward
	_create_expanding_ring()

func _create_expanding_ring() -> void:
	# Create a temporary sprite for the ring effect
	var ring = Sprite2D.new()
	ring.texture = star_sprite.texture  # Use same texture
	ring.modulate = active_color
	ring.modulate.a = 0.8
	ring.scale = Vector2(0.1, 0.1)
	add_child(ring)
	
	# Animate the ring expanding and fading
	var ring_tween = create_tween()
	ring_tween.set_parallel(true)
	ring_tween.set_trans(Tween.TRANS_EXPO)
	ring_tween.set_ease(Tween.EASE_OUT)
	ring_tween.tween_property(ring, "scale", Vector2(2.0, 2.0), 0.6)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.6)
	ring_tween.chain().tween_callback(ring.queue_free)

func deactivate() -> void:
	if activated:
		activated = false
		_apply_texture()

func play_collected_animation():
	# Quick flash when collected
	var collect_tween = create_tween()
	collect_tween.tween_property(star_sprite, "scale", Vector2(1.5, 1.5), 0.2)
	collect_tween.tween_property(star_sprite, "modulate:a", 0.0, 0.3)
	collect_tween.tween_callback(queue_free)
