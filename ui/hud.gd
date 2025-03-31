extends Control

@export var player : Player
@export var weapon_manager: WeaponManager
@onready var label: Label = $Label
@export var health_bar: ProgressBar
@onready var damage_texture: TextureRect = $hurt_img
@onready var hit_marker: TextureRect = $hit_marker
@onready var reticle: ColorRect = $reticle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health_bar.show()
	
	# Connecting the signals.
	player.health_changed.connect(update_health_bar)
	player.add_health.connect(add_health_bar)
	
	# Waits to do next frame because of some reference being set on the same frame.
	await get_tree().process_frame
	player.weapon_manager.current_weapon.hit_marker.connect(update_hit_marker)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if weapon_manager.current_weapon:
		label.text = str(weapon_manager.current_weapon.current_ammo) + " / " + str(weapon_manager.current_weapon.reserve_ammo)

# Called when player is damaged. Showing the red tint around the screen.
func update_health_bar(health_value):
	health_bar.value = health_value
	print("damage img being called")
	damage_texture.show()
	await get_tree().create_timer(0.5).timeout
	damage_texture.hide()

# Called when player picks up the Health powerup.
func add_health_bar(health_value):
	health_bar.value = health_value

# Called when shooting at an enemy. Showing the hitmarker icon.
func update_hit_marker(hit):
	if hit:
		print("hit marker being called")
		reticle.hide()
		hit_marker.show()
		await get_tree().create_timer(0.2).timeout
		hit == false
		reticle.show()
		hit_marker.hide()
