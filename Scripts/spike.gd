extends Area2D
## Spike hazard — deals 1 damage on contact. Uses level health system.

@export var damage: int = 1
@export var cooldown: float = 0.6

var _can_hit := true

func _ready() -> void:
	add_to_group("spikes")
	monitoring = true
	collision_layer = 0
	collision_mask = 6
	body_entered.connect(_on_body)
	# also check overlapping each frame for teleport cases
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	for b in get_overlapping_bodies():
		if b.is_in_group("players"):
			_on_body(b)
			break

func _on_body(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	if not _can_hit:
		return
	_can_hit = false
	var lvl = get_tree().get_first_node_in_group("level")
	if lvl != null and lvl.has_method("take_damage"):
		lvl.take_damage(body, damage, global_position)
	elif lvl != null and lvl.has_method("respawn_both"):
		lvl.respawn_both()
	get_tree().create_timer(cooldown).timeout.connect(func(): _can_hit = true)
