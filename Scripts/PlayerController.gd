## ============================================================================
## 🌴 JUNGLE ADVENTURE - PLAYER CONTROLLER
## ============================================================================
## This script controls the player character in a DKC-inspired platformer.
## It handles: movement, jumping, rolling, ground pound, and barrel cannons.
##
## 🎓 KEY CONCEPTS YOU'LL LEARN:
## - CharacterBody2D: Godot's physics character controller
## - Velocity: How to move objects with physics
## - State variables: Tracking player state (grounded, rolling, etc.)
## - Export variables: Making variables editable in the Godot editor
## - Input handling: Reading keyboard/controller input
## - Signals: Communicating between objects
## ============================================================================

## ============================================================================
## EXTENDS: CharacterBody2D
## ============================================================================
## "extends" means PlayerController INHERITS from CharacterBody2D.
## Think of it like: CharacterBody2D is the "parent" and we add our own features.
##
## CharacterBody2D provides:
## - velocity: A Vector2 (x, y) for movement
## - move_and_slide(): Built-in physics movement function
## - is_on_floor(): Check if player is on the ground
## ============================================================================

extends CharacterBody2D

## ============================================================================
## SECTION 1: EXPORT VARIABLES (Settings you can edit in Godot!)
## ============================================================================
## These @export variables appear in the Godot Inspector panel.
## You can change values without touching the code!
##
## @export_category: Groups related settings together
## @export: Makes the variable editable in the Inspector
## ============================================================================

## Movement settings - how the player moves
@export_category("Movement")  ## Creates a category in the Inspector
@export var move_speed: float = 8.0          ## How fast player walks (meters/second)
@export var acceleration: float = 50.0       ## How fast player reaches full speed
@export var deceleration: float = 30.0       ## How fast player slows down

## Jump settings - how jumping works
@export_category("Jump")
@export var jump_force: float = 14.0         ## Initial upward velocity when jumping
@export var fall_multiplier: float = 2.5     ## Gravity multipler when falling (makes falls feel heavier)
@export var low_jump_multiplier: float = 2.0 ## Reduces upward velocity if jump button released early
@export var max_jumps: int = 2               ## Maximum jumps (2 = double jump)

## Roll settings - the rolling/dash ability
@export_category("Roll")
@export var roll_speed: float = 12.0         ## Speed during roll (faster than walking!)
@export var roll_duration: float = 0.4       ## How long the roll lasts (in seconds)
@export var roll_cooldown: float = 0.5       ## Wait time before rolling again
@export var after_roll_momentum: float = 0.5 ## Speed boost after roll ends

## Ground pound settings - dive attack from air
@export_category("Ground Pound")
@export var ground_pound_force: float = 25.0 ## Downward velocity when ground pounding
@export var ground_pound_impact_radius: float = 3.0  ## Range of impact effect
@export var ground_pound_cooldown: float = 0.3 ## Cooldown after ground pound

## Barrel cannon settings
@export_category("Barrel Cannon")
@export var barrel_launch_speed: float = 20.0  ## Speed when launched from barrel
@export var barrel_angle: float = 45.0         ## Default barrel angle (degrees)

## References to other nodes (drag-and-drop in editor)
@export_category("References")
@export var feet_position: Node2D              ## Point at player's feet (for ground check)
@export var body_sprite: Sprite2D              ## The player's visual sprite
@export var dust_particles: GPUParticles2D     ## Dust effect when running/jumping
@export var audio_player: AudioStreamPlayer    ## For playing sound effects

## ============================================================================
## SECTION 2: STATE VARIABLES (Internal tracking)
## ============================================================================
## These variables track the player's current state.
## They start with "is_" or "can_" for booleans (true/false values).
## ============================================================================

