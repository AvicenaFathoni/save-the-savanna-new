extends Area2D
## Level goal flag. Drop into any level; first player to touch it wins.

const Juice := preload("res://Scripts/juice_particles.gd")
const SFX := preload("res://Scripts/sfx.gd")

var _done := false

func _ready() -> void:
	add_to_group("goals")
	body_entered.connect(_on_body)

func _on_body(body: Node2D) -> void:
	if _done:
		return
	if not body.is_in_group("players"):
		return
	var lvl := get_tree().get_first_node_in_group("level")
	if lvl != null and lvl.has_method("can_finish") and not lvl.can_finish():
		# locked — need all gems
		var spr := get_node_or_null("Sprite")
		if spr != null:
			var tw := create_tween()
			tw.tween_property(spr, "position:x", spr.position.x + 4, 0.06)
			tw.tween_property(spr, "position:x", spr.position.x - 4, 0.06)
			tw.tween_property(spr, "position:x", spr.position.x, 0.06)
			spr.modulate = Color(1, 0.5, 0.5, 1)
			create_tween().tween_property(spr, "modulate", Color(1,1,1,1), 0.4)
		return
	_done = true
	Juice.spawn_confetti(get_parent(), global_position + Vector2(0, -12))
	SFX.play_goal(self)
	if lvl != null and lvl.has_method("on_goal"):
		lvl.on_goal()
