extends CharacterBody3D

# References.
@onready var world_model: Node3D = $world_model
@onready var head: Node3D = $head_original_pos/head
@onready var camera: Camera3D = $head_original_pos/head/camera
@onready var weapon_view_model: Node3D = $head_original_pos/head/camera/weapon_view_model

# Multiplayer Player ID
@export var player_id := 1:
	set(id):
		player_id = id

# Player settings.
@export var look_sensitivity: float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var health = 100

# Headbob settings.
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0

# Ground movement settings.
@export var walk_speed := 7.0
@export var sprint_speed := 8.5
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

# Air movement settings.
@export var air_cap := 0.85 # Surf steeper ramps if higher
@export var air_accel := 800.0
@export var air_move_speed := 500.0

var wish_dir := Vector3.ZERO

# Crouch settings.
const CROUCH_TRANSLATE = 0.7
const CROUCH_JUMP_ADD = CROUCH_TRANSLATE * 0.9 # * 0.9 for sourcelike camera jitter in air on crouch, makes for a nice notifier
var is_crouched := false

# 
const VIEW_MODEL_LAYER = 9
const WORLD_MODEL_LAYER = 2

# Setting up multiplayer authority, correspoding to correct peer_id.
func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

# More robust version of enabling sprint. 
func _get_move_speed() -> float:
	if is_crouched:
		return walk_speed * 0.8
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func _ready():
	# Checking multiplayer authority.
	if not is_multiplayer_authority(): return
	
	_update_view_and_world_model_masks()
	
	#Camera is current for the correct player character.
	camera.current = true

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

func _headbob_effect(delta: float):
	# Gets absolute velocity. The faster we are moving, the faster our head is bobbing.
	headbob_time += delta * self.velocity.length()
	# Uses sine & cosine waves functions with time, to move the head up and down with time.
	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

@rpc("any_peer")
func _recieve_damage():
	health = health - 10
	print(health)
	if health <= 0:
		self.queue_free()

@onready var anim_player: AnimationPlayer = $world_model/desert_droid_container/desert_droid/AnimationPlayer

@onready var animation_tree : AnimationTree = $world_model/desert_droid_container/AnimationTree
@onready var state_machine_playback : AnimationNodeStateMachinePlayback = $world_model/desert_droid_container/AnimationTree.get("parameters/playback")

# Something to do with blend spaces that dont let anims seen on multiplayer
func _update_animations():
	if not is_on_floor():
		if is_crouched:
			state_machine_playback.travel("MidJumpCrouch")
		else:
			state_machine_playback.travel("MidJump")
		return
	
	var rel_vel = self.global_basis.inverse() * ((self.velocity * Vector3(1,0,1)) / _get_move_speed())
	var rel_vel_xz = Vector2(rel_vel.x, -rel_vel.z)
	
	if is_crouched:
		state_machine_playback.travel("CrouchBlendSpace2D")
		animation_tree.set("parameters/CrouchBlendSpace2D/blend_position", rel_vel_xz)
	elif Input.is_action_pressed("sprint"):
		state_machine_playback.travel("RunBlendSpace2D")
		animation_tree.set("parameters/RunBlendSpace2D/blend_position", rel_vel_xz)
	else:
		state_machine_playback.travel("WalkBlendSpace2D")
		animation_tree.set("parameters/WalkBlendSpace2D/blend_position", rel_vel_xz)

func _process(delta: float) -> void:
	pass
	
@onready var _original_capsule_height = $CollisionShape3D.shape.height
func _handle_crouch(delta: float) -> void:
	var was_crouched_last_frame = is_crouched
	if Input.is_action_pressed("crouch"):
		is_crouched = true
	elif is_crouched and not self.test_move(self.transform, Vector3(0,CROUCH_TRANSLATE,0)):
		is_crouched = false
		
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
	
	$CollisionShape3D.shape.height = _original_capsule_height - CROUCH_TRANSLATE if is_crouched else _original_capsule_height
	$CollisionShape3D.position.y = $CollisionShape3D.shape.height / 2
	# For crouch visuals.
	#$world_model/desert_droid_container.mesh.height = $CollisionShape3D.shape.height
	#$world_model/desert_droid_container.position.y = $CollisionShape3D.position.y

	
func _handle_air_physics(delta: float) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	# Classic battle tested & fan favourite source/quake air movement recipe.
	# Dot product is the measure of how much two vectors are pointing in the same direction.
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	
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
		self.velocity += accel_speed * wish_dir

func _handle_ground_physics(delta: float) -> void:
	# Similar to the air movement. Acceleration and friction on ground.
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = _get_move_speed() - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * _get_move_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	# Apply friction. 
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	
	_headbob_effect(delta)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	var input_dir := Input.get_vector("left", "right", "up", "down").normalized()
	# Depending on which way you have your character facing, you may have to negate the input directions.
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	_handle_crouch(delta)
	
	if is_on_floor():
		# Handle jump.
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
		
	_update_animations()
	
	move_and_slide()
