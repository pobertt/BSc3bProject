class_name Player
extends CharacterBody3D

signal health_changed(health_value)
signal add_health(health_value)

# References.
@onready var world_model: Node3D = $world_model
@onready var head: Node3D = $head_original_pos/head
@onready var camera: Camera3D = $head_original_pos/head/camera
@onready var weapon_view_model: Node3D = $head_original_pos/head/camera/weapon_view_model
@onready var movement_manager: MovementManager = $movement_manager
@onready var raycast: RayCast3D = $head_original_pos/head/camera/BulletRayCast3D
@onready var weapon_manager: WeaponManager = $weapon_manager
@export var robot: MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var anim_player: AnimationPlayer = $world_model/desert_droid_container/desert_droid/AnimationPlayer
@onready var animation_tree : AnimationTree = $world_model/desert_droid_container/AnimationTree
@onready var state_machine_playback : AnimationNodeStateMachinePlayback = $world_model/desert_droid_container/AnimationTree.get("parameters/playback")
@onready var cam_marker: Marker3D = $head_original_pos/head/marker
@onready var muzzle_flash: GPUParticles3D = $head_original_pos/head/camera/MuzzleFlash

# Multiplayer Player ID.
@export var player_id := 1:
	set(id):
		player_id = id

# Player settings.
@export var look_sensitivity: float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var health := 100
var robot_mat := StandardMaterial3D.new()

# Headbob settings.
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0

# Ground movement settings.
@export var walk_speed := 7.0
@export var sprint_speed := 8.5

# Crouch settings.
const CROUCH_TRANSLATE = 0.7
const CROUCH_JUMP_ADD = CROUCH_TRANSLATE * 0.9 # * 0.9 for sourcelike camera jitter in air on crouch, makes for a nice notifier
var is_crouched := false

# 
const VIEW_MODEL_LAYER = 9
const WORLD_MODEL_LAYER = 2

# Spawn pos.
var spawn_positions = [Vector3(25, 2, 0), Vector3(0, 2, 25), Vector3(0, 2, -25), Vector3(-25, 2, 0)]

# Recoil vars.
var target_recoil := Vector2.ZERO
var current_recoil := Vector2.ZERO
const RECOIL_APPLY_SPEED : float = 10.0
const RECOIL_RECOVER_SPEED : float = 7.0

# Powerup vars.
var active : bool = false
var dash_count : int = 0
@export var dashs : int = 0
var dash_active : bool = false
const DASH_SPEED = 25
var double_jump_active : bool = false
var jump_count : int = 0
@export var jumps : int = 1
const JUMP_VELOCITY = 9

# Setting up multiplayer authority, correspoding to correct peer_id.
func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	
	# Setting different player colours.
	MultiplayerManager.set_colour(self)

# More robust version of enabling sprint. 
func _get_move_speed() -> float:
	if is_crouched:
		return walk_speed * 0.8
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func _ready():
	# Checking multiplayer authority.
	if not is_multiplayer_authority(): return
	
	_update_view_and_world_model_masks()
	
	# Camera is current for the correct player character.
	camera.current = true
	
	# Set movement for different players (not entirely needed just cleans up the code)
	movement_manager.init_movement_manager(self)

@rpc("call_local")
func _update_view_and_world_model_masks():
	if not is_multiplayer_authority(): return
	
	# For some reason the @onready references do not work (a godot thing I don't understand (says it is a null value)) 
	# Hiding character body from player. 
	for child in $world_model.find_children("*", "VisualInstance3D", true, false):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(WORLD_MODEL_LAYER, true)
	for child in $head_original_pos/head/camera/weapon_view_model.find_children("*", "VisualInstance3D", true, false):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(VIEW_MODEL_LAYER, true)
		if child is GeometryInstance3D:
			child.cast_shadow = false
			
	$head_original_pos/head/camera.set_cull_mask_value(WORLD_MODEL_LAYER, false)
	# If I had a 3rd person camera.
	#camera_third_person.set_cull_mask_value(VIEW_MODEL_LAYER, false)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("shoot"):
		shoot_animation.rpc()
	
	# Weapon switching.
	if event.is_action_pressed("gun1"): 
		weapon_manager.current_weapon = weapon_manager.equipped_weapons[0]
		print(weapon_manager.current_weapon)
		weapon_manager._update_weapon_model()
	elif event.is_action_pressed("gun2"):
		weapon_manager.current_weapon = weapon_manager.equipped_weapons[1]
		print(weapon_manager.current_weapon)
		weapon_manager._update_weapon_model()
		
	if event is InputEventMouseMotion:
		# Capturing the mouse to the screen.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		# Making mouse visible when doing menus.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Camera Rotation.
		if event is InputEventMouseMotion:
			# Left and right.
			rotate_y(-event.relative.x * look_sensitivity)
			# Up and down.
			camera.rotate_x(-event.relative.y * look_sensitivity)
			# Limited to looking down to feet and up to the sky. Otherwise it would rotate forever (back/frontflips)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

