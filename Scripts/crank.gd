extends Area2D
## Crank switch. Reusable link pattern: set link_id in the inspector, and
## every Door with the same link_id toggles when a player uses the crank.
## Use: P1 presses F (p1_special), P2 presses Enter (p2_interact) while inside.

@export var link_id: String = "door_a"

const TEX_UP := preload("res://Assets/crank-up.png")
const TEX_DOWN := preload("res://Assets/crank-down.png")
const SFX := preload("res://Scripts/sfx.gd")

var _state := false
var _shake_tween: Tween

func _ready() -> void:
	add_to_group("cranks")

func _physics_process(_delta: float) -> void:
	var bodies = get_overlapping_bodies()
	var p1_inside := false
	var p2_inside := false
	for b in bodies:
		if b is Node and b.is_in_group("players"):
			if String(b.name) == "Player1":
				p1_inside = true
			elif String(b.name) == "Player2":
				p2_inside = true
	if not p1_inside and not p2_inside:
		return
	var triggered := false
	if p1_inside and Input.is_action_just_pressed("p1_special"):
		triggered = true
	if p2_inside and Input.is_action_just_pressed("p2_interact"):
		triggered = true
	if not triggered:
		return
	_state = not _state
	var spr := get_node_or_null("Sprite")
	if spr != null:
		spr.texture = TEX_DOWN if _state else TEX_UP
		_shake(spr)
	SFX.play_toggle(self, _state)
	get_tree().call_group("doors", "set_door", link_id, _state)

func _shake(spr: Node2D) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	spr.rotation = 0.18 if _state else -0.18
	_shake_tween = create_tween()
	_shake_tween.tween_property(spr, "rotation", 0.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _player_inside() -> bool:
	for b in get_overlapping_bodies():
		if b is Node and b.is_in_group("players"):
			return true
	return false
