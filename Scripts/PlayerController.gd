extends CharacterBody2D

## Core player controller with rolling, ground pound, and barrel mechanics
## Inspired by Donkey Kong Country series
## Ported from Unity to Godot

@export_category("Movement")
@export var move_speed: float = 8.0
@export var acceleration: float = 50.0
@export var deceleration: float = 30.0

@export_category("Jump")
@export var jump_force: float = 14.0
@export var fall_multiplier: float = 2.5
@export var low_jump_multiplier: float = 2.0
@export var max_jumps: int = 2

@export_category("Roll")
@export var roll_speed: float = 12.0
@export var roll_duration: float = 0.4
@export var roll_cooldown: float = 0.5
@export var after_roll_momentum: float = 0.5

@export_category("Ground Pound")
@export var ground_pound_force: float = 25.0
@export var ground_pound_impact_radius: float = 3.0
@export var ground_pound_cooldown: float = 0.3

@export_category("Barrel Cannon")
@export var barrel_launch_speed: float = 20.0
@export var barrel_angle: float = 45.0

@export_category("References")
@export var feet_position: Node2D
@export var body_sprite: Sprite2D
@export var dust_particles: GPUParticles2D
@export var audio_player: AudioStreamPlayer

## State variables
var current_jumps: int = 0
var is_rolling: bool = false
var can_roll: bool = true
var can_ground_pound: bool = true
var is_in_barrel_cannon: bool = false
var barrel_direction: Vector2 = Vector2.ZERO
var roll_timer: float = 0.0
var roll_cooldown_timer: float = 0.0
var ground_pound_cooldown_timer: float = 0.0
var input_vector: Vector2 = Vector2.ZERO
var is_grounded: bool = false
var is_dead: bool = false

## Audio clips
var jump_sounds: Array[AudioStream] = []
var roll_sounds: Array[AudioStream] = []
var pound_sounds: Array[AudioStream] = []

func _ready():
	# Initialize feet position if not set
	if feet_position == null:
		feet_position = Node2D.new()
		feet_position.name = "FeetPosition"
		add_child(feet_position)
		feet_position.position = Vector2(0, 30)  # Adjust based on sprite size
	
	# Initialize sprite if not set
	if body_sprite == null:
		for child in get_children():
			if child is Sprite2D:
				body_sprite = child
				break
	
	print("PlayerController ready!")

func _physics_process(delta):
	if is_dead:
		return
	
	# Get input
	var horizontal_input = Input.get_axis("ui_left", "ui_right")
	
	# Check for special moves
	var jump_pressed = Input.is_action_just_pressed("ui_accept")  # Space
	var roll_pressed = Input.is_action_just_pressed("ui_select")  # X
	var ground_pound_pressed = Input.is_action_just_pressed("ui_down")  # Down arrow
	
	# Update cooldowns
	_update_cooldowns(delta)
	
	# Handle ground pound (only when not grounded and not rolling)
	if ground_pound_pressed and can_ground_pound and not is_grounded and not is_rolling and not is_in_barrel_cannon:
		_ground_pound()
	
	# Handle roll
	if roll_pressed and can_roll and is_grounded and not is_rolling and not is_in_barrel_cannon:
		_start_roll()
	
	# Handle jump
	if jump_pressed and current_jumps < max_jumps and not is_rolling and not is_in_barrel_cannon:
		_jump()
	
	# Handle movement
	if not is_in_barrel_cannon:
		_move(horizontal_input, delta)
	
	# Apply gravity with variable jump height
	_apply_gravity(delta)
	
	# Update rolling timer
	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0:
			_end_roll()
	
	# Move and slide
	move_and_slide()
	
	# Update grounded state
	_check_grounded()
	
	# Update animation
	_update_animation()

func _move(horizontal_input: float, delta: float):
	if is_rolling:
		# Rolling has fixed high speed
		var roll_direction = -1 if body_sprite and body_sprite.flip_h else 1
		velocity.x = roll_direction * roll_speed
	else:
		var target_speed = horizontal_input * move_speed
		
		if abs(horizontal_input) > 0.01:
			# Accelerate
			var accel_rate = acceleration if abs(target_speed) > abs(velocity.x) else deceleration
			velocity.x = move_toward(velocity.x, target_speed, accel_rate * delta)
			
			# Face direction
			if body_sprite:
				body_sprite.flip_h = horizontal_input < 0
		else:
			# Decelerate
			velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func _jump():
	velocity.y = jump_force
	current_jumps += 1
	_create_dust()
	_play_random_sound(jump_sounds)

func _start_roll():
	is_rolling = true
	can_roll = false
	roll_timer = roll_duration
	roll_cooldown_timer = roll_cooldown
	
	# Disable collision during roll
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	_create_dust()
	_play_random_sound(roll_sounds)

func _end_roll():
	is_rolling = false
	
	# Re-enable collision
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", false)
	
	# Small momentum boost after roll
	var roll_direction = -1 if body_sprite and body_sprite.flip_h else 1
	velocity.x = roll_direction * move_speed * after_roll_momentum

func _ground_pound():
	can_ground_pound = false
	ground_pound_cooldown_timer = ground_pound_cooldown
	
	# Launch downward
	velocity.y = ground_pound_force
	
	# Visual feedback
	_create_dust()
	_play_random_sound(pound_sounds)

func _check_grounded():
	if is_on_floor():
		is_grounded = true
		current_jumps = 0
		
		# Reset roll capability
		if roll_cooldown_timer <= 0:
			can_roll = true
		
		# Reset ground pound capability
		if ground_pound_cooldown_timer <= 0:
			can_ground_pound = true
	else:
		is_grounded = false

func _update_cooldowns(delta: float):
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
	if ground_pound_cooldown_timer > 0:
		ground_pound_cooldown_timer -= delta

func _apply_gravity(delta: float):
	if velocity.y < 0:  # Rising
		pass  # Normal gravity
	elif velocity.y > 0:  # Falling
		velocity.y += gravity * (fall_multiplier - 1) * delta
	
	# Variable jump height - reduce upward velocity if jump button released
	if velocity.y < 0 and not Input.is_action_pressed("ui_accept"):
		velocity.y -= gravity * (low_jump_multiplier - 1) * delta

func _update_animation():
	# Override this in a subclass or connect to AnimationPlayer
	pass

func _create_dust():
	if dust_particles:
		dust_particles.emitting = true

func _play_random_sound(sounds: Array[AudioStream]):
	if audio_player and sounds.size() > 0:
		var random_index = randi() % sounds.size()
		audio_player.stream = sounds[random_index]
		audio_player.play()

func die():
	if is_dead:
		return
	
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	print("Player died!")
	# Emit signal or call game manager

func collect_banana():
	print("Banana collected!")
	# Emit signal or call game manager

## Public methods for other scripts
func get_is_in_barrel() -> bool:
	return is_in_barrel_cannon

func is_grounded_state() -> bool:
	return is_grounded

## Barrel cannon integration
func enter_barrel_cannon(direction: Vector2):
	is_in_barrel_cannon = true
	barrel_direction = direction.normalized()
	velocity = Vector2.ZERO
	set_physics_process(false)  # Disable physics while in barrel

func fire_from_barrel():
	is_in_barrel_cannon = false
	set_physics_process(true)
	velocity = barrel_direction * barrel_launch_speed
