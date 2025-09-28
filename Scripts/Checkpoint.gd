extends Area2D
class_name Checkpoint

@onready var sprite: Sprite2D = $Sprite2D

@export var inactive_texture: Texture2D
@export var active_texture: Texture2D
@export var make_unique := true      # only one active at a time

var activated := false

func _ready() -> void:
	# show correct initial texture
	_apply_texture()

	# connect signal if not connected in the editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	if not is_in_group("checkpoint"):
		add_to_group("checkpoint")

func _apply_texture() -> void:
	if sprite:
		sprite.texture = active_texture if activated else inactive_texture

func _on_body_entered(body: Node) -> void:
	#if not (body is RigidBody2D):
		#return
	#if not body.has_method("set_checkpoint"):
		#return

	# If already active, still set the player's spawn
	if body and body.has_method("set_checkpoint"):
		body.set_checkpoint(global_position)

	# Swap texture if this is the first time
	if not activated:
		_activate()

func _activate() -> void:
	activated = true
	_apply_texture()

	if make_unique:
		# Deactivate all other checkpoints in the scene
		for cp in get_tree().get_nodes_in_group("checkpoint"):
			if cp == self:
				continue
			if cp is Checkpoint:
				cp.deactivate()

func deactivate() -> void:
	if activated:
		activated = false
		_apply_texture()
