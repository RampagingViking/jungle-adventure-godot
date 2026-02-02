## ============================================================================
## 🌴 JUNGLE ADVENTURE - CAMERA CONTROLLER
## ============================================================================
## Smooth camera that follows the player with bounds checking.
## Includes look-ahead feature for dynamic feel.
##
## 🎓 KEY CONCEPTS YOU'LL LEARN:
## - Camera2D: Godot's 2D camera node
## - Lerp (Linear Interpolation): Smooth movement between values
## - Smoothing: Creating fluid camera movement
## - Bounds: Limiting camera movement to level boundaries
## - Groups: Finding nodes by tags
## ============================================================================

extends Camera2D

## ============================================================================
## SECTION 1: EXPORT VARIABLES
## ============================================================================

@export_category("Target")
@export var target: Node2D              ## Player to follow (drag-and-drop)
@export var offset: Vector2 = Vector2(0, 2)  ## Offset from player position

@export_category("Follow Settings")
@export var smooth_speed: float = 5.0   ## How fast camera catches up (higher = snappier)
@export var look_ahead_distance: float = 2.0  ## How far camera looks ahead
@export var look_ahead_speed: float = 2.0     ## How fast look-ahead responds

@export_category("Bounds")
@export var use_bounds: bool = true     ## Should camera respect bounds?
@export var min_bounds: Vector2 = Vector2(-10, -5)   ## Left/top limits
@export var max_bounds: Vector2 = Vector2(100, 10)   ## Right/bottom limits

## ============================================================================
## SECTION 2: STATE VARIABLES
## ============================================================================

var target_position: Vector2            ## Where the camera wants to be
var current_look_ahead: float = 0.0     ## Current look-ahead offset

## ============================================================================
## SECTION 3: _ready() - INITIALIZATION
## ============================================================================
func _ready():
	## Try to find player if not assigned
	if target == null:
		## Groups are like tags - player should be in "Player" group
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			target = player
	
	## Initialize target position
	target_position = global_position
	
	print("CameraController ready!")

## ============================================================================
## SECTION 4: _process() - MAIN LOOP
## ============================================================================
## Runs every frame for smooth camera movement.
## ============================================================================
func _process(delta):
	## Exit if no target to follow
	if target == null:
		return
	
	## --- CALCULATE TARGET POSITION ---
	## Base target is player position plus offset
	var target_pos = target.global_position + offset
	
	## --- LOOK-AHEAD FEATURE ---
	## Camera shifts slightly in the direction player is moving
	## This creates a more dynamic, cinematic feel
	if target.has_method("get_velocity") or "velocity" in target:
		## Get player's horizontal velocity
		var velocity_x = 0.0
		if "velocity" in target:
			velocity_x = target.velocity.x
		elif target.has_method("get_velocity"):
			velocity_x = target.get_velocity().x
		
		## Smoothly move look-ahead toward target
		## sign() returns -1 (left), 0, or 1 (right)
		current_look_ahead = move_toward(
			current_look_ahead, 
			sign(velocity_x) * look_ahead_distance, 
			look_ahead_speed * delta
		)
		
		## Apply look-ahead to target position
		target_pos.x += current_look_ahead
	
	## --- SMOOTH FOLLOW ---
	## Lerp creates smooth movement from current to target position
	## lerp(current, target, speed * delta)
	## This creates a "spring" effect where camera catches up gradually
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	
	## --- APPLY BOUNDS ---
	if use_bounds:
		## Clamp position to stay within bounds
		var clamped_position = global_position
		clamped_position.x = clamp(clamped_position.x, min_bounds.x, max_bounds.x)
		clamped_position.y = clamp(clamped_position.y, min_bounds.y, max_bounds.y)
		
		## Apply clamped position (keep original Z offset)
		global_position = Vector2(clamped_position.x, clamped_position.y)

## ============================================================================
## SECTION 5: SET BOUNDS FUNCTION
## ============================================================================
## Sets camera bounds at runtime (e.g., when entering new room).
## ============================================================================
func set_bounds(min_pos: Vector2, max_pos: Vector2):
	min_bounds = min_pos
	max_bounds = max_pos

## ============================================================================
## SECTION 6: TRANSITION TO NEW BOUNDS
## ============================================================================
## Smoothly transitions camera to new bounds (for room transitions).
## ============================================================================
func transition_to_bounds(new_min: Vector2, new_max: Vector2, transition_delay: float = 0.5):
	## Wait before starting transition
	await get_tree().create_timer(transition_delay).timeout
	
	## Run the actual transition
	_transition_routine(new_min, new_max)

## ============================================================================
## SECTION 7: TRANSITION ANIMATION
## ============================================================================
## Smoothly animates bounds from current to new values.
## ============================================================================
func _transition_routine(new_min: Vector2, new_max: Vector2):
	var duration = 1.0                   ## Transition duration
	var elapsed = 0.0                    ## Timer
	var start_min = min_bounds           ## Store starting bounds
	var start_max = max_bounds
	
	## Animate bounds over time
	while elapsed < duration:
		## Calculate progress (0.0 to 1.0)
		var t = elapsed / duration
		
		## Interpolate bounds
		min_bounds = start_min.lerp(new_min, t)
		max_bounds = start_max.lerp(new_max, t)
		
		## Wait for next frame
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	
	## Ensure final values are exact
	min_bounds = new_min
	max_bounds = new_max

## ============================================================================
## END OF CAMERA CONTROLLER SCRIPT
## ============================================================================

## ============================================================================
## 📚 MATH EXPLANATION
## ============================================================================
## 
## LERP (Linear Interpolation):
## lerp(a, b, t) = a + (b - a) * t
## 
## Example: lerp(0, 100, 0.5) = 50
## Example: lerp(0, 100, 0.1) = 10
## 
## This is used for:
## - Smooth camera following
## - Animation transitions
## - Value interpolation
## 
## SIGN:
## sign(5) = 1
## sign(-5) = -1
## sign(0) = 0
## 
## This is used for:
## - Determining direction
## - Flipping sprites
## - Calculating look-ahead
## 
## CLAMP:
## clamp(value, min, max)
## 
## Example: clamp(150, 0, 100) = 100
## Example: clamp(-50, 0, 100) = 0
## 
## This is used for:
## - Keeping camera in bounds
## - Limiting values
## 
## ============================================================================
