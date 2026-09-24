extends CharacterBody2D
## Meerkat (Player 2) — same template as player1.gd, retuned for a smaller body.
## Controls (defaults): p2_left / p2_right / p2_jump, p2_interact reserved for later.
## Piggyback: landing on the ostrich glues the meerkat to its back so the
## ostrich can walk and jump freely; move or jump to hop off.

@export var speed: float = 190.0
@export var acceleration: float = 1300.0
@export var friction: float = 1500.0
@export var jump_speed: float = -300.0
@export var gravity: float = 850.0
@export var down_gravity_factor: float = 2.2
@export var max_fall_speed: float = 550.0

@export var action_left: StringName = &"p2_left"
@export var action_right: StringName = &"p2_right"
@export var action_jump: StringName = &"p2_jump"

const Juice := preload("res://Scripts/juice_particles.gd")
const SFX := preload("res://Scripts/sfx.gd")

@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var coyote_timer: Timer = $CoyoteTimer

enum State {IDLE, WALK, JUMP, DOWN}
var current_state: State = State.IDLE
var _was_on_floor := false
var _squash_tween: Tween

func _ready() -> void:
	add_to_group("players")

var _riding: CharacterBody2D = null
var _ride_offset := Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Glued to the ostrich's back: follow it exactly until the
	# meerkat steers (move) or hops off (jump).
	if _riding != null:
		if not is_instance_valid(_riding):
			_riding = null
		elif Input.is_action_just_pressed(action_jump):
			_riding = null
			jump_buffer_timer.start()
		elif Input.get_axis(action_left, action_right) != 0.0:
			_riding = null
		else:
			global_position = _riding.global_position + _ride_offset
			velocity = _riding.velocity
			update_animation()
			return

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
	_try_mount()


## If we landed on another player, glue onto its back.
func _try_mount() -> void:
	if not is_on_floor() or _riding != null:
		return
	for i in get_slide_collision_count():
		var sc := get_slide_collision(i)
		if sc.get_normal().y < -0.5:
			var c := sc.get_collider()
			if c is CharacterBody2D and c != self:
				_riding = c
				# 1px air gap so the glued rider never overlaps the
				# carrier (which would block its move_and_slide).
				_ride_offset = global_position - c.global_position + Vector2(0, -1.0)
				break


func _on_landed() -> void:
	Juice.spawn_dust(get_parent(), global_position + Vector2(0, 8))
	SFX.play_land(self)
	_squash(1.25, 0.75)

func _on_jump() -> void:
	SFX.play_jump(self)
	_squash(0.75, 1.25)

func _squash(sx: float, sy: float) -> void:
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	animations.scale = Vector2(sx, sy)
	_squash_tween = create_tween()
	_squash_tween.tween_property(animations, "scale", Vector2(1, 1), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func handle_input(delta: float) -> void:
	if Input.is_action_just_pressed(action_jump):
		jump_buffer_timer.start()

	var direction := Input.get_axis(action_left, action_right)

	if direction == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)


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
