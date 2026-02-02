extends Node2D

## Enemy base class with stomp vulnerability from above
## Ported from Unity to Godot

@export_category("Enemy Settings")
@export var move_speed: float = 2.0
@export var move_range: float = 3.0
@export var damage: int = 1
@export var health: int = 1
@export var can_be_stomped: bool = true
@export var stomp_bounce_force: float = 10.0

@export_category("References")
@export var sprite_renderer: Sprite2D
@export var hit_sounds: Array[AudioStream] = []
@export var death_sounds: Array[AudioStream] = []

## State variables
var start_position: Vector2
var direction: float = 1.0
var is_dead: bool = false
var velocity: Vector2 = Vector2.ZERO

func _ready():
	start_position = position
	
	if sprite_renderer == null:
		for child in get_children():
			if child is Sprite2D:
				sprite_renderer = child
				break
	
	print("Enemy ready at position: ", position)

func _physics_process(delta):
	if is_dead:
		return
	
	_patrol(delta)

func _patrol(delta: float):
	var new_x = position.x + direction * move_speed * delta
	
	# Check patrol bounds
	if abs(new_x - start_position.x) > move_range:
		direction *= -1
	
	position.x = new_x
	
	# Face direction
	if sprite_renderer:
		sprite_renderer.flip_h = direction < 0

func take_damage(damage_amount: int):
	if is_dead:
		return
	
	health -= damage_amount
	
	# Flash effect
	_flash_white()
	
	_play_random_sound(hit_sounds)
	
	if health <= 0:
		die()

func die():
	if is_dead:
		return
	
	is_dead = true
	
	# Death animation
	_death_animation()
	
	_play_random_sound(death_sounds)
	
	print("Enemy died!")
	# Give player points - emit signal or call game manager

func _flash_white():
	if sprite_renderer:
		var original_modulate = sprite_renderer.modulate
		sprite_renderer.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if sprite_renderer:
			sprite_renderer.modulate = original_modulate

func _death_animation():
	# Simple death: fade out and shrink
	var duration = 0.3
	var elapsed = 0.0
	var start_scale = scale
	
	while elapsed < duration:
		var t = elapsed / duration
		scale = start_scale.lerp(Vector2.ZERO, t)
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	
	queue_free()

func _play_random_sound(sounds: Array[AudioStream]):
	if sounds.size() > 0:
		var random_index = randi() % sounds.size()
		var sound_player = AudioStreamPlayer.new()
		sound_player.stream = sounds[random_index]
		add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)

func _on_body_entered(body: Node):
	if is_dead:
		return
	
	# Check if player stomped from above
	if body.name.begins_with("Player") or body.has_method("jump"):
		if can_be_stomped:
			# Check if player is above enemy
			if body.global_position.y < global_position.y - 10:
				# Stomp kill!
				take_damage(health)  # Kill in one hit
				
				# Bounce player
				if body.has_method("jump"):
					body.velocity.y = stomp_bounce_force
			else:
				# Player takes damage
				body.die()
