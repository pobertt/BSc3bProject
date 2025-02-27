extends Control

@export var weapon_manager: WeaponManager
@onready var label: Label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if weapon_manager.current_weapon:
		label.text = str(weapon_manager.current_weapon.current_ammo) + " / " + str(weapon_manager.current_weapon.reserve_ammo)