@rpc("call_local")
func shoot_animation():
	anim_player.stop()
	anim_player.play("PistolShoot")

func _headbob_effect(delta: float):
	# Gets absolute velocity. The faster we are moving, the faster our head is bobbing.
	headbob_time += delta * self.velocity.length()
	# Uses sine & cosine waves functions with time, moves the head up and down with time.
	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

@onready var _original_capsule_height = $CollisionShape3D.shape.height
func _handle_crouch(delta: float) -> void:
	
	var was_crouched_last_frame = is_crouched
	if Input.is_action_pressed("crouch"):
		is_crouched = true
	elif is_crouched and not self.test_move(self.transform, Vector3(0,CROUCH_TRANSLATE,0)):
		is_crouched = false
		play_crouch_anim.rpc(is_crouched)
		
	# Allow for crouch to heighgten/extend a jump.
	var translate_y_if_possible := 0.0
	if was_crouched_last_frame != is_crouched and not is_on_floor():
		translate_y_if_possible = CROUCH_JUMP_ADD if is_crouched else -CROUCH_JUMP_ADD
	
	# Make sure not to get player stuck in floor/ceiling during crouch jumps
	if translate_y_if_possible != 0.0:
		var result = KinematicCollision3D.new()
		self.test_move(self.transform, Vector3(0,translate_y_if_possible,0), result)
		self.position.y += result.get_travel().y
		# For camera smoothing.
		head.position.y -= result.get_travel().y
		head.position.y = clampf(head.position.y, -CROUCH_TRANSLATE, 0)
	# Also for camera smoothing.
	head.position.y = move_toward(head.position.y, -CROUCH_TRANSLATE if is_crouched else 0, 7.0 * delta)
	
	# For 3rd person crouch visuals.
	#$world_model/desert_droid_container.mesh.height = $CollisionShape3D.shape.height
	#$world_model/desert_droid_container.position.y = $CollisionShape3D.position.y

@rpc("call_local")
func play_crouch_anim(is_crouched):
	var rel_vel = self.global_basis.inverse() * ((self.velocity * Vector3(1,0,1)) / _get_move_speed())
	var rel_vel_xz = Vector2(rel_vel.x, -rel_vel.z)
	collision_shape.position.y = collision_shape.shape.height / 2
	
	if is_crouched:
		print(player_id)
		collision_shape.shape.height = _original_capsule_height - CROUCH_TRANSLATE 
		state_machine_playback.travel("CrouchBlendSpace2D")
		animation_tree.set("parameters/CrouchBlendSpace2D/blend_position", rel_vel_xz)
	else:
		collision_shape.shape.height = _original_capsule_height
		state_machine_playback.travel("WalkBlendSpace2D")
		animation_tree.set("parameters/WalkBlendSpace2D/blend_position", rel_vel_xz)

@rpc("call_local")
func play_movement_anim():
	var rel_vel = self.global_basis.inverse() * ((self.velocity * Vector3(1,0,1)) / _get_move_speed())
	var rel_vel_xz = Vector2(rel_vel.x, -rel_vel.z)
	
	if Input.is_action_pressed("sprint"):
		state_machine_playback.travel("RunBlendSpace2D")
		animation_tree.set("parameters/RunBlendSpace2D/blend_position", rel_vel_xz)
	else:
		state_machine_playback.travel("WalkBlendSpace2D")
		animation_tree.set("parameters/WalkBlendSpace2D/blend_position", rel_vel_xz)

@rpc("any_peer")
func _recieve_damage():
	if not is_multiplayer_authority(): return
	
	health -= weapon_manager.current_weapon.damage
	print(health)
	if health <= 0:
		health = 100
		dead()
	health_changed.emit(health)

func dead():
	# Setting new position when health = 0
	var new_pos = spawn_positions.pick_random()
	position = new_pos

