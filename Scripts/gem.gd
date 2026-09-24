extends Area2D
## Gem collectible — spritesheet gem.png (5×15x13). Place in level, any player can collect.
## Reports to level.gd via group "level" -> gem_collected(), free on touch.

func _ready() -> void:
	add_to_group("gems")
	body_entered.connect(_on_body)
	monitoring = true
	collision_layer = 0
	collision_mask = 6
	# subtle bob
	var tw := create_tween().set_loops()
	tw.tween_property(self, "position:y", position.y - 3.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", position.y, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_body(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	var lvl = get_tree().get_first_node_in_group("level")
	if lvl != null and lvl.has_method("gem_collected"):
		lvl.gem_collected(self)
	# small pop
	var spr := get_node_or_null("Sprite")
	if spr != null:
		var tw := create_tween()
		tw.tween_property(spr, "scale", Vector2(1.4, 1.4), 0.08)
		tw.tween_property(spr, "scale", Vector2(0, 0), 0.18)
		await tw.finished
	queue_free()
