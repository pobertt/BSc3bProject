class_name WeaponManager
extends Node3D

@export var current_weapon: WeaponResource

@export var player : CharacterBody3D
@export var bullet_ray_cast_3d: RayCast3D

@export var view_model_container: Node3D
@export var world_model_container: Node3D

var current_weapon_view_model: Node3D
var current_weapon_world_model: Node3D

func _update_weapon_model() -> void:
	if current_weapon != null:
		if view_model_container and current_weapon.view_model:
			current_weapon_view_model = current_weapon.view_model.instantiate()
			view_model_container.add_child(current_weapon_view_model)
			current_weapon_view_model.position = current_weapon.view_model_pos
			current_weapon_view_model.rotation = current_weapon.view_model_rot
			current_weapon_view_model.scale = current_weapon.view_model_scale
		if world_model_container and current_weapon.world_model:
			current_weapon_world_model = current_weapon.world_model.instantiate()
			world_model_container.add_child(current_weapon_world_model)
			current_weapon_world_model.position = current_weapon.world_model_pos
			current_weapon_world_model.rotation = current_weapon.world_model_rot
			current_weapon_world_model.scale = current_weapon.world_model_scale

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_weapon_model()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
