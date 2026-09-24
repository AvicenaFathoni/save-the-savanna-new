extends CharacterBody2D

@export var speed: float = 160.0
@export var acceleration: float = 1000.0
@export var friction: float = 1200.0
@export var jump_speed: float = -320.0
@export var gravity: float = 800.0
@export var down_gravity_factor: float = 2.0
@export var max_fall_speed: float = 500.0

@export var action_left: StringName = &"p1_left"
@export var action_right: StringName = &"p1_right"
@export var action_jump: StringName = &"p1_jump"

const Juice := preload("res://Scripts/juice_particles.gd")
const SFX := preload("res://Scripts/sfx.gd")

@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var coyote_timer: Timer = $CoyoteTimer

enum State {IDLE, WALK, JUMP, DOWN}
var current_state: State = State.IDLE
var _was_on_floor := false
var _squash_tween: Tween
var _kick_cooldown := false
@onready var _kick_box: Area2D = $KickBox

func _ready() -> void:
	add_to_group("players")
	_kick_box.body_entered.connect(_on_kick_hit)
	_kick_box.monitoring = false

func _on_kick_hit(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	if body.has_method("take_hit"):
		var ok = await body.take_hit(global_position)
		if ok:
			Engine.time_scale = 0.85
			await get_tree().create_timer(0.07, true, false, true).timeout
			Engine.time_scale = 1.0

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("p1_special") and not _kick_cooldown:
		_kick()
	handle_input(delta)
	update_movement(delta)
	update_states()
	update_animation()
	var was_floor := _was_on_floor
	move_and_slide()
	var landed := not was_floor and is_on_floor() and current_state != State.JUMP
	if landed:
		_on_landed()
	_was_on_floor = is_on_floor()


func handle_input(delta: float) -> void:
	if Input.is_action_just_pressed(action_jump):
		jump_buffer_timer.start()

	var direction := Input.get_axis(action_left, action_right)

	if direction == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)


func _on_landed() -> void:
	Juice.spawn_dust(get_parent(), global_position + Vector2(0, 12))
	SFX.play_land(self)
	_squash(1.25, 0.75)

func _on_jump() -> void:
	SFX.play_jump(self)
	_squash(0.75, 1.25)

func _kick() -> void:
	_kick_cooldown = true
	var facing = -1 if animations.flip_h else 1
	var col = _kick_box.get_child(0) as CollisionShape2D
	if col != null:
		col.position.x = 32 * facing
		col.position.y = 7
	_kick_box.monitoring = true
	_squash(1.15, 0.85)
	SFX.play_kick(self)
	Juice.spawn_kick(get_parent(), global_position + Vector2(32 * facing, 7), facing)
	await get_tree().create_timer(0.18).timeout
	_kick_box.monitoring = false
	await get_tree().create_timer(0.22).timeout
	_kick_cooldown = false

func _squash(sx: float, sy: float) -> void:
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	animations.scale = Vector2(sx, sy)
	_squash_tween = create_tween()
	_squash_tween.tween_property(animations, "scale", Vector2(1, 1), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func update_movement(delta: float) -> void:
	if (is_on_floor() || coyote_timer.time_left > 0.0) && jump_buffer_timer.time_left > 0.0:
		velocity.y = jump_speed
		current_state = State.JUMP
		jump_buffer_timer.stop()
		coyote_timer.stop()
		_on_jump()

	# Rising uses normal gravity, falling uses increased gravity for snappy feel.
	if current_state == State.JUMP and velocity.y < 0.0:
		velocity.y += gravity * delta
	else:
		velocity.y += gravity * down_gravity_factor * delta

	velocity.y = minf(velocity.y, max_fall_speed)


func update_states() -> void:
	match current_state:
		State.IDLE:
			if not is_on_floor():
				current_state = State.DOWN
				coyote_timer.start()
			elif velocity.x != 0.0:
				current_state = State.WALK

		State.WALK:
			if not is_on_floor():
				current_state = State.DOWN
				coyote_timer.start()
			elif velocity.x == 0.0:
				current_state = State.IDLE

		State.JUMP when velocity.y >= 0.0:
			current_state = State.DOWN

		State.DOWN when is_on_floor():
			if velocity.x == 0.0:
				current_state = State.IDLE
			else:
				current_state = State.WALK


func update_animation() -> void:
	# flip_h keeps the symmetric hitbox centered; never scale/flip the collision.
	if velocity.x != 0.0:
		animations.flip_h = velocity.x < 0.0

	match current_state:
		State.IDLE: animations.play("idle")
		State.WALK: animations.play("walk")
		State.JUMP: animations.play("jump_up")
		State.DOWN: animations.play("jump_down")
