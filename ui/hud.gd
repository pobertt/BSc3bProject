extends Control

@export var player : Player
@export var weapon_manager: WeaponManager
@onready var label: Label = $Label
@export var health_bar: ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	health_bar.show()
	
	player.health_changed.connect(update_health_bar)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if weapon_manager.current_weapon:
		label.text = str(weapon_manager.current_weapon.current_ammo) + " / " + str(weapon_manager.current_weapon.reserve_ammo)

func update_health_bar(health_value):
	health_bar.value = health_value
