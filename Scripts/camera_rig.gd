extends Camera2D
## Co-op camera: centered between all players, keeps both on screen.
## Place on a Camera2D at level root. Auto-limits from Ground TileMap.
## "Can't abandon each other" = players clamped to viewport edge.

@export var smooth_speed: float = 6.0
@export var margin: float = 24.0

var _limit_computed := false

func _ready() -> void:
	enabled = true
	make_current()
	limit_smoothed = true
	position_smoothing_enabled = true
	position_smoothing_speed = smooth_speed
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	_compute_limits()

func _collect_layers(root: Node, out: Array) -> void:
	for c in root.get_children():
		if c is TileMapLayer and c.tile_set != null:
			out.append(c)
		_collect_layers(c, out)

func _compute_limits() -> void:
	var p = get_parent()
	if p == null:
		return
	# collect ALL TileMapLayers in level (Ground or TileMap/*)
	var layers: Array = []
	_collect_layers(p, layers)
	if layers.is_empty():
		limit_left = -240
		limit_right = 1920
		limit_top = -200
		limit_bottom = 400
		_limit_computed = true
		return
	var min_x: int = 1000000
	var max_x: int = -1000000
	var min_y: int = 1000000
	var max_y: int = -1000000
	var have := false
	for ground in layers:
		var cells = ground.get_used_cells()
		if cells.is_empty():
			continue
		have = true
		for c in cells:
			min_x = mini(min_x, c.x)
			max_x = maxi(max_x, c.x)
			min_y = mini(min_y, c.y)
			max_y = maxi(max_y, c.y)
	if not have:
		return
	var tile = (layers[0] as TileMapLayer).tile_set.tile_size
	limit_left = min_x * tile.x - int(margin)
	limit_right = (max_x + 1) * tile.x + int(margin)
	limit_top = min_y * tile.y - 80
	limit_bottom = (max_y + 1) * tile.y + 40
	_limit_computed = true
	# sanity: if union is tiny (< viewport), expand to at least viewport around spawn
	if limit_right - limit_left < 480:
		var mid = (limit_left + limit_right) * 0.5
		limit_left = int(mid - 240)
		limit_right = int(mid + 240)

func _process(delta: float) -> void:
	if not _limit_computed and limit_left < -1000000:
		_compute_limits()
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var avg = Vector2.ZERO
	var cnt = 0
	for pl in players:
		if pl is Node2D:
			avg += pl.global_position
			cnt += 1
	if cnt == 0:
		return
	avg /= cnt
	avg.y -= 28.0 # look slightly up
	var hw = 240.0
	var hh = 135.0
	# clamp midpoint so viewport never shows outside limits
	avg.x = clamp(avg.x, float(limit_left + hw), float(limit_right - hw))
	avg.y = clamp(avg.y, float(limit_top + hh), float(limit_bottom - hh))
	global_position = global_position.lerp(avg, 1.0 - exp(-smooth_speed * delta))
	# prevent abandonment: soft clamp — only nudge if outside, don't teleport to center
	# wall at viewport edge, push gently
	for pl in players:
		if pl is CharacterBody2D:
			var half_w = 18.0
			var min_x = global_position.x - hw + margin + half_w
			var max_x = global_position.x + hw - margin - half_w
			if pl.global_position.x < min_x:
				pl.global_position.x = move_toward(pl.global_position.x, min_x, 500.0 * delta)
				if pl.velocity.x < 0:
					pl.velocity.x = max(pl.velocity.x, 0)
			elif pl.global_position.x > max_x:
				pl.global_position.x = move_toward(pl.global_position.x, max_x, 500.0 * delta)
				if pl.velocity.x > 0:
					pl.velocity.x = min(pl.velocity.x, 0)