## Jump tracking
var current_jumps: int = 0                    ## How many jumps used (0, 1, or 2)
## Roll tracking
var is_rolling: bool = false                  ## Is player currently rolling?
var can_roll: bool = true                     ## Can player roll right now?
## Ground pound tracking
var can_ground_pound: bool = true             ## Can player ground pound?
## Barrel cannon tracking
var is_in_barrel_cannon: bool = false         ## Is player inside a barrel?
var barrel_direction: Vector2 = Vector2.ZERO  ## Direction barrel will launch player
## Timer variables (countdown values)
var roll_timer: float = 0.0                   ## Counts down during roll
var roll_cooldown_timer: float = 0.0          ## Counts down until roll is ready
var ground_pound_cooldown_timer: float = 0.0  ## Counts down until ground pound is ready
## Other tracking
var input_vector: Vector2 = Vector2.ZERO      ## Stores keyboard input as a vector
var is_grounded: bool = false                 ## Is player on the ground?
var is_dead: bool = false                     ## Is player dead?

## ============================================================================
## SECTION 3: AUDIO ARRAYS
## ============================================================================
## Arrays store MULTIPLE values in one variable.
## [] means "array of AudioStream"
## ============================================================================
var jump_sounds: Array[AudioStream] = []      ## Array to hold jump sound files
var roll_sounds: Array[AudioStream] = []      ## Array to hold roll sound files
var pound_sounds: Array[AudioStream] = []     ## Array to hold ground pound sounds

## ============================================================================
## SECTION 4: _ready() - INITIALIZATION FUNCTION
## ============================================================================
## _ready() runs ONCE when the node enters the scene.
## Use it to set up initial state and find child nodes.
## ============================================================================
func _ready():
	## Check if feet_position was assigned in the editor
	if feet_position == null:
		## If not assigned, create one programmatically
		feet_position = Node2D.new()           ## Create a new empty Node2D
		feet_position.name = "FeetPosition"    ## Give it a name
		add_child(feet_position)               ## Add it as a child of the player
		feet_position.position = Vector2(0, 30) ## Position at player's feet
		
	## Same for body sprite - find it if not assigned
	if body_sprite == null:
		## Loop through all child nodes looking for a Sprite2D
		for child in get_children():
			if child is Sprite2D:              ## "is" checks if child is Sprite2D type
				body_sprite = child            ## Found it! Store reference
				break                          ## Stop looking (break out of loop)
	
	## Print message to console (helps debug)
	print("PlayerController ready!")

## ============================================================================
## SECTION 5: _physics_process() - MAIN GAME LOOP (runs every frame)
## ============================================================================
## _physics_process() runs every physics frame (typically 60 times/second).
## Use it for movement, physics, and game logic.
##
## delta: Time since last frame (in seconds). Use it for frame-independent timing!
## ============================================================================
func _physics_process(delta):
	## Don't process if player is dead
	if is_dead:
		return                               ## Exit the function early
	
	## --- INPUT HANDLING ---
	## Get horizontal input from arrow keys or WASD
	## Input.get_axis returns -1 (left), 0 (none), or 1 (right)
	var horizontal_input = Input.get_axis("ui_left", "ui_right")
	
	## Check for button presses (just_pressed = true for ONE frame only)
	var jump_pressed = Input.is_action_just_pressed("ui_accept")   ## Space bar
	var roll_pressed = Input.is_action_just_pressed("ui_select")   ## X key
	var ground_pound_pressed = Input.is_action_just_pressed("ui_down")  ## Down arrow
	
	## Update all cooldown timers
	_update_cooldowns(delta)
	
	## --- SPECIAL MOVES ---
	## Ground pound: only when not grounded, not rolling, barrel available
	if ground_pound_pressed and can_ground_pound and not is_grounded and not is_rolling and not is_in_barrel_cannon:
		_ground_pound()                     ## Call the ground pound function
	
	## Roll: only when grounded, cooldown ready, not already rolling
	if roll_pressed and can_roll and is_grounded and not is_rolling and not is_in_barrel_cannon:
		_start_roll()                       ## Call the roll function
	
	## Jump: only if we have jumps remaining
	if jump_pressed and current_jumps < max_jumps and not is_rolling and not is_in_barrel_cannon:
		_jump()                             ## Call the jump function
	
	## --- MOVEMENT ---
	## Only apply movement if NOT inside a barrel cannon
	if not is_in_barrel_cannon:
		_move(horizontal_input, delta)      ## Call the move function
	
	## --- GRAVITY ---
	## Apply gravity with variable jump height
	_apply_gravity(delta)
	
	## --- ROLL TIMER ---
	## Count down roll timer and end roll when done
	if is_rolling:
		roll_timer -= delta                 ## Subtract delta from timer
		if roll_timer <= 0:                 ## If timer reaches zero
			_end_roll()                     ## Call end roll function
	
	## --- PHYSICS ---
	## Apply all accumulated velocity to move the character
	## move_and_slide() handles collisions automatically!
	move_and_slide()
	
	## --- STATE CHECK ---
	## Check if player is on the ground
	_check_grounded()
	
	## --- ANIMATION ---
	## Update the sprite animation based on state
	_update_animation()

