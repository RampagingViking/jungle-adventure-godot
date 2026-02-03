## ============================================================================
## 🌴 JUNGLE ADVENTURE - BANANA COLLECTIBLE v2.0
## ============================================================================
## Enhanced with polish fixes and new features.
##
## v2.0 IMPROVEMENTS:
## - Glow effect when player is nearby
## - Sparkle particles
## - Score popup
## - Banana chains (DKC style)
## ============================================================================

extends Area2D

## ============================================================================
## SECTION 1: EXPORT VARIABLES
## ============================================================================

@export_category("Banana Settings")
@export var banana_value: int = 10
@export var rotation_speed: float = 90.0
@export var bob_speed: float = 2.0
@export var bob_amount: float = 10.0

@export_category("Polish")
@export var enable_glow: bool = true
@export var glow_color: Color = Color(1, 0.8, 0)
@export var enable_sparkles: bool = true
@export var score_popup: bool = true

@export_category("Chain Settings")
@export var is_chain: bool = false
@export var chain_direction: Vector2 = Vector2.DOWN
@export var chain_spacing: float = 40.0
@export var chain_count: int = 3

@export_category("References")
@export var banana_sprite: Sprite2D
@export var collect_sound: AudioStream
@export var collect_sounds: Array[AudioStream] = []
@export var collect_particles: GPUParticles2D

## ============================================================================
## SECTION 2: STATE VARIABLES
## ============================================================================

var start_position: Vector2
var is_collected: bool = false
var bob_offset: float = 0.0
var glow_intensity: float = 0.0
var player_nearby: bool = false
var animation_time: float = 0.0
var collected_anim_time: float = 0.0

## ============================================================================
## SECTION 3: _ready()
## ============================================================================
func _ready():
	start_position = position
	
	if banana_sprite == null:
		for child in get_children():
			if child is Sprite2D:
				banana_sprite = child
				break
	
	body_entered.connect(_on_body_entered)
	
	if is_chain:
		_create_chain()

## ============================================================================
## SECTION 4: _process()
## ============================================================================
func _process(delta):
	if is_collected:
		_collect_animation(delta)
		return
	
	animation_time += delta
	rotation_degrees += rotation_speed * delta
	bob_offset = sin(animation_time * bob_speed) * bob_amount
	position.y = start_position.y + bob_offset
	
	if enable_glow and banana_sprite:
		var player = _get_player()
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance < 100:
				player_nearby = true
				glow_intensity = lerp(glow_intensity, 1.0, delta * 5)
			else:
				player_nearby = false
				glow_intensity = lerp(glow_intensity, 0.0, delta * 5)
			
			var current_color = banana_sprite.modulate
			banana_sprite.modulate = current_color.lerp(
				Color(glow_color.r, glow_color.g, glow_color.b, 1),
				glow_intensity * 0.3
			)

## ============================================================================
## SECTION 5: COLLISION
## ============================================================================
func _on_body_entered(body: Node):
	if is_collected:
		return
	
	if body.name.begins_with("Player") or body.has_method("collect_banana"):
		_collect(body)

## ============================================================================
## SECTION 6: COLLECT
## ============================================================================
func _collect(player):
	if is_collected:
		return
	
	is_collected = true
	
	if player.has_method("collect_banana"):
		player.collect_banana()
	
	_play_random_collect_sound()
	
	if score_popup:
		_show_score_popup()
	
	_play_collect_effects()
	
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false

## ============================================================================
## SECTION 7: ANIMATION
## ============================================================================
func _collect_animation(delta: float):
	collected_anim_time += delta
	
	if banana_sprite:
		banana_sprite.scale = banana_sprite.scale.lerp(Vector2(0.3, 0.3), delta * 5)
		banana_sprite.modulate.a = max(0, 1 - collected_anim_time * 2)
	
	if collected_anim_time > 0.5:
		queue_free()

## ============================================================================
## SECTION 8: CHAIN
## ============================================================================
func _create_chain():
	if not is_chain or chain_count <= 1:
		return
	
	var parent = get_parent()
	
	for i in range(1, chain_count):
		var new_banana = duplicate()
		new_banana.position = position + (chain_direction * chain_spacing * i)
		new_banana.is_chain = false
		new_banana.name = name + "_" + str(i)
		parent.add_child(new_banana)

## ============================================================================
## SECTION 9: EFFECTS
## ============================================================================
func _play_random_collect_sound():
	var sounds = collect_sounds if collect_sounds.size() > 0 else [collect_sound]
	var valid_sounds = sounds.filter(func(s): return s != null)
	
	if valid_sounds.size() > 0:
		var sound_player = AudioStreamPlayer.new()
		sound_player.stream = valid_sounds[randi() % valid_sounds.size()]
		add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)

func _play_collect_effects():
	if collect_particles:
		collect_particles.emitting = true
	
	if enable_sparkles:
		_create_sparkles()

func _create_sparkles():
	var sparkles = GPUParticles2D.new()
	sparkles.amount = 8
	sparkles.lifetime = 0.5
	sparkles.explosiveness = 1.0
	sparkles.one_shot = true
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 15
	material.direction = Vector3(0, -1, 0)
	material.spread = 180
	material.initial_velocity_min = 50
	material.initial_velocity_max = 100
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 2
	material.scale_max = 5
	material.color = Color(1, 0.9, 0)
	
	sparkles.process_material = material
	
	add_child(sparkles)
	sparkles.emitting = true
	sparkles.finished.connect(sparkles.queue_free)

## ============================================================================
## SECTION 10: SCORE POPUP
## ============================================================================
func _show_score_popup():
	var label = Label.new()
	label.text = "+" + str(banana_value)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	
	get_parent().add_child(label)
	label.global_position = global_position
	label.z_index = 100
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", global_position.y - 50, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0, 0.5)
	tween.tween_callback(label.queue_free)

## ============================================================================
## SECTION 11: HELPERS
## ============================================================================
func _get_player() -> Node:
	var parent = get_parent()
	for child in parent.get_children():
		if child.name.begins_with("Player"):
			return child
	return null

## ============================================================================
## END OF BANANA v2.0
## ============================================================================
