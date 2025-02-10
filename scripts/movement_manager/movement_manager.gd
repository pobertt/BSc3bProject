class_name MovementManager
extends Node3D

var player_ref : Player

var wish_dir := Vector3.ZERO

# Ground movement settings
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

# Air movement settings.
@export var air_cap := 0.85 # Surf steeper ramps if higher
@export var air_accel := 800.0
@export var air_move_speed := 500.0

func init_movement_manager(new_player: Player) -> void:
	player_ref = new_player

func _handle_air_physics(delta: float) -> void:
	player_ref.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	# Classic battle tested & fan favourite source/quake air movement recipe.
	# Dot product is the measure of how much two vectors are pointing in the same direction.
	var cur_speed_in_wish_dir = player_ref.velocity.dot(wish_dir)
	
	# Wish speed (if wish_dir > 0 length) capped to the air_cap
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	
	# How much to get to the spped the player wishes (in the new dir).
	# This allows for infinite speed. If wish_dir is perpendicular, we always need to add velocity no matter how fast we're going.
	# This is what allows for things like bhop in CSS & Quake.
	# Also happens to just give some very nice feeling movement & responsiveness when in the air.
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta # Usually adding in this one.
		accel_speed = min(accel_speed, add_speed_till_cap) # Works okay without this but sticking to classic game recipe.
		player_ref.velocity += accel_speed * wish_dir

func _handle_ground_physics(delta: float) -> void:
	# Similar to the air movement. Acceleration and friction on ground.
	var cur_speed_in_wish_dir = player_ref.velocity.dot(wish_dir)
	var add_speed_till_cap = player_ref._get_move_speed() - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * player_ref._get_move_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		player_ref.velocity += accel_speed * wish_dir
		
	# Apply friction. 
	var control = max(player_ref.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(player_ref.velocity.length() - drop, 0.0)
	if player_ref.velocity.length() > 0:
		new_speed /= player_ref.velocity.length()
	player_ref.velocity *= new_speed
	
	player_ref._headbob_effect(delta)
