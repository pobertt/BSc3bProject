class_name WeaponResource
extends Resource

# Used for the first person perspective, when holding the gun. Will include hand models.
@export var view_model: PackedScene
# Used for when the weapon is in the player's hand or on the ground
@export var world_model: PackedScene

@export var view_model_pos: Vector3
@export var view_model_rot: Vector3
@export var view_model_scale:= Vector3(1,1,1)
@export var world_model_pos: Vector3
@export var world_model_rot: Vector3
@export var world_model_scale:= Vector3(1,1,1)

@export var damage = 10
