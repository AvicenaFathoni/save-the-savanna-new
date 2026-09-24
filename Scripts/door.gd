extends StaticBody2D
## Door slab. Reusable link pattern: set link_id in the inspector; any Crank
## with the same link_id toggles it. Place multiple crank/door pairs per
## level and link them purely by matching link_id strings.

@export var link_id: String = "door_a"
@export var start_open := false

var open := false
var _tween: Tween

func _ready() -> void:
	add_to_group("doors")
	open = not start_open
	set_door(link_id, start_open)

func set_door(id: String, state: bool) -> void:
	if id != link_id or state == open:
		return
	open = state
	var col := get_node_or_null("CollisionShape2D")
	if col != null:
		col.set_deferred("disabled", open)
	var vis := get_node_or_null("Visual")
	if vis != null:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		# Stay in place; fade out when open, fade back in when closed.
		_tween = create_tween()
		_tween.tween_property(vis, "modulate:a", 0.0 if open else 1.0, 0.35)
