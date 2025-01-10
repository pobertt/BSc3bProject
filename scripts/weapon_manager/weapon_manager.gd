class_name WeaponManager
extends Node3D

@export var allow_shoot: bool = true

@export var current_weapon: WeaponResource

@export var player : CharacterBody3D
@export var bullet_ray_cast_3d: RayCast3D

@export var view_model_container: Node3D
@export var world_model_container: Node3D

var current_weapon_view_model: Node3D
var current_weapon_world_model: Node3D

@onready var audio_stream_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Positioning weapon model. The data (pos, rot and scale) is input into the weapon resource, example: deagle.tres 
func _update_weapon_model() -> void:
	if current_weapon != null:
		current_weapon.weapon_manager = self
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
		
		current_weapon.is_equipped = true
		
		if player.has_method("_update_view_and_world_model_masks"):
			player._update_view_and_world_model_masks()
			
func _play_sound(sound: AudioStream):
	if sound:
		if audio_stream_player.stream != sound:
			audio_stream_player.stream = sound
		audio_stream_player.play()

func _stop_sounds():
	audio_stream_player.stop() 

func _play_anim(name: String):
	var anim_player: AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	if not anim_player or not anim_player.has_animation(name):
		return
	
	anim_player.seek(0.0)
	anim_player.play(name)

func _queue_anim(name: String):
	var anim_player: AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	if not anim_player: return
	anim_player.queue(name)

func _unhandled_input(event: InputEvent) -> void:
	if current_weapon and is_inside_tree():
		if event.is_action_pressed("shoot") and allow_shoot:
			current_weapon.trigger_down = true
		elif event.is_action_released("shoot"):
			current_weapon.trigger_down = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_weapon_model()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
