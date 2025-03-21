class_name WeaponManager
extends Node3D

@export var allow_shoot: bool = true

@export var current_weapon: WeaponResource :
	set(v):
		if v != current_weapon:
			if current_weapon:
				current_weapon.is_equipped = false
			current_weapon = v;
			if is_inside_tree():
				_update_weapon_model()

@export var equipped_weapons : Array[WeaponResource]

@export var player : CharacterBody3D
@export var bullet_ray_cast_3d: RayCast3D

@export var view_model_container: Node3D
@export var world_model_container: Node3D

var current_weapon_view_model: Node3D
var current_weapon_world_model: Node3D

@onready var audio_stream_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Positioning weapon model. The data (pos, rot and scale) is input into the weapon resource, example: deagle.tres 
@rpc("call_local")
func _update_weapon_model() -> void:
	if not is_multiplayer_authority(): return
	
	# Bug can't see weapon until shot on deagle (need idle anim maybe?) and on alternate clients ammo count overlaps 
	if current_weapon_view_model != null and is_instance_valid(current_weapon_view_model):
		current_weapon_view_model.queue_free()
		current_weapon_view_model.get_parent().remove_child(current_weapon_view_model)
	if current_weapon_world_model != null and is_instance_valid(current_weapon_world_model):
		current_weapon_world_model.queue_free()
		current_weapon_world_model.get_parent().remove_child(current_weapon_world_model)
	
	if current_weapon != null:
		current_weapon.weapon_manager = self
		if view_model_container and current_weapon.view_model:
			current_weapon_view_model = current_weapon.view_model.instantiate()
			view_model_container.add_child(current_weapon_view_model)
			current_weapon_view_model.position = current_weapon.view_model_pos
			current_weapon_view_model.rotation = current_weapon.view_model_rot
			current_weapon_view_model.scale = current_weapon.view_model_scale
			if current_weapon_view_model.get_node_or_null("AnimationPlayer"):
				current_weapon_view_model.get_node_or_null("AnimationPlayer").connect("current_animation_changed", _current_anim_changed)
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

var last_played_anim: String = ""
var current_anim_finished_callback
var current_anim_cancelled_callback

@rpc("call_local")
func _play_anim(name: String, finished_callback = null, cancelled_callback = null):
	if not is_multiplayer_authority(): return
	
	var anim_player: AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	
	if last_played_anim and _get_anim() == last_played_anim and current_anim_cancelled_callback is Callable:
		current_anim_cancelled_callback.call() # Last anim didn't finish.
	
	if not anim_player or not anim_player.has_animation(name):
		if finished_callback is Callable:
			finished_callback.call() # Treat empty animations as finishing immediately
		return
	
	current_anim_finished_callback = finished_callback
	current_anim_cancelled_callback = cancelled_callback
	last_played_anim = name
	anim_player.clear_queue()
	anim_player.seek(0.0)
	anim_player.play(name)

func _queue_anim(name: String):
	if not is_multiplayer_authority(): return
	
	var anim_player: AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	if not anim_player: return
	anim_player.queue(name)

func _current_anim_changed(new_anim: StringName):
	if not is_multiplayer_authority(): return
	
	var anim_player: AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	if new_anim != last_played_anim and current_anim_finished_callback is Callable:
		current_anim_finished_callback.call()
	last_played_anim = anim_player.current_animation
	if last_played_anim != anim_player.current_animation:
		current_anim_finished_callback = null
		current_anim_cancelled_callback = null

func _get_anim() -> String:
	
	var anim_player : AnimationPlayer = current_weapon_view_model.get_node_or_null("AnimationPlayer")
	if not anim_player: return ""
	return anim_player.current_animation

var heat : float = 0.0
func apply_recoil():
	var spray_recoil := Vector2.ZERO
	if current_weapon.spray_pattern:
		spray_recoil = current_weapon.spray_pattern.get_point_position(int(heat) % current_weapon.spray_pattern.point_count) * 0.002
		print(spray_recoil)
		print(heat)
	var random_recoil := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 0.01
	var recoil = spray_recoil + random_recoil
	player.add_recoil(-recoil.y, -recoil.x)
	heat += 2.5

func get_current_recoil():
	return player.get_current_recoil() if player.has_method("get_current_recoil") else Vector2()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if current_weapon and is_inside_tree():
		if event.is_action_pressed("shoot") and allow_shoot:
			current_weapon.trigger_down = true
			
		elif event.is_action_released("shoot"):
			current_weapon.trigger_down = false

		if event.is_action_pressed("reload"):
			current_weapon._reload_pressed()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	_update_weapon_model()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if current_weapon:
		current_weapon._on_process(delta)
	
	# Slowly drifts it back to 0 when player isn't shooting
	if current_weapon.current_ammo == 0:
		heat = 0.0
	else:
		heat = max(0.0, heat - delta * 10.0)
	
