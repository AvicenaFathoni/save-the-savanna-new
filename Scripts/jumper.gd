extends Area2D
## Jump pad — always on. Gives strong upward boost. Directional.
## Place with arrow up. Uses distinct boost for lighter meerkat.

@export var boost_ostrich: float = 520.0
@export var boost_meerkat: float = 600.0

func _ready() -> void:
	body_entered.connect(_on_body)
	collision_layer = 0
	collision_mask = 6
	# subtle idle bob
	var tw := create_tween().set_loops()
	tw.tween_property(self, "position:y", position.y - 2.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", position.y, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_body(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	if not body.has_method("get") and not body is CharacterBody2D:
		return
	var is_meerkat := String(body.name).contains("Player2") or String(body.name) == "Player2"
	var boost := boost_meerkat if is_meerkat else boost_ostrich
	# only boost if moving down or on floor (prevent infinite hover)
	if body is CharacterBody2D:
		body.velocity.y = -boost
		if body.has_method("_squash"):
			body._squash(1.2, 0.8)
		# brief squash on pad itself
		var spr := get_node_or_null("Sprite")
		if spr != null:
			var tw := create_tween()
			tw.tween_property(spr, "scale", Vector2(1.2, 0.8), 0.08)
			tw.tween_property(spr, "scale", Vector2(1, 1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
