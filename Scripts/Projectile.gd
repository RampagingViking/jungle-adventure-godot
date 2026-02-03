## ============================================================================
## 🌴 JUNGLE ADVENTURE - ENEMY PROJECTILE
## ============================================================================
## Projectile fired by ranged enemies (acorns, rocks, etc.)
## ============================================================================

extends Area2D

@export_category("Projectile Settings")
@export var speed: float = 200.0
@export var damage: int = 1
@export var lifetime: float = 3.0
@export var gravity: float = 100.0

@export_category("Polish")
@export var enable_trail: bool = true
@export var trail_color: Color = Color(0.5, 0.3, 0)
@export var impact_particles: bool = true

@export_category("References")
@export var sprite: Sprite2D
@export var trail_particles: GPUParticles2D

var velocity: Vector2 = Vector2.ZERO
var lifetime_timer: float = 0.0
var is_active: bool = true

func _ready():
	if sprite == null:
		for child in get_children():
			if child is Sprite2D:
				sprite = child
				break
	
	body_entered.connect(_on_body_entered)
	
	if enable_trail:
		_create_trail()

func _physics_process(delta):
	if not is_active:
		return
	
	lifetime_timer += delta
	
	if lifetime_timer >= lifetime:
		_expire()
		return
	
	velocity.y += gravity * delta
	global_position += velocity * delta
	
	if velocity.length() > 10:
		rotation = velocity.angle()

func _on_body_entered(body: Node):
	if not is_active:
		return
	
	if body.name.begins_with("Player") or body.has_method("die"):
		_impact(body)
	elif body is StaticBody2D or body is TileMap:
		_impact(null)

func _impact(body: Node):
	is_active = false
	
	if body and body.has_method("die"):
		body.die()
	
	_create_impact_effects()
	
	set_deferred("monitoring", false)
	visible = false
	
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _create_trail():
	var trail = GPUParticles2D.new()
	trail.amount = 10
	trail.lifetime = 0.3
	trail.explosiveness = 0
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5
	material.direction = Vector3(0, 0, 0)
	material.spread = 180
	material.initial_velocity_min = 10
	material.initial_velocity_max = 20
	material.gravity = Vector3(0, 0, 0)
	material.scale_min = 3
	material.scale_max = 6
	material.color = trail_color
	
	trail.process_material = material
	trail.z_index = -1
	
	add_child(trail)

func _create_impact_effects():
	if not impact_particles:
		return
	
	var particles = GPUParticles2D.new()
	particles.amount = 6
	particles.lifetime = 0.2
	particles.explosiveness = 1.0
	particles.one_shot = true
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5
	material.direction = Vector3(0, 0, 0)
	material.spread = 180
	material.initial_velocity_min = 50
	material.initial_velocity_max = 100
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 2
	material.scale_max = 5
	material.color = trail_color
	
	particles.process_material = material
	
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

func _expire():
	_create_impact_effects()
	queue_free()

## ============================================================================
## END OF PROJECTILE
## ============================================================================
