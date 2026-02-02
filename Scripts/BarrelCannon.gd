extends Area2D

## Barrel cannon that launches player in an arc
## Inspired by Donkey Kong Country barrel mechanics
## Ported from Unity to Godot

@export_category("Barrel Settings")
@export var launch_speed: float = 25.0
@export var arc_angle: float = 45.0
@export var aim_speed: float = 3.0
@export var fire_cooldown: float = 0.5

@export_category("References")
@export var aim_indicator: Node2D
@export var barrel_sprite: Sprite2D
@export var aim_sound: AudioStream
@export var fire_sound: AudioStream
@export var steam_particles: GPUParticles2D

## State variables
var current_aim_angle: float = 45.0
var is_player_in_range: bool = false
var player: Node = null
var fire_cooldown_timer: float = 0.0

func _ready():
	current_aim_angle = arc_angle
	_update_aim_indicator()
	
	# Connect body signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("Barrel Cannon ready! Angle: ", current_aim_angle)

func _process(delta):
	# Handle cooldowns
	if fire_cooldown_timer > 0:
		fire_cooldown_timer -= delta
	
	# Aiming with input
	if is_player_in_range and player != null:
		_handle_aiming(delta)

func _handle_aiming(delta: float):
	var vertical_input = Input.get_axis("ui_up", "ui_down")
	
	if abs(vertical_input) > 0.1:
		current_aim_angle = clamp(current_aim_angle + vertical_input * aim_speed * delta * 50, 0, 90)
		_update_aim_indicator()
		
		if aim_sound:
			_play_sound(aim_sound)
	
	# Fire with fire button
	if Input.is_action_just_pressed("ui_select") and fire_cooldown_timer <= 0:
		_fire()

func _update_aim_indicator():
	if aim_indicator:
		aim_indicator.rotation_degrees = current_aim_angle
	
	if barrel_sprite:
		# Could rotate barrel sprite too
		pass

func _fire():
	# Launch player
	var rad_angle = deg_to_rad(current_aim_angle)
	var launch_direction = Vector2(cos(rad_angle), sin(rad_angle))
	
	player.enter_barrel_cannon(launch_direction)
	
	# Visual feedback
	_play_sound(fire_sound)
	
	if steam_particles:
		steam_particles.emitting = true
	
	# Reset aim after fire
	current_aim_angle = arc_angle
	_update_aim_indicator()
	
	fire_cooldown_timer = fire_cooldown
	
	# Invoke fire after short delay
	await get_tree().create_timer(0.1).timeout
	_launch_player()

func _launch_player():
	if player and player.has_method("fire_from_barrel"):
		player.fire_from_barrel()
	player = null

func _on_body_entered(body: Node):
	if body.name.begins_with("Player") or body.has_method("enter_barrel_cannon"):
		is_player_in_range = true
		player = body
		print("Player entered barrel range")

func _on_body_exited(body: Node):
	if body == player:
		is_player_in_range = false
		player = null

func _play_sound(sound: AudioStream):
	if sound:
		var sound_player = AudioStreamPlayer.new()
		sound_player.stream = sound
		add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)

## Helper for player to check if in barrel
func get_is_in_barrel() -> bool:
	return player != null
