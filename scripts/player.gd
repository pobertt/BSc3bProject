extends CharacterBody3D

@onready var world_model: Node3D = $world_model
@onready var head: Node3D = $head
@onready var camera: Camera3D = $head/camera

@export var player_id := 1:
	set(id):
		player_id = id

@export var look_sensitivity: float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var walk_speed := 7.0
@export var sprint_speed := 8.5

const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0

# Air movement settings.
@export var air_cap := 0.85 # Surf steeper ramps if higher
@export var air_accel := 800.0
@export var air_move_speed := 500.0

var wish_dir := Vector3.ZERO

# Setting up multiplayer authority, correspoding to correct peer_id.
func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

# More robust version of enabling sprint. 
func _get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed

func _ready():
	# Checking multiplayer authority.
	if not is_multiplayer_authority(): return
	
	for child in world_model.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
		
	#Camera is current for the correct player character.
	camera.current = true

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

func _process(delta: float) -> void:
	pass
	
func _handle_air_physics(delta: float) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
func _handle_ground_physics(delta: float) -> void:
	self.velocity.x = wish_dir.x * _get_move_speed()
	self.velocity.z = wish_dir.z * _get_move_speed()
	
	_headbob_effect(delta)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	var input_dir := Input.get_vector("left", "right", "up", "down").normalized()
	# Depending on which way you have your character facing, you may have to negate the input directions.
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	if is_on_floor():
		# Handle jump.
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_velocity
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	move_and_slide()
