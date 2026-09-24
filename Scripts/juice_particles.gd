extends RefCounted
# Juice helper: one-shot dust/confetti that frees itself.
# Create via Juice.spawn_dust(parent, pos) etc. - parent is any Node.

static func _white_tex() -> Texture2D:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)

static func spawn_dust(at: Node, pos: Vector2) -> void:
	var p := GPUParticles2D.new()
	p.texture = _white_tex()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.lifetime = 0.35
	p.amount = 10
	p.explosiveness = 0.85
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 55.0
	mat.gravity = Vector3(0, 98, 0)
	mat.scale_min = 1.0
	mat.scale_max = 2.5
	mat.color = Color(0.85, 0.78, 0.65, 0.9)
	p.process_material = mat
	at.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

static func spawn_confetti(at: Node, pos: Vector2) -> void:
	var p := GPUParticles2D.new()
	p.texture = _white_tex()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.lifetime = 1.1
	p.amount = 40
	p.explosiveness = 0.15
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 70.0
	mat.initial_velocity_min = 60.0
	mat.initial_velocity_max = 140.0
	mat.gravity = Vector3(0, 90, 0)
	mat.scale_min = 2.0
	mat.scale_max = 4.5
	mat.color = Color(1, 0.85, 0.2, 1)
	p.process_material = mat
	at.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

static func spawn_kick(at: Node, pos: Vector2, facing: int) -> void:
	var p := GPUParticles2D.new()
	p.texture = _white_tex()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.lifetime = 0.22
	p.amount = 8
	p.explosiveness = 0.9
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(facing, -0.3, 0)
	mat.spread = 28.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3(0, 180, 0)
	mat.scale_min = 1.2
	mat.scale_max = 2.2
	mat.color = Color(0.95, 0.92, 0.85, 0.9)
	p.process_material = mat
	at.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

static func spawn_hit(at: Node, pos: Vector2) -> void:
	var p := GPUParticles2D.new()
	p.texture = _white_tex()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.lifetime = 0.28
	p.amount = 14
	p.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -0.6, 0)
	mat.spread = 85.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 110.0
	mat.gravity = Vector3(0, 260, 0)
	mat.scale_min = 1.6
	mat.scale_max = 3.0
	mat.color = Color(1, 0.35, 0.15, 1)
	p.process_material = mat
	at.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
