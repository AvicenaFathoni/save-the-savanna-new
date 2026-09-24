extends Area2D
## Checkpoint flag. Drop into any level with feet on the ground.
## First player to touch it sets the level spawn and turns the flag green.

const SFX := preload("res://Scripts/sfx.gd")

@export var checkpoint_name: String = "checkpoint"

var activated := false

func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body)
	var spr := get_node_or_null("Sprite")
	if spr != null:
		spr.modulate = Color(0.55, 0.55, 0.55, 1)
		spr.speed_scale = 0.5

func _on_body(body: Node2D) -> void:
	if activated:
		return
	if not body.is_in_group("players"):
		return
	activated = true
	var lvl := get_tree().get_first_node_in_group("level")
	if lvl != null and lvl.has_method("set_spawn"):
		lvl.set_spawn(global_position)
	var spr := get_node_or_null("Sprite")
	if spr != null:
		spr.modulate = Color(1, 1, 1, 1)
		spr.speed_scale = 1.0
		var tw := create_tween()
		tw.tween_property(spr, "scale", Vector2(1.25, 1.25), 0.12)
		tw.tween_property(spr, "scale", Vector2(1, 1), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	SFX.play_checkpoint(self)
