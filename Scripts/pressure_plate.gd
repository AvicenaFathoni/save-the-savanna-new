extends Area2D
## Pressure plate — hold switch. While any player stands on it, emits
## link_id=true; when empty emits false. Same link_id as Doors/platforms,
## so one plate can drive many targets. Needs players in group "players".

@export var link_id: String = "door_a"

var _pressed := false

func _ready() -> void:
	add_to_group("plates")

func _physics_process(_delta: float) -> void:
	var now := _player_inside()
	if now == _pressed:
		return
	_pressed = now
	var spr := get_node_or_null("Sprite")
	if spr != null:
		spr.position.y = 2.0 if _pressed else 0.0
		spr.modulate = Color(0.6, 1, 0.6, 1) if _pressed else Color(1, 1, 1, 1)
	get_tree().call_group("doors", "set_door", link_id, _pressed)

func _player_inside() -> bool:
	for b in get_overlapping_bodies():
		if b is Node and b.is_in_group("players"):
			return true
	return false