## ============================================================================
## SECTION 6: MOVE FUNCTION
## ============================================================================
## Handles horizontal movement with acceleration and deceleration.
## ============================================================================
func _move(horizontal_input: float, delta: float):
	## If rolling, use fixed high speed in facing direction
	if is_rolling:
		## Determine roll direction based on sprite flip
		var roll_direction = -1 if body_sprite and body_sprite.flip_h else 1
		## Set velocity.x to roll speed in that direction
		velocity.x = roll_direction * roll_speed
	else:
		## Calculate target speed based on input
		var target_speed = horizontal_input * move_speed
		
		## If player is pressing a direction
		if abs(horizontal_input) > 0.01:
			## Determine acceleration rate
			## Accelerate if gaining speed, decelerate if reducing speed
			var accel_rate = acceleration if abs(target_speed) > abs(velocity.x) else deceleration
			
			## Smoothly move velocity toward target speed
			velocity.x = move_toward(velocity.x, target_speed, accel_rate * delta)
			
			## Flip sprite to face movement direction
			if body_sprite:
				body_sprite.flip_h = horizontal_input < 0  ## Flip if moving left
		else:
			## No input - decelerate to stop
			velocity.x = move_toward(velocity.x, 0, deceleration * delta)

## ============================================================================
## SECTION 7: JUMP FUNCTION
## ============================================================================
## Applies upward velocity for jumping.
## ============================================================================
func _jump():
	## Set vertical velocity to jump_force (negative = up in Godot!)
	velocity.y = jump_force
	## Increment jump counter
	current_jumps += 1
	## Create dust effect and play sound
	_create_dust()
	_play_random_sound(jump_sounds)

## ============================================================================
## SECTION 8: START ROLL FUNCTION
## ============================================================================
## Initiates the roll state and disables collision temporarily.
## ============================================================================
func _start_roll():
	is_rolling = true           ## Set rolling state to true
	can_roll = false            ## Prevent rolling again until cooldown
	roll_timer = roll_duration  ## Set roll timer
	roll_cooldown_timer = roll_cooldown  ## Start cooldown
	
	## Disable collision shape during roll (player is invincible!)
	if has_node("CollisionShape2D"):
		## set_deferred waits until physics frame to disable
		$CollisionShape2D.set_deferred("disabled", true)
	
	## Visual and audio feedback
	_create_dust()
	_play_random_sound(roll_sounds)

## ============================================================================
## SECTION 9: END ROLL FUNCTION
## ============================================================================
## Ends the roll state and applies momentum boost.
## ============================================================================
func _end_roll():
	is_rolling = false          ## Set rolling state to false
	
	## Re-enable collision
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", false)
	
	## Apply momentum boost after roll
	var roll_direction = -1 if body_sprite and body_sprite.flip_h else 1
	velocity.x = roll_direction * move_speed * after_roll_momentum

## ============================================================================
## SECTION 10: GROUND POUND FUNCTION
## ============================================================================
## Launches player downward rapidly.
## ============================================================================
func _ground_pound():
	can_ground_pound = false           ## Prevent spamming
	ground_pound_cooldown_timer = ground_pound_cooldown
	
	## Set high downward velocity
	velocity.y = ground_pound_force
	
	## Visual/audio feedback
	_create_dust()
	_play_random_sound(pound_sounds)

## ============================================================================
## SECTION 11: CHECK GROUNDED FUNCTION
## ============================================================================
## Checks if player is on the floor and resets jump counter.
## ============================================================================
func _check_grounded():
	## is_on_floor() is built into CharacterBody2D
	if is_on_floor():
		is_grounded = true               ## Player is on ground
		current_jumps = 0                ## Reset jump counter
		
		## Reset roll if cooldown is done
		if roll_cooldown_timer <= 0:
			can_roll = true
		
		## Reset ground pound if cooldown is done
		if ground_pound_cooldown_timer <= 0:
			can_ground_pound = true
	else:
		is_grounded = false              ## Player is in air

