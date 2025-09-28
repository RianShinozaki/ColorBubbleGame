extends Node

var last_checkpoint_pos: Vector2
var have_checkpoint := false

# how long the player is gray/invincible after respawn
const INVULN_TIME := 1.0

func set_checkpoint(pos: Vector2) -> void:
	last_checkpoint_pos = pos
	have_checkpoint = true

func respawn_player(player: Node) -> void:
	if have_checkpoint:
		player.global_position = last_checkpoint_pos
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	# gray color + short invulnerability window
	player.modulate = Color(0.6, 0.6, 0.6, 1.0)
	player.set_physics_process(true)
	player.set_process(true)
	player.set_meta("dead", false)
	# disable collisions or set a flag on the player
	player.set_collision_layer_value(1, false) # turn off main layer
	player.set_collision_mask_value(1, false)

	var t := get_tree().create_timer(INVULN_TIME)
	await t.timeout

	player.modulate = Color(1, 1, 1, 1)
	player.set_collision_layer_value(1, true)
	player.set_collision_mask_value(1, true)
