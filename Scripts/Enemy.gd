## ============================================================================
## 🌴 JUNGLE ADVENTURE - ENEMY BASE CLASS
## ============================================================================
## Base class for all enemies in the game.
## Handles patrolling behavior and stomp vulnerability.
##
## 🎓 KEY CONCEPTS YOU'LL LEARN:
## - Node2D: Base class for 2D game objects
## - _physics_process(): Game loop for movement
## - Patrolling: Moving back and forth between bounds
## - Signals: Connecting collision events
## - Inheritance: Creating specialized enemy types
## ============================================================================

extends Node2D

## ============================================================================
## SECTION 1: EXPORT VARIABLES
## ============================================================================

@export_category("Enemy Settings")
@export var move_speed: float = 2.0           ## How fast enemy walks (meters/second)
@export var move_range: float = 3.0           ## How far enemy walks from start (meters)
@export var damage: int = 1                   ## Damage dealt to player on contact
@export var health: int = 1                   ## Enemy hit points
@export var can_be_stomped: bool = true       ## Can player kill by jumping on enemy?
@export var stomp_bounce_force: float = 10.0  ## Bounce height when player stomps enemy

@export_category("References")
@export var sprite_renderer: Sprite2D         ## Visual representation
@export var hit_sounds: Array[AudioStream]    ## Sounds when enemy is hit
@export var death_sounds: Array[AudioStream]  ## Sounds when enemy dies

## ============================================================================
## SECTION 2: STATE VARIABLES
## ============================================================================

## Tracks starting position for patrolling
var start_position: Vector2
## Movement direction: 1 = right, -1 = left
var direction: float = 1.0
## Death state flag
var is_dead: bool = false
## Velocity for physics-based movement
var velocity: Vector2 = Vector2.ZERO

## ============================================================================
## SECTION 3: _ready() - INITIALIZATION
## ============================================================================
## Runs once when enemy enters the scene.
## ============================================================================
func _ready():
	## Store starting position for patrol bounds
	start_position = position
	
	## Find sprite renderer if not assigned
	if sprite_renderer == null:
		## Loop through children looking for Sprite2D
		for child in get_children():
			if child is Sprite2D:
				sprite_renderer = child
				break
	
	print("Enemy ready at position: ", position)

## ============================================================================
## SECTION 4: _physics_process() - MAIN GAME LOOP
## ============================================================================
## Runs every physics frame (60 FPS typically).
## ============================================================================
func _physics_process(delta):
	## Don't process if dead
	if is_dead:
		return
	
	## Run patrol behavior
	_patrol(delta)

## ============================================================================
## SECTION 5: PATROL BEHAVIOR
## ============================================================================
## Moves enemy back and forth within bounds.
## ============================================================================
func _patrol(delta: float):
	## Calculate new X position based on direction and speed
	var new_x = position.x + direction * move_speed * delta
	
	## Check if we've walked too far from start
	if abs(new_x - start_position.x) > move_range:
		## Reverse direction
		direction *= -1
	
	## Apply new position
	position.x = new_x
	
	## Flip sprite to face movement direction
	if sprite_renderer:
		## Flip horizontally if moving left (direction < 0)
		sprite_renderer.flip_h = direction < 0

## ============================================================================
## SECTION 6: TAKE DAMAGE FUNCTION
## ============================================================================
## Reduces enemy health and handles death.
## ============================================================================
func take_damage(damage_amount: int):
	## Don't take damage if already dead
	if is_dead:
		return
	
	## Reduce health
	health -= damage_amount
	
	## Visual feedback - flash white
	_flash_white()
	
	## Play hit sound
	_play_random_sound(hit_sounds)
	
	## Check if enemy should die
	if health <= 0:
		die()

## ============================================================================
## SECTION 7: DIE FUNCTION
## ============================================================================
## Handles enemy death.
## ============================================================================
func die():
	if is_dead:
		return                           ## Already dead, ignore
	
	is_dead = true                      ## Mark as dead
	
	## Run death animation
	_death_animation()
	
	## Play death sound
	_play_random_sound(death_sounds)
	
	print("Enemy died!")
	## In a real game:
	## - Add score
	## - Spawn particles
	## - Drop loot

## ============================================================================
## SECTION 8: FLASH WHITE EFFECT
## ============================================================================
## Makes sprite flash white briefly when hit.
## ============================================================================
func _flash_white():
	if sprite_renderer:
		## Store original color
		var original_modulate = sprite_renderer.modulate
		
		## Set to pure white
		sprite_renderer.modulate = Color.WHITE
		
		## Wait 0.1 seconds (using await instead of sleep!)
		await get_tree().create_timer(0.1).timeout
		
		## Restore original color
		if sprite_renderer:
			sprite_renderer.modulate = original_modulate

## ============================================================================
## SECTION 9: DEATH ANIMATION
## ============================================================================
## Shrinks and removes enemy when killed.
## ============================================================================
func _death_animation():
	## Animation parameters
	var duration = 0.3                   ## Animation duration in seconds
	var elapsed = 0.0                    ## Timer
	var start_scale = scale              ## Store original scale
	
	## Animate over time
	while elapsed < duration:
		## Calculate progress (0.0 to 1.0)
		var t = elapsed / duration
		
		## Scale from original to zero
		scale = start_scale.lerp(Vector2.ZERO, t)
		
		## Wait for next frame
		elapsed += get_process_delta_time()
		await get_tree().process_frame()
	
	## Remove enemy from scene
	queue_free()

## ============================================================================
## SECTION 10: PLAY SOUND FUNCTION
## ============================================================================
## Plays a random sound from the provided array.
## ============================================================================
func _play_random_sound(sounds: Array[AudioStream]):
	## Check if we have sounds
	if sounds.size() > 0:
		## Create a new AudioStreamPlayer
		var sound_player = AudioStreamPlayer.new()
		## Pick random sound
		sound_player.stream = sounds[randi() % sounds.size()]
		## Add as child so it can play
		add_child(sound_player)
		## Play the sound
		sound_player.play()
		## Auto-cleanup when finished
		sound_player.finished.connect(sound_player.queue_free)

## ============================================================================
## SECTION 11: COLLISION DETECTION
## ============================================================================
## Called when player collides with enemy.
## ============================================================================
func _on_body_entered(body: Node):
	if is_dead:
	 return
	
	## Check if colliding with player
	if body.name.begins_with("Player") or body.has_method("jump"):
		## Check if player is stomping (coming from above)
		if can_be_stomped:
			## Player must be above enemy to stomp
			## Compare Y positions: smaller Y = higher up in Godot
			if body.global_position.y < global_position.y - 10:
				## STOMP KILL!
				take_damage(health)  ## Kill in one hit regardless of health
				
				## Bounce player upward
				if body.has_method("jump"):
					body.velocity.y = stomp_bounce_force
			else:
				## Player touched enemy from side/below - player dies!
				body.die()

## ============================================================================
## END OF ENEMY SCRIPT
## ============================================================================
