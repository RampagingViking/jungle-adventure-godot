## ============================================================================
## 🌴 JUNGLE ADVENTURE - PLAYER CONTROLLER v2.0
## ============================================================================
## Enhanced with bug fixes and polish.
##
## v2.0 IMPROVEMENTS:
## - Coyote time (jump after leaving ledge)
## - Jump buffering (queue jump before landing)
## - Better grounded checks
## ============================================================================

extends CharacterBody2D

## ============================================================================
## SECTION 1: EXPORT VARIABLES
## ============================================================================

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

@export_category("Polish (v2.0)")
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export_category("References")
@export var feet_position: Node2D
@export var body_sprite: Sprite2D
@export var dust_particles: GPUParticles2D
@export var audio_player: AudioStreamPlayer

## ============================================================================
## SECTION 2: STATE VARIABLES
## ============================================================================

var current_jumps: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

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

var jump_sounds: Array[AudioStream] = []
var roll_sounds: Array[AudioStream] = []
var pound_sounds: Array[AudioStream] = []

## ============================================================================
## SECTION 3: _ready()
## ============================================================================
func _ready():
	if feet_position == null:
		feet_position = Node2D.new()
		feet_position.name = "FeetPosition"
		add_child(feet_position)
		feet_position.position = Vector2(0, 30)
	
	if body_sprite == null:
		for child in get_children():
			if child is Sprite2D:
				body_sprite = child
				break

## ============================================================================
## SECTION 4: _physics_process()
## ============================================================================
func _physics_process(delta):
	if is_dead:
		return
	
	var horizontal_input = Input.get_axis("ui_left", "ui_right")
	var jump_pressed = Input.is_action_just_pressed("ui_accept")
	var roll_pressed = Input.is_action_just_pressed("ui_select")
	var ground_pound_pressed = Input.is_action_just_pressed("ui_down")
	
	_update_cooldowns(delta)
	
	# Jump buffering
	if jump_pressed:
		jump_buffer_timer = jump_buffer_time
	
	var buffered_jump = jump_buffer_timer > 0 and current_jumps < max_jumps and not is_rolling and not is_in_barrel_cannon
	
	# Special moves
	if ground_pound_pressed and can_ground_pound and not is_grounded and not is_rolling and not is_in_barrel_cannon:
		_ground_pound()
	
	if roll_pressed and can_roll and is_grounded and not is_rolling and not is_in_barrel_cannon:
		_start_roll()
	
	if (jump_pressed or buffered_jump) and current_jumps < max_jumps and not is_rolling and not is_in_barrel_cannon:
		_jump()
	
	if not is_in_barrel_cannon:
		_move(horizontal_input, delta)
	
	_apply_gravity(delta)
	
	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0:
			_end_roll()
	
	_update_timers(delta)
	move_and_slide()
	_check_grounded()
	_update_animation()

## ============================================================================
## SECTION 5: MOVEMENT
## ============================================================================
func _move(horizontal_input: float, delta: float):
	if is_rolling:
		var roll_direction = -1 if body_sprite and body_sprite.flip_h else 1
		velocity.x = roll_direction * roll_speed
	else:
		var target_speed = horizontal_input * move_speed
		
		if abs(horizontal_input) > 0.01:
			var accel_rate = acceleration if abs(target_speed) > abs(velocity.x) else deceleration
			velocity.x = move_toward(velocity.x, target_speed, accel_rate * delta)
			if body_sprite:
				body_sprite.flip_h = horizontal_input < 0
		else:
			velocity.x = move_toward(velocity.x, 0, deceleration * delta)

## ============================================================================
## SECTION 6: JUMP
## ============================================================================
func _jump():
	velocity.y = jump_force
	current_jumps += 1
	_create_dust()
	_play_random_sound(jump_sounds)

## ============================================================================
## SECTION 7: ROLL
## ============================================================================
func _start_roll():
	is_rolling = true
	can_roll = false
	roll_timer = roll_duration
	roll_cooldown_timer = roll_cooldown
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	_create_dust()
	_play_random_sound(roll_sounds)

func _end_roll():
	is_rolling = false
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", false)
	
	var roll_direction = -1 if body_sprite and body_sprite.flip_h else 1
	velocity.x = roll_direction * move_speed * after_roll_momentum

## ============================================================================
## SECTION 8: GROUND POUND
## ============================================================================
func _ground_pound():
	can_ground_pound = false
	ground_pound_cooldown_timer = ground_pound_cooldown
	velocity.y = ground_pound_force
	_create_dust()
	_play_random_sound(pound_sounds)

## ============================================================================
## SECTION 9: GROUNDED CHECK (v2.0 - with coyote time)
## ============================================================================
func _check_grounded():
	if is_on_floor():
		is_grounded = true
		current_jumps = 0
		coyote_timer = coyote_time
		
		if roll_cooldown_timer <= 0:
			can_roll = true
		if ground_pound_cooldown_timer <= 0:
			can_ground_pound = true
	else:
		if coyote_timer > 0:
			is_grounded = true
		else:
			is_grounded = false

## ============================================================================
## SECTION 10: TIMERS
## ============================================================================
func _update_cooldowns(delta: float):
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
	if ground_pound_cooldown_timer > 0:
		ground_pound_cooldown_timer -= delta

func _update_timers(delta: float):
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

## ============================================================================
## SECTION 11: GRAVITY
## ============================================================================
func _apply_gravity(delta: float):
	if velocity.y < 0:
		pass
	elif velocity.y > 0:
		velocity.y += gravity * (fall_multiplier - 1) * delta
	
	if velocity.y < 0 and not Input.is_action_pressed("ui_accept"):
		velocity.y -= gravity * (low_jump_multiplier - 1) * delta

## ============================================================================
## SECTION 12: ANIMATION
## ============================================================================
func _update_animation():
	pass

## ============================================================================
## SECTION 13: HELPERS
## ============================================================================
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

func collect_banana():
	pass

## ============================================================================
## SECTION 14: BARREL CANNON
## ============================================================================
func enter_barrel_cannon(direction: Vector2):
	is_in_barrel_cannon = true
	barrel_direction = direction.normalized()
	velocity = Vector2.ZERO
	set_physics_process(false)

func fire_from_barrel():
	is_in_barrel_cannon = false
	set_physics_process(true)
	velocity = barrel_direction * barrel_launch_speed

## ============================================================================
## END OF PLAYER CONTROLLER v2.0
## ============================================================================
