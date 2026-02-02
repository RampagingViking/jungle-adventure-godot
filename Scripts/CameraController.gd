extends Camera2D

## Smooth camera that follows player with bounds
## Ported from Unity to Godot

@export_category("Target")
@export var target: Node2D
@export var offset: Vector2 = Vector2(0, 2)

@export_category("Follow Settings")
@export var smooth_speed: float = 5.0
@export var look_ahead_distance: float = 2.0
@export var look_ahead_speed: float = 2.0

@export_category("Bounds")
@export var use_bounds: bool = true
@export var min_bounds: Vector2 = Vector2(-10, -5)
@export var max_bounds: Vector2 = Vector2(100, 10)

## State variables
var target_position: Vector2
var current_look_ahead: float = 0.0

func _ready():
	if target == null:
		# Try to find player in scene
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			target = player
	
	target_position = global_position
	print("CameraController ready!")

func _process(delta):
	if target == null:
		return
	
	# Calculate target position
	var target_pos = target.global_position + offset
	
	# Look ahead based on player velocity
	if target.has_method("get_velocity") or "velocity" in target:
		var velocity_x = 0.0
		if "velocity" in target:
			velocity_x = target.velocity.x
		elif target.has_method("get_velocit"):
			velocity_x = target.get_velocity().x
		
		current_look_ahead = move_toward(current_look_ahead, sign(velocity_x) * look_ahead_distance, look_ahead_speed * delta)
		target_pos.x += current_look_ahead
	
	# Smooth follow
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	
	# Apply bounds
	if use_bounds:
		var clamped_position = global_position
		clamped_position.x = clamp(clamped_position.x, min_bounds.x, max_bounds.x)
		clamped_position.y = clamp(clamped_position.y, min_bounds.y, max_bounds.y)
		global_position = clamped_position

func set_bounds(min_pos: Vector2, max_pos: Vector2):
	min_bounds = min_pos
	max_bounds = max_pos

func transition_to_bounds(new_min: Vector2, new_max: Vector2, transition_delay: float = 0.5):
	await get_tree().create_timer(transition_delay).timeout
	_transition_routine(new_min, new_max)

func _transition_routine(new_min: Vector2, new_max: Vector2):
	var duration = 1.0
	var elapsed = 0.0
	var start_min = min_bounds
	var start_max = max_bounds
	
	while elapsed < duration:
		var t = elapsed / duration
		min_bounds = start_min.lerp(new_min, t)
		max_bounds = start_max.lerp(new_max, t)
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	
	min_bounds = new_min
	max_bounds = new_max