# Recoil for gun.
func add_recoil(pitch: float, yaw: float) -> void:
	target_recoil.x += pitch
	target_recoil.y += yaw

# The guns current recoil.
func get_current_recoil() -> Vector2:
	return current_recoil

# Every frame recoil drifts back towards 0
func update_recoil(delta: float) -> void:
	# Slowly move target recoil back to 0,0
	target_recoil = target_recoil.lerp(Vector2.ZERO, RECOIL_RECOVER_SPEED * delta)
	
	# Slowly move current recoil to the target recoil
	# Save current recoil of player
	var prev_recoil = current_recoil
	# Move current recoil to target recoil
	current_recoil = current_recoil.lerp(target_recoil, RECOIL_APPLY_SPEED * delta)
	# Give us the amount of recoil this frame
	var recoil_difference = current_recoil - prev_recoil
	
	# Rotate the player/camera to current recoil
	# Rotate character body by the Yaw (horizontal movement)
	rotate_y(recoil_difference.y)
	# Rotate the camera by the Pitch (vertical movement)
	camera.rotate_x(recoil_difference.x)
	# Clamp so recoil doesn't go crazy
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

@rpc("call_local")
func gain_jumps(active):
	# Setting double jump powerup.
	if active == true:
		print("double jump active")
		double_jump_active = active

@rpc("call_local")
func gain_dash(active):
	# Setting dash powerup.
	if active == true:
		print("dash active")
		dash_active = active

@rpc("call_local")
func gain_health(active):
	# Adding health.
	if active == true and health < 100:
		health = health + 25
		add_health.emit(health)

func handle_jump():
	# Allows another jump if the powerup is active
	if double_jump_active == true and not is_on_floor() and Input.is_action_just_pressed("jump"):
		self.velocity.y = jump_velocity * 1.5
		double_jump_active = false
		
	if is_on_floor():
		# Handle jump.
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_velocity
		# Resets to 0 when jumps are used.
		jump_count = 0

func check_dash():
	if Input.is_action_just_pressed("dash"):
		if(dash_active):
			#$player_audios/dash.play()
			var aim = camera.get_global_transform().basis
			var dash_direction = Vector3()
			
			# Dashes towards the direction the cam_marker is pointing towards.
			dash_direction += aim.z * (cam_marker.global_position.z * -(1/ cam_marker.global_position.z))
			dash_direction = dash_direction.normalized()
			
			# Setting the dash speed.
			var dash_vector = dash_direction * DASH_SPEED
			velocity += dash_vector
			# Resetting the dash
			print("dash used")
			dash_active = false

func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	update_recoil(delta)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	var input_dir := Input.get_vector("left", "right", "up", "down").normalized()
	# Depending on which way you have your character facing, you may have to negate the input directions.
	movement_manager.wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	# Handling all player movement functions.
	_handle_crouch(delta)
	
	handle_jump()
	
	if is_on_floor():
		movement_manager._handle_ground_physics(delta)
	else:
		movement_manager._handle_air_physics(delta)
		
	#_update_animations.rpc()
	if is_crouched:
		play_crouch_anim.rpc(is_crouched)
	else:
		play_crouch_anim.rpc(is_crouched)
		play_movement_anim.rpc()
	
	check_dash()
	
	move_and_slide()

# Something to do with blend spaces that dont let anims seen on multiplayer
#@rpc("call_local")
#func _update_animations():
	#if not is_on_floor():
		#if is_crouched:
			#state_machine_playback.travel("MidJumpCrouch")
		#else:
			#state_machine_playback.travel("MidJump")
		#return
	#
	#var rel_vel = self.global_basis.inverse() * ((self.velocity * Vector3(1,0,1)) / _get_move_speed())
	#var rel_vel_xz = Vector2(rel_vel.x, -rel_vel.z)
	#
	#if is_crouched:
		#state_machine_playback.travel("CrouchBlendSpace2D")
		#animation_tree.set("parameters/CrouchBlendSpace2D/blend_position", rel_vel_xz)
	#elif Input.is_action_pressed("sprint"):
		#state_machine_playback.travel("RunBlendSpace2D")
		#animation_tree.set("parameters/RunBlendSpace2D/blend_position", rel_vel_xz)
	#else:
		#state_machine_playback.travel("WalkBlendSpace2D")
		#animation_tree.set("parameters/WalkBlendSpace2D/blend_position", rel_vel_xz)
