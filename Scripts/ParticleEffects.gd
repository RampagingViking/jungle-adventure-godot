## ============================================================================
## 🌴 JUNGLE ADVENTURE - PARTICLE EFFECTS LIBRARY
## ============================================================================
## Reusable particle effects for polish (dust, hits, celebrations)
## ============================================================================

class_name ParticleEffects extends Node

## ============================================================================
## DUST CLOUD EFFECT
## ============================================================================
static func create_dust(parent: Node, position: Vector2, count: int = 8) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = count
	particles.lifetime = 0.4
	particles.explosiveness = 0.8
	particles.one_shot = true
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10
	material.direction = Vector3(0, -1, 0)
	material.spread = 60
	material.initial_velocity_min = 30
	material.initial_velocity_max = 60
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 3
	material.scale_max = 8
	material.color = Color(0.7, 0.6, 0.5, 0.8)
	
	particles.process_material = material
	particles.position = position
	particles.z_index = -1
	
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

## ============================================================================
## LANDING DUST EFFECT
## ============================================================================
static func create_landing_dust(parent: Node, position: Vector2) -> void:
	create_dust(parent, position, 12)

## ============================================================================
## HIT/SPARK EFFECT
## ============================================================================
static func create_spark(parent: Node, position: Vector2, color: Color = Color.YELLOW) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 6
	particles.lifetime = 0.15
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
	material.color = color
	
	particles.process_material = material
	particles.position = position
	particles.z_index = 10
	
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

## ============================================================================
## CELEBRATION SPARKLE
## ============================================================================
static func create_celebration(parent: Node, position: Vector2, color: Color = Color.GOLD) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 10
	particles.lifetime = 0.5
	particles.explosiveness = 0.5
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 20
	material.direction = Vector3(0, -1, 0)
	material.spread = 60
	material.initial_velocity_min = 40
	material.initial_velocity_max = 80
	material.gravity = Vector3(0, -100, 0)
	material.scale_min = 2
	material.scale_max = 6
	material.color = color
	
	particles.process_material = material
	particles.position = position
	particles.z_index = 100
	
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

## ============================================================================
## FOOTSTEP DUST
## ============================================================================
static func create_footstep_dust(parent: Node, position: Vector2) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 4
	particles.lifetime = 0.3
	particles.explosiveness = 0.3
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5
	material.direction = Vector3(0, -1, 0)
	material.spread = 45
	material.initial_velocity_min = 10
	material.initial_velocity_max = 20
	material.gravity = Vector3(0, 50, 0)
	material.scale_min = 2
	material.scale_max = 4
	material.color = Color(0.6, 0.5, 0.4, 0.5)
	
	particles.process_material = material
	particles.position = position
	particles.z_index = -2
	
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

## ============================================================================
## ROLL DUST CLOUD
## ============================================================================
static func create_roll_dust(parent: Node, position: Vector2) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 5
	particles.lifetime = 0.3
	particles.explosiveness = 0.2
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 8
	material.direction = Vector3(1, 0, 0)
	material.spread = 30
	material.initial_velocity_min = 20
	material.initial_velocity_max = 40
	material.gravity = Vector3(0, 0, 0)
	material.scale_min = 3
	material.scale_max = 6
	material.color = Color(0.7, 0.6, 0.5, 0.6)
	
	particles.process_material = material
	particles.position = position
	particles.z_index = -1
	
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

## ============================================================================
## ENEMY DEATH EXPLOSION
## ============================================================================
static func create_enemy_death(parent: Node, position: Vector2) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 16
	particles.lifetime = 0.4
	particles.explosiveness = 0.9
	particles.one_shot = true
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 15
	material.direction = Vector3(0, 0, 0)
	material.spread = 180
	material.initial_velocity_min = 40
	material.initial_velocity_max = 100
	material.gravity = Vector3(0, 150, 0)
	material.scale_min = 4
	material.scale_max = 10
	material.color = Color(0.3, 0.8, 0.3)
	
	particles.process_material = material
	particles.position = position
	particles.z_index = 5
	
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free())

## ============================================================================
## END OF PARTICLE EFFECTS
## ============================================================================
