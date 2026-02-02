## ============================================================================
## 🌴 JUNGLE ADVENTURE - BARREL CANNON
## ============================================================================
## Interactive barrel cannon that aims and launches the player in an arc.
## Inspired by Donkey Kong Country's barrel mechanics.
##
## 🎓 KEY CONCEPTS YOU'LL LEARN:
## - Area2D: Detection zone for player
## - State management: Different states (aiming, firing, cooldown)
## - Vector math: Calculating launch direction from angle
## - Input handling: Directional input for aiming
## - Signals: Connecting body enter/exit events
## ============================================================================

extends Area2D

## ============================================================================
## SECTION 1: EXPORT VARIABLES
## ============================================================================

@export_category("Barrel Settings")
@export var launch_speed: float = 25.0       ## Speed when launching player
@export var arc_angle: float = 45.0          ## Default aim angle (degrees)
@export var aim_speed: float = 3.0           ## How fast barrel aims
@export var fire_cooldown: float = 0.5       ## Cooldown between launches

@export_category("References")
@export var aim_indicator: Node2D            ## Visual arrow showing aim direction
@export var barrel_sprite: Sprite2D          ## Barrel visual
@export var aim_sound: AudioStream           ## Sound when aiming
@export var fire_sound: AudioStream          ## Sound when firing
@export var steam_particles: GPUParticles2D  ## Steam effect when firing

## ============================================================================
## SECTION 2: STATE VARIABLES
## ============================================================================

var current_aim_angle: float = 45.0          ## Current aim angle in degrees
var is_player_in_range: bool = false         ## Is player touching barrel?
var player: Node = null                      ## Reference to player node
var fire_cooldown_timer: float = 0.0         ## Cooldown countdown

## ============================================================================
## SECTION 3: _ready() - INITIALIZATION
## ============================================================================
func _ready():
	## Set initial angle
	current_aim_angle = arc_angle
	
	## Update visual indicator
	_update_aim_indicator()
	
	## Connect body signals
	## body_entered: Called when something enters the Area2D
	## body_exited: Called when something leaves the Area2D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("Barrel Cannon ready! Angle: ", current_aim_angle)

## ============================================================================
## SECTION 4: _process() - MAIN LOOP
## ============================================================================
func _process(delta):
	## Update cooldown timer
	if fire_cooldown_timer > 0:
		fire_cooldown_timer -= delta
	
	## Handle aiming if player is in range
	if is_player_in_range and player != null:
		_handle_aiming(delta)

## ============================================================================
## SECTION 5: AIMING LOGIC
## ============================================================================
func _handle_aiming(delta: float):
	## Get vertical input (up/down keys)
	## Returns -1 (up), 0 (none), or 1 (down)
	var vertical_input = Input.get_axis("ui_up", "ui_down")
	
	## If player is pressing up or down
	if abs(vertical_input) > 0.1:
		## Adjust angle based on input
		## Clamp ensures angle stays between 0 and 90 degrees
		current_aim_angle = clamp(current_aim_angle + vertical_input * aim_speed * delta * 50, 0, 90)
		
		## Update visual indicator
		_update_aim_indicator()
		
		## Play aim sound
		if aim_sound:
			_play_sound(aim_sound)
	
	## Check for fire button
	if Input.is_action_just_pressed("ui_select") and fire_cooldown_timer <= 0:
		_fire()

## ============================================================================
## SECTION 6: UPDATE AIM INDICATOR
## ============================================================================
## Rotates the visual aim indicator to match current angle.
## ============================================================================
func _update_aim_indicator():
	if aim_indicator:
		## Set rotation in degrees
		aim_indicator.rotation_degrees = current_aim_angle
	
	## Could also rotate barrel sprite here if desired

## ============================================================================
## SECTION 7: FIRE FUNCTION
## ============================================================================
## Launches the player from the barrel.
## ============================================================================
func _fire():
	## Calculate launch direction from angle
	## deg_to_rad converts degrees to radians (Godot uses radians for rotation)
	var rad_angle = deg_to_rad(current_aim_angle)
	
	## Calculate direction vector:
	## cos(angle) = X component
	## sin(angle) = Y component
	var launch_direction = Vector2(cos(rad_angle), sin(rad_angle))
	
	## Tell player to enter barrel
	player.enter_barrel_cannon(launch_direction)
	
	## Play fire effects
	_play_sound(fire_sound)
	
	if steam_particles:
		steam_particles.emitting = true
	
	## Reset aim to default
	current_aim_angle = arc_angle
	_update_aim_indicator()
	
	## Set cooldown
	fire_cooldown_timer = fire_cooldown
	
	## Wait 0.1 seconds then actually launch
	## This creates a small delay for visual effect
	await get_tree().create_timer(0.1).timeout
	_launch_player()

## ============================================================================
## SECTION 8: LAUNCH PLAYER
## ============================================================================
## Actually fires the player from the barrel.
## ============================================================================
func _launch_player():
	## Check if player still exists and has fire method
	if player and player.has_method("fire_from_barrel"):
		player.fire_from_barrel()
	
	## Clear player reference
	player = null

## ============================================================================
## SECTION 9: BODY SIGNALS
## ============================================================================
## Called when player enters/exits barrel area.
## ============================================================================
func _on_body_entered(body: Node):
	## Check if it's the player
	if body.name.begins_with("Player") or body.has_method("enter_barrel_cannon"):
		is_player_in_range = true
		player = body
		print("Player entered barrel range")

func _on_body_exited(body: Node):
	## Clear player reference if they exit
	if body == player:
		is_player_in_range = false
		player = null

## ============================================================================
## SECTION 10: PLAY SOUND HELPER
## ============================================================================
func _play_sound(sound: AudioStream):
	if sound:
		var sound_player = AudioStreamPlayer.new()
		sound_player.stream = sound
		add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)

## ============================================================================
## SECTION 11: HELPER FUNCTIONS
## ============================================================================

## Returns whether player is currently in barrel
func get_is_in_barrel() -> bool:
	return player != null

## ============================================================================
## END OF BARREL CANNON SCRIPT
## ============================================================================
