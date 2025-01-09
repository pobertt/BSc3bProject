class_name WeaponResource
extends Resource

# Used for the first person perspective, when holding the gun. Will include hand models.
@export var view_model: PackedScene
# Used for when the weapon is in the player's hand or on the ground
@export var world_model: PackedScene

@export var view_model_pos: Vector3
@export var view_model_rot: Vector3
@export var view_model_scale:= Vector3(1,1,1)
@export var world_model_pos: Vector3
@export var world_model_rot: Vector3
@export var world_model_scale:= Vector3(1,1,1)

@export var view_idle_anim: String
@export var view_equip_anim: String
@export var view_shoot_anim: String
@export var view_reload_anim: String

# Sounds.

@export var shoot_sound: AudioStream
@export var realod_sound: AudioStream
@export var unholster_sound: AudioStream

# Weapon Logic.

@export var damage = 10

const RAYCAST_DIST: float = 9999 # Too far seems to break it

var weapon_manager : WeaponManager

var trigger_down := false:
	set(v):
		if trigger_down != v:
			trigger_down = v
			if trigger_down:
				_on_trigger_down()
			else:
				_on_trigger_up()

var is_equipped := false:
	set(v):
		if is_equipped != v:
			is_equipped = v
			if is_equipped:
				_on_equip()
			else:
				_on_unequip()

func _on_trigger_down():
	_fire_shot()

func _on_trigger_up():
	pass

func _on_equip():
	weapon_manager._play_anim(view_equip_anim)
	weapon_manager._queue_anim(view_idle_anim)

func _on_unequip():
	pass

func _fire_shot():
	weapon_manager._play_sound(shoot_sound)
	weapon_manager._play_anim(view_shoot_anim)
	weapon_manager._queue_anim(view_idle_anim)
	
	var raycast = weapon_manager.bullet_ray_cast_3d
	raycast.target_position = Vector3(0,0, -abs(RAYCAST_DIST))
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var obj = raycast.get_collider()
		var nrml = raycast.get_collision_normal()
		var pt = raycast.get_collision_point()
		
		if obj is RigidBody3D:
			obj.apply_impulse(-nrml * 5.0 / obj.mass, pt - obj.global_position)
		
