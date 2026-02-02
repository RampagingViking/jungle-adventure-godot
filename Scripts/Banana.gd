## ============================================================================
## 🌴 JUNGLE ADVENTURE - BANANA COLLECTIBLE
## ============================================================================
## Banana collectible item that the player can pick up.
## Provides points when collected.
##
## 🎓 KEY CONCEPTS YOU'LL LEARN:
## - Area2D: Detection zone for overlaps
## - Signals: Responding to player entering the area
## - Process loop: Continuous animation (rotation, bobbing)
## - Coroutines/Await: Waiting for timers without freezing
## ============================================================================

extends Area2D

## ============================================================================
## SECTION 1: EXPORT VARIABLES
## ============================================================================

@export_category("Banana Settings")
@export var banana_value: int = 10           ## Points awarded when collected
@export var rotation_speed: float = 90.0     ## Rotation speed (degrees/second)
@export var bob_speed: float = 2.0           ## Bobbing animation speed
@export var bob_amount: float = 10.0         ## Bobbing distance (pixels)

@export_category("References")
@export var banana_sprite: Sprite2D          ## Visual sprite
@export var collect_sound: AudioStream       ## Sound when collected
@export var collect_particles: GPUParticles2D  ## Particle effect

## ============================================================================
## SECTION 2: STATE VARIABLES
## ============================================================================

var start_position: Vector2                  ## Original position for bobbing
var is_collected: bool = false               ## Has banana been collected?
var bob_offset: float = 0.0                  ## Current bob offset

## ============================================================================
## SECTION 3: _ready() - INITIALIZATION
## ============================================================================
func _ready():
	## Store starting position
	start_position = position
	
	## Find sprite if not assigned
	if banana_sprite == null:
		for child in get_children():
			if child is Sprite2D:
				banana_sprite = child
				break
	
	## Connect the body_entered signal
	## This means when ANY body enters this Area2D, _on_body_entered() runs
	body_entered.connect(_on_body_entered)
	
	print("Banana ready at: ", position)

## ============================================================================
## SECTION 4: _process() - ANIMATION LOOP
## ============================================================================
## Runs every frame (typically 60 FPS) for visual effects.
## ============================================================================
func _process(delta):
	## Skip if already collected
	if is_collected:
		return
	
	## Rotate banana continuously
	rotation_degrees += rotation_speed * delta
	
	## Bob up and down using sine wave
	## sin() returns -1 to 1 based on input
	## Time.get_ticks_msec() gives milliseconds since game start
	bob_offset = sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_amount
	
	## Apply bob offset to Y position
	position.y = start_position.y + bob_offset

## ============================================================================
## SECTION 5: BODY ENTERED SIGNAL
## ============================================================================
## Called when any body enters the banana's Area2D.
## ============================================================================
func _on_body_entered(body: Node):
	## Don't process if already collected
	if is_collected:
		return
	
	## Check if it's the player
	## We check both by name AND by method existence
	if body.name.begins_with("Player") or body.has_method("collect_banana"):
		_collect(body)

## ============================================================================
## SECTION 6: COLLECT FUNCTION
## ============================================================================
## Handles banana collection logic.
## ============================================================================
func _collect(player):
	## Don't collect twice
	if is_collected:
		return
	
	## Mark as collected
	is_collected = true
	
	## Notify player
	if player.has_method("collect_banana"):
		player.collect_banana()
	
	print("Banana collected! Value: ", banana_value)
	
	## Play collection effects
	_play_collect_effects()
	
	## Disable processing and hide
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	
	## Wait 0.2 seconds then remove from scene
	await get_tree().create_timer(0.2).timeout
	queue_free()

## ============================================================================
## SECTION 7: COLLECT EFFECTS
## ============================================================================
## Plays sound and particle effects.
## ============================================================================
func _play_collect_effects():
	## Play sound
	if collect_sound:
		var sound_player = AudioStreamPlayer.new()
		sound_player.stream = collect_sound
		add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)
	
	## Play particles
	if collect_particles:
		collect_particles.emitting = true

## ============================================================================
## END OF BANANA SCRIPT
## ============================================================================
