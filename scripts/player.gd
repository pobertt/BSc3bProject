extends CharacterBody3D

@onready var world_model: Node3D = $world_model
@onready var head: Node3D = $head
@onready var camera: Camera3D = $head/camera

@export var look_sensitivity: float = 0.006
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var walk_speed := 7.0
@export var sprint_speed := 8.5

var wish_dir := Vector3.ZERO

const SPEED = 10.0
const JUMP_VELOCITY = 10.0

@export var player_id := 1:
	set(id):
		player_id = id

# Setting up multiplayer authority, correspoding to correct peer_id.
func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

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

func _process(delta: float) -> void:
	pass
	
func _handle_air_physics(delta: float) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
func _handle_ground_physics(delta: float) -> void:
	self.velocity.x = wish_dir.x * walk_speed
	self.velocity.z = wish_dir.z * walk_speed

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "up", "down").normalized()
	# Depending on which way you have your character facing, you may have to negate the input directions.
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	if is_on_floor():
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	move_and_slide()
