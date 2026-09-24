extends CharacterBody2D
## Blue dino — hops instead of walks. Cooldown prevents spam.
## 3 HP, contact instakill, kick knockback, hurt anim.

@export var hop_speed: float = 70.0
@export var hop_force: float = -280.0
@export var gravity: float = 900.0
@export var hop_cooldown: float = 0.9
@export var patrol_time: float = 3.0
@export var knockback_force: float = 200.0
@export var hurt_invuln: float = 0.35

var health: int = 3
var dir: int = 1
var _invuln := false
var _dead := false
var _can_hop := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hop_timer: Timer = $HopTimer
@onready var patrol_timer: Timer = $PatrolTimer
@onready var hurtbox: Area2D = $HurtBox

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 1
	if hop_timer == null:
		var t := Timer.new()
		t.name = "HopTimer"
		t.wait_time = hop_cooldown
		t.one_shot = true
		add_child(t)
		hop_timer = t
	if patrol_timer == null:
		var pt := Timer.new()
		pt.name = "PatrolTimer"
		pt.wait_time = patrol_time
		pt.one_shot = false
		add_child(pt)
		patrol_timer = pt
	hop_timer.wait_time = hop_cooldown
	patrol_timer.wait_time = patrol_time
	hop_timer.timeout.connect(func(): _can_hop = true)
	patrol_timer.timeout.connect(_on_patrol_timeout)
	patrol_timer.start()
	_update_facing()
	sprite.play("walk")
	if hurtbox != null:
		hurtbox.monitoring = true
		hurtbox.collision_layer = 0
		hurtbox.collision_mask = 6
		hurtbox.body_entered.connect(_on_hurtbox_body)

func _physics_process(delta: float) -> void:
	if _dead:
		velocity.y += gravity * delta
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y += gravity * delta
		sprite.play("jump")
	else:
		velocity.y = 0
		if _can_hop and not _invuln:
			_do_hop()
		else:
			# small idle drift
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if abs(velocity.x) < 1.0:
				sprite.play("walk")
	move_and_slide()
	if is_on_wall() and is_on_floor():
		_flip_dir()
	_update_facing()

func _do_hop() -> void:
	_can_hop = false
	velocity.y = hop_force
	velocity.x = dir * hop_speed
	sprite.play("jump")
	hop_timer.start()

func _on_patrol_timeout() -> void:
	_flip_dir()

func _flip_dir() -> void:
	dir *= -1
	_update_facing()

func _update_facing() -> void:
	if sprite != null:
		sprite.flip_h = dir < 0

func _on_hurtbox_body(body: Node) -> void:
	if _dead or _invuln:
		return
	if body.is_in_group("players"):
		var lvl = get_tree().get_first_node_in_group("level")
		if lvl != null and lvl.has_method("take_damage"):
			lvl.take_damage(body, 1)
		elif lvl != null and lvl.has_method("respawn_both"):
			lvl.respawn_both()

func take_hit(from_pos: Vector2) -> bool:
	if _dead or _invuln:
		return false
	health -= 1
	_invuln = true
	var kb_dir = sign(global_position.x - from_pos.x)
	if kb_dir == 0:
		kb_dir = -dir
	velocity.x = kb_dir * knockback_force
	velocity.y = -120.0
	sprite.play("hurt")
	sprite.modulate = Color(1, 0.6, 0.6, 1)
	SFX.play_hit(self)
	Juice.spawn_hit(get_parent(), global_position + Vector2(0, -6))
	if health > 0:
		Juice.spawn_dust(get_parent(), global_position + Vector2(0, 8))
	await get_tree().create_timer(hurt_invuln).timeout
	if _dead:
		return true
	_invuln = false
	sprite.modulate = Color(1,1,1,1)
	if health <= 0:
		_die()
	else:
		sprite.play("walk")
	return true

func _die() -> void:
	_dead = true
	collision_layer = 0
	collision_mask = 0
	if hurtbox != null:
		hurtbox.monitoring = false
	sprite.play("hurt")
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tw.tween_property(self, "scale:y", 0.1, 0.4)
	await tw.finished
	queue_free()

const SFX := preload("res://Scripts/sfx.gd")
const Juice := preload("res://Scripts/juice_particles.gd")
