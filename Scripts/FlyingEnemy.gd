## ============================================================================
## 🌴 JUNGLE ADVENTURE - FLYING ENEMY (Kritter Variant)
## ============================================================================
## Flying enemy that patrols above and dives at player.
## ============================================================================

extends Node2D

@export_category("Flying Settings")
@export var fly_speed: float = 3.0
@export var fly_range_x: float = 5.0
@export var fly_range_y: float = 1.0
@export var fly_amplitude: float = 40.0
@export var fly_frequency: float = 1.5

@export_category("Combat")
@export var damage: int = 1
@export var health: int = 1
@export var can_be_stomped: bool = false
@export var dive_attack: bool = true
@export var dive_cooldown: float = 3.0
@export var dive_speed: float = 8.0

@export_category("References")
@export var sprite_renderer: Sprite2D
@export var wing_sound: AudioStream
@export var hit_sounds: Array[AudioStream]
@export var death_sounds: Array[AudioStream]

enum FlyingState { PATROL, DIVE, RETURN }
var current_state: FlyingState = FlyingState.PATROL

var start_position: Vector2
var original_y: float
var velocity: Vector2 = Vector2.ZERO
var direction: float = 1.0

var is_dead: bool = false
var is_invincible: bool = false
var hitbox_timer: float = 0.0

var fly_time: float = 0.0
var dive_timer: float = 0.0
var dive_target: Vector2 = Vector2.ZERO

func _ready():
	start_position = position
	original_y = position.y
	
	if sprite_renderer == null:
		for child in get_children():
			if child is Sprite2D:
				sprite_renderer = child
				break
	
	direction = randf_range(-1, 1) > 0 ? 1.0 : -1.0

func _physics_process(delta):
	if is_dead:
		return
	
	if is_invincible:
		hitbox_timer -= delta
		if hitbox_timer <= 0:
			is_invincible = false
			if sprite_renderer:
				sprite_renderer.modulate = Color.WHITE
	
	if dive_timer > 0:
		dive_timer -= delta
	
	match current_state:
		FlyingState.PATROL:
			_patrol_fly(delta)
			if dive_attack and dive_timer <= 0:
				var player = _get_player()
				if player and _can_dive(player):
					_start_dive(player)
		FlyingState.DIVE:
			_dive_movement(delta)
		FlyingState.RETURN:
			_return_to_patrol(delta)

func _patrol_fly(delta: float):
	fly_time += delta * fly_frequency
	var x_offset = sin(fly_time) * fly_range_x * direction
	var y_offset = sin(fly_time * 2) * fly_range_y * 0.5
	
	position.x = lerp(position.x, start_position.x + x_offset, delta * 2)
	position.y = lerp(position.y, start_position.y + y_offset, delta * 2)
	
	if sprite_renderer:
		sprite_renderer.flip_h = direction < 0

func _can_dive(player: Node) -> bool:
	if not player:
		return false
	return global_position.distance_to(player.global_position) < 300

func _start_dive(player: Node):
	current_state = FlyingState.DIVE
	dive_target = player.global_position
	dive_timer = dive_cooldown
	_play_sound(wing_sound)
	
	if sprite_renderer:
		sprite_renderer.modulate = Color(1, 0.5, 0.5)

func _dive_movement(delta: float):
	var target = dive_target
	var player = _get_player()
	if player and current_state == FlyingState.DIVE:
		target = player.global_position
	
	var dir = (target - global_position).normalized()
	velocity = dir * dive_speed
	global_position += velocity
	
	if global_position.distance_to(target) < 20:
		current_state = FlyingState.RETURN

func _return_to_patrol(delta: float):
	var target = Vector2(start_position.x, original_y)
	var dir = (target - global_position).normalized()
	velocity = dir * fly_speed * 0.7
	global_position += velocity
	
	if global_position.distance_to(target) < 10:
		current_state = FlyingState.PATROL

func take_damage(damage_amount: int):
	if is_dead or is_invincible:
		return
	
	health -= damage_amount
	is_invincible = true
	hitbox_timer = 0.3
	
	if sprite_renderer:
		sprite_renderer.modulate = Color(1, 0.3, 0.3)
	
	_play_sound_array(hit_sounds)
	
	if health <= 0:
		die()

func die():
	if is_dead:
		return
	
	is_dead = true
	
	var tween = create_tween()
	tween.tween_property(self, "rotation", PI, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.5)
	tween.tween_callback(queue_free)
	
	_play_sound_array(death_sounds)

func _on_body_entered(body: Node):
	if is_dead:
		return
	
	if body.name.begins_with("Player") or body.has_method("die"):
		if current_state == FlyingState.DIVE:
			body.die()
		else:
			body.die()

func _get_player() -> Node:
	var parent = get_parent()
	for child in parent.get_children():
		if child.name.begins_with("Player"):
			return child
	return null

func _play_sound(sound: AudioStream):
	if sound:
		var player = AudioStreamPlayer.new()
		player.stream = sound
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)

func _play_sound_array(sounds: Array[AudioStream]):
	if sounds.size() > 0:
		_play_sound(sounds[randi() % sounds.size()])

## ============================================================================
## END OF FLYING ENEMY
## ============================================================================
