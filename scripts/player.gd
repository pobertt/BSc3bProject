extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D

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
	
	# Capturing the mouse to the screen.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Camera is current for the correct player character.
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	# Camera Rotation.
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