## ============================================================================
## SECTION 12: UPDATE COOLDOWNS FUNCTION
## ============================================================================
## Counts down all cooldown timers.
## ============================================================================
func _update_cooldowns(delta: float):
	## Subtract delta from each timer
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
	if ground_pound_cooldown_timer > 0:
		ground_pound_cooldown_timer -= delta

## ============================================================================
## SECTION 13: APPLY GRAVITY FUNCTION
## ============================================================================
## Applies gravity with variable jump height (hold space for higher jump).
## ============================================================================
func _apply_gravity(delta: float):
	## If moving upward (negative velocity)
	if velocity.y < 0:
		pass  ## Normal gravity (no change)
	## If falling (positive velocity)
	elif velocity.y > 0:
		## Apply extra gravity for heavier-feeling falls
		velocity.y += gravity * (fall_multiplier - 1) * delta
	
	## Variable jump height:
	## If moving up AND jump button NOT pressed, apply extra downward force
	## This cuts the jump short for a shorter hop
	if velocity.y < 0 and not Input.is_action_pressed("ui_accept"):
		velocity.y -= gravity * (low_jump_multiplier - 1) * delta

## ============================================================================
## SECTION 14: UPDATE ANIMATION FUNCTION
## ============================================================================
## Placeholder for animation system. Override or connect to AnimationPlayer.
## ============================================================================
func _update_animation():
	## TODO: Add animation state machine here
	## You could:
	## - Check is_rolling → play "roll" animation
	## - Check is_grounded → play "idle" or "run"
	## - Check velocity.y → play "jump_up" or "fall"
	pass  ## Do nothing for now

## ============================================================================
## SECTION 15: HELPER FUNCTIONS
## ============================================================================
## Utility functions used by other parts of the code.

## Creates dust particle effect
func _create_dust():
	if dust_particles:
		dust_particles.emitting = true

## Plays a random sound from the provided array
func _play_random_sound(sounds: Array[AudioStream]):
	## Check if we have an audio player and sounds available
	if audio_player and sounds.size() > 0:
		## Pick a random sound from the array
		var random_index = randi() % sounds.size()
		## Set and play the sound
		audio_player.stream = sounds[random_index]
		audio_player.play()

## Kills the player
func die():
	if is_dead:
		return                          ## Already dead, ignore
	
	is_dead = true                     ## Mark as dead
	velocity = Vector2.ZERO            ## Stop movement
	set_physics_process(false)        ## Disable physics
	
	print("Player died!")
	## In a real game, you'd:
	## - Play death animation
	## - Show game over screen
	## - Restart level

## Called when player collects a banana
func collect_banana():
	print("Banana collected!")
	## In a real game, you'd:
	## - Add score
	## - Play collection sound
	## - Update UI

## ============================================================================
## SECTION 16: PUBLIC ACCESSOR METHODS
## ============================================================================
## These methods allow OTHER scripts to read player state.
## ============================================================================

## Returns whether player is inside a barrel cannon
func get_is_in_barrel() -> bool:
	return is_in_barrel_cannon

## Returns whether player is on the ground
func is_grounded_state() -> bool:
	return is_grounded

## ============================================================================
## SECTION 17: BARREL CANNON INTEGRATION
## ============================================================================
## Functions for interacting with barrel cannons.

## Called when player enters a barrel cannon
func enter_barrel_cannon(direction: Vector2):
	is_in_barrel_cannon = true
	barrel_direction = direction.normalized()  ## Normalize to unit vector
	velocity = Vector2.ZERO                    ## Stop player movement
	set_physics_process(false)                ## Disable physics while in barrel

## Called when barrel fires the player
func fire_from_barrel():
	is_in_barrel_cannon = false
	set_physics_process(true)                 ## Re-enable physics
	velocity = barrel_direction * barrel_launch_speed  ## Launch!

## ============================================================================
## END OF PLAYER CONTROLLER
## ============================================================================
