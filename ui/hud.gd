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
	
	player.health_changed.connect(update_health_bar)
	await get_tree().create_timer(0.5).timeout
	player.weapon_manager.current_weapon.hit_marker.connect(update_hit_marker)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if weapon_manager.current_weapon:
		label.text = str(weapon_manager.current_weapon.current_ammo) + " / " + str(weapon_manager.current_weapon.reserve_ammo)

func update_health_bar(health_value):
	health_bar.value = health_value
	damage_texture.show()
	await get_tree().create_timer(0.5).timeout
	damage_texture.hide()

func update_hit_marker(hit):
	print("being called")
	if hit:
		reticle.hide()
		hit_marker.show()
		await get_tree().create_timer(0.2).timeout
		hit == false
		reticle.show()
		hit_marker.hide()
