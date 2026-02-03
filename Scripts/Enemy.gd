## ============================================================================
## 🌴 JUNGLE ADVENTURE - ENEMY BASE CLASS v2.0
## ============================================================================
## Enhanced with polish fixes and new features.
##
## v2.0 IMPROVEMENTS:
## - Hitbox frames (invincibility after hit)
## - Death effects (particles, shake)
## - State machine (Idle, Patrol, Chase, Hit, Dead)
## - Flying/ranged enemy support
## ============================================================================

extends Node2D

## ============================================================================
## SECTION 1: EXPORT VARIABLES
## ============================================================================

@export_category("Enemy Settings")
@export var move_speed: float = 2.0
@export var move_range: float = 3.0
@export var damage: int = 1
@export var health: int = 1
@export var can_be_stomped: bool = true
@export var stomp_bounce_force: float = 10.0
@export var enemy_type: String = "ground"

@export_category("Polish")
@export var hitbox_frames: float = 0.3
@export var death_duration: float = 0.5
@export var enable_shake: bool = true
@export var enable_particles: bool = true

@export_category("References")
@export var sprite_renderer: Sprite2D
@export var hit_sounds: Array[AudioStream]
@export var death_sounds: Array[AudioStream]
@export var death_particles: PackedScene

## ============================================================================
## SECTION 2: STATE VARIABLES
## ============================================================================

enum EnemyState { IDLE, PATROL, CHASE, HIT, DEAD }
var current_state: EnemyState = EnemyState.IDLE

var start_position: Vector2
var direction: float = 1.0
var velocity: Vector2 = Vector2.ZERO

var is_dead: bool = false
var is_invincible: bool = false
var hitbox_timer: float = 0.0

var shake_intensity: float = 0.0
var original_position: Vector2

@export_category("Flying Settings")
@export var fly_amplitude: float = 30.0
@export var fly_frequency: float = 2.0
var fly_time: float = 0.0

@export_category("Ranged Settings")
@export var shoot_cooldown: float = 2.0
@export var projectile_scene: PackedScene
var shoot_timer: float = 0.0
@export var projectile_speed: float = 200.0

## ============================================================================
## SECTION 3: _ready()
## ============================================================================
func _ready():
	start_position = position
	original_position = position
	
	if sprite_renderer == null:
		for child in get_children():
			if child is Sprite2D:
				sprite_renderer = child
				break
	
	if enemy_type not in ["ground", "flying", "ranged"]:
		enemy_type = "ground"

## ============================================================================
## SECTION 4: _physics_process()
## ============================================================================
func _physics_process(delta):
	if is_dead:
		_death_animation_process(delta)
		return
	
	if is_invincible:
		hitbox_timer -= delta
		if hitbox_timer <= 0:
			is_invincible = false
			if sprite_renderer:
				sprite_renderer.modulate = Color.WHITE
	
	if enemy_type == "ranged" and current_state != EnemyState.HIT:
		shoot_timer -= delta
	
	match current_state:
		EnemyState.IDLE:
			_idle_state(delta)
		EnemyState.PATROL:
			_patrol_state(delta)
		EnemyState.CHASE:
			_chase_state(delta)
		EnemyState.HIT:
			_hit_state(delta)
	
	if enemy_type == "ground":
		position.x += velocity.x * delta
	elif enemy_type == "flying":
		_fly_bob(delta)

## ============================================================================
## SECTION 5: STATE FUNCTIONS
## ============================================================================

func _idle_state(delta: float):
	velocity.x = 0
	if randf() < 0.02:
		current_state = EnemyState.PATROL

func _patrol_state(delta: float):
	var new_x = position.x + direction * move_speed * delta
	if abs(new_x - start_position.x) > move_range:
		direction *= -1
	velocity.x = direction * move_speed
	if sprite_renderer:
		sprite_renderer.flip_h = direction < 0

func _chase_state(delta: float):
	var player = _get_player()
	if player:
		var dir_to_player = sign(player.global_position.x - global_position.x)
		velocity.x = dir_to_player * move_speed * 1.5
		if enemy_type == "ranged" and shoot_timer <= 0:
			_shoot_at_player(player)
	else:
		current_state = EnemyState.PATROL

func _hit_state(delta: float):
	velocity.x = 0
	if hitbox_timer <= 0:
		current_state = EnemyState.PATROL

## ============================================================================
## SECTION 6: FLYING ENEMY
## ============================================================================

func _fly_bob(delta: float):
	fly_time += delta * fly_frequency
	var bob_offset = sin(fly_time) * fly_amplitude
	position.y = start_position.y + bob_offset

## ============================================================================
## SECTION 7: RANGED ENEMY
## ============================================================================

func _shoot_at_player(player: Node):
	if not projectile_scene:
		return
	
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	var dir = sign(player.global_position.x - global_position.x)
	projectile.global_position = global_position
	projectile.velocity = Vector2(dir * projectile_speed, -50)
	shoot_timer = shoot_cooldown

## ============================================================================
## SECTION 8: TAKE DAMAGE
## ============================================================================

func take_damage(damage_amount: int):
	if is_dead or is_invincible:
		return
	
	health -= damage_amount
	is_invincible = true
	hitbox_timer = hitbox_frames
	current_state = EnemyState.HIT
	
	if sprite_renderer:
		sprite_renderer.modulate = Color(1, 0.3, 0.3)
	
	shake_intensity = 5.0
	_play_random_sound(hit_sounds)
	
	if health <= 0:
		die()

## ============================================================================
## SECTION 9: DIE
## ============================================================================

func die():
	if is_dead:
		return
	
	is_dead = true
	current_state = EnemyState.DEAD
	_play_random_sound(death_sounds)
	
	if enable_particles and death_particles:
		var particles = death_particles.instantiate()
		get_parent().add_child(particles)
		particles.global_position = global_position

## ============================================================================
## SECTION 10: DEATH ANIMATION
## ============================================================================

func _death_animation_process(delta: float):
	if sprite_renderer:
		var shrink_rate = delta / death_duration
		scale = scale.lerp(Vector2.ZERO, shrink_rate)
		rotation += delta * 2.0
		
		if shake_intensity > 0:
			var shake_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity
			sprite_renderer.position = shake_offset
			shake_intensity -= delta * 10
	
	if scale.x < 0.05:
		queue_free()

## ============================================================================
## SECTION 11: COLLISION
## ============================================================================

func _on_body_entered(body: Node):
	if is_dead:
		return
	
	if body.name.begins_with("Player") or body.has_method("jump"):
		if can_be_stomped and body.global_position.y < global_position.y - 10:
			take_damage(health)
			if body.has_method("jump"):
				body.velocity.y = stomp_bounce_force
		else:
			body.die()

## ============================================================================
## SECTION 12: HELPERS
## ============================================================================

func _get_player() -> Node:
	var parent = get_parent()
	for child in parent.get_children():
		if child.name.begins_with("Player"):
			return child
	return null

func _play_random_sound(sounds: Array[AudioStream]):
	if sounds.size() > 0:
		var sound_player = AudioStreamPlayer.new()
		sound_player.stream = sounds[randi() % sounds.size()]
		add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)

## ============================================================================
## END OF ENEMY v2.0
## ============================================================================
