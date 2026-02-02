extends Area2D

## Banana collectible - the primary scoring item
## Inspired by Donkey Kong Country's banana coins
## Ported from Unity to Godot

@export_category("Banana Settings")
@export var banana_value: int = 10
@export var rotation_speed: float = 90.0
@export var bob_speed: float = 2.0
@export var bob_amount: float = 10.0

@export_category("References")
@export var banana_sprite: Sprite2D
@export var collect_sound: AudioStream
@export var collect_particles: GPUParticles2D

## State
var start_position: Vector2
var is_collected: bool = false
var bob_offset: float = 0.0

func _ready():
	start_position = position
	
	if banana_sprite == null:
		for child in get_children():
			if child is Sprite2D:
				banana_sprite = child
				break
	
	# Connect body_entered signal for player detection
	body_entered.connect(_on_body_entered)
	
	print("Banana ready at: ", position)

func _process(delta):
	if is_collected:
		return
	
	# Rotate banana
	rotation_degrees += rotation_speed * delta
	
	# Bob up and down
	bob_offset = sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_amount
	position.y = start_position.y + bob_offset

func _on_body_entered(body: Node):
	if is_collected:
		return
	
	# Check if it's the player
	if body.name.begins_with("Player") or body.has_method("collect_banana"):
		_collect(body)

func _collect(player):
	if is_collected:
		return
	
	is_collected = true
	
	# Notify player
	if player.has_method("collect_banana"):
		player.collect_banana()
	
	print("Banana collected! Value: ", banana_value)
	
	# Play collect effects
	_play_collect_effects()
	
	# Disable and hide
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	
	# Queue free after short delay
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _play_collect_effects():
	# Sound
	if collect_sound:
		var sound_player = AudioStreamPlayer.new()
		sound_player.stream = collect_sound
		add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)
	
	# Particles
	if collect_particles:
		collect_particles.emitting = true
