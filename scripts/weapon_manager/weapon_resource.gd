class_name WeaponResource
extends Resource

signal hit_marker(player_hit)

# References.
var weapon_manager : WeaponManager

# Used for the first person perspective, when holding the weapon. Will include hand models (for most, not p90).
@export var view_model: PackedScene
# Used for when the weapon is in the player's hand or on the ground.
@export var world_model: PackedScene

# View/World model position, rotation and scale.
@export var view_model_pos: Vector3
@export var view_model_rot: Vector3
@export var view_model_scale:= Vector3(1,1,1)
@export var world_model_pos: Vector3
@export var world_model_rot: Vector3
@export var world_model_scale:= Vector3(1,1,1)

# Animations of weapon.
@export var view_idle_anim: String
@export var view_equip_anim: String
@export var view_shoot_anim: String
@export var view_reload_anim: String

# Sounds.
@export var shoot_sound: AudioStream
@export var reload_sound: AudioStream
@export var unholster_sound: AudioStream

# Weapon Logic.
@export var damage = 10
@export var current_ammo := INF
@export var magazine_capacity := INF
@export var reserve_ammo := INF
@export var max_reserve_ammo := INF
@export var auto_fire: bool = true
@export var max_fire_rate_ms: float = 50
@export var spray_pattern : Curve2D
const RAYCAST_DIST: float = 9999 # Too far seems to break it

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

var last_fire_time = -999999

func _on_process(delta):
	# Calls fire shot for auto weapons and reloads when reach ammo reaches 0.
	if trigger_down and auto_fire and Time.get_ticks_msec() - last_fire_time >= max_fire_rate_ms:
		if current_ammo > 0:
			_fire_shot()
		else:
			_reload_pressed()

func _on_trigger_down():
	# Calls fire shot for semi auto weapons
	if Time.get_ticks_msec() - last_fire_time > max_fire_rate_ms and current_ammo > 0:
		_fire_shot()
	elif current_ammo == 0:
		_reload_pressed()

func _on_trigger_up():
	pass

func _on_equip():
	# Playing anims for equipping the weapon.
	weapon_manager._play_anim(view_equip_anim)
	weapon_manager._queue_anim(view_idle_anim)

func _on_unequip():
	pass

func _get_amount_can_reload() -> int:
	# Returns if the weapon can be reloaded and calculates how much to add to magazine.
	var wish_reload = magazine_capacity - current_ammo
	var can_reload = min(wish_reload, reserve_ammo)
	return can_reload

# Plays animations and sounds when reloading.
func _reload_pressed():
	if view_reload_anim and weapon_manager._get_anim() == view_reload_anim:
		return
	if _get_amount_can_reload() <= 0:
		return
	var cancel_cb = (func():
		weapon_manager._stop_sounds())
	weapon_manager._play_anim(view_reload_anim, _reload, cancel_cb)
	weapon_manager._play_sound(reload_sound)
	weapon_manager._queue_anim(view_idle_anim)

func _reload():
	# Calculates the difference of how much ammo to add to the magazine and remove from reserve ammo.
	var can_reload = _get_amount_can_reload()
	if can_reload < 0:
		return
	elif magazine_capacity == INF or current_ammo == INF:
		current_ammo = magazine_capacity
	else:
		current_ammo += can_reload
		reserve_ammo -= can_reload

# Called for each bullet shot.
func _fire_shot():
	# Plays animations and sound.
	weapon_manager._play_sound(shoot_sound)
	weapon_manager._play_anim(view_shoot_anim)
	weapon_manager._queue_anim(view_idle_anim)
	weapon_manager.muzzle_flash.rpc()
	
	# Sets the raycast and moves raycast based on recoil.
	var raycast = weapon_manager.bullet_ray_cast_3d
	raycast.rotation.x = weapon_manager.get_current_recoil().x
	raycast.rotation.y = weapon_manager.get_current_recoil().y
	raycast.target_position = Vector3(0,0, -abs(RAYCAST_DIST))
	raycast.force_raycast_update()
	
	# If raycast collides it gets the object, normal and point of what it collides with.
	if raycast.is_colliding():
		var obj = raycast.get_collider()
		var nrml = raycast.get_collision_normal()
		var pt = raycast.get_collision_point()
		
		print(obj)
		
		# Calls take_damage for objects.
		if obj is RigidBody3D and obj.has_method("take_damage"):
			obj.take_damage.rpc(self.damage, pt, nrml)
		
		# Calls recieve_damage for players and displays hit marker.
		if obj is CharacterBody3D and obj.has_method("_recieve_damage"):
			obj._recieve_damage.rpc_id(obj.get_multiplayer_authority())
		if obj is CharacterBody3D:
			show_hit_marker()
	
	# Applys recoil for each shot fired.
	weapon_manager.apply_recoil()
	
	# Gets last time it fired and removes 1 from current ammo.
	last_fire_time = Time.get_ticks_msec()
	current_ammo -= 1

# Displays hit_marker in hud.
func show_hit_marker():
	hit_marker.emit(true)
