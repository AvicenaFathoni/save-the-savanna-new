extends Node2D
## Level root logic: spawn management, fall respawn, win banner.
## Attach to the level's root node. Checkpoints/goals/cranks talk to it
## through group "level", so prefabs never need per-level wiring.

const Juice := preload("res://Scripts/juice_particles.gd")
const SFX := preload("res://Scripts/sfx.gd")

var spawn_point := Vector2(241, 120)
var _won := false
var _banner: Label
var gems_total: int = 0
var gems_collected: int = 0
var _gem_label: Label

func _ready() -> void:
	add_to_group("level")
	var p1 := get_node_or_null("Player1")
	if p1 != null:
		spawn_point = Vector2(p1.position.x, p1.position.y - 20.0)
	var mus := get_node_or_null("Music")
	if mus is AudioStreamPlayer and mus.stream is AudioStreamWAV:
		(mus.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_banner = Label.new()
	_banner.text = "LEVEL COMPLETE!"
	_banner.visible = false
	_banner.add_theme_font_size_override("font_size", 32)
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layer.add_child(_banner)
	# gems HUD (pixel heart style placeholder)
	_gem_label = Label.new()
	_gem_label.add_theme_font_size_override("font_size", 14)
	_gem_label.position = Vector2(8, 8)
	_gem_label.text = ""
	layer.add_child(_gem_label)
	await get_tree().process_frame
	gems_total = get_tree().get_nodes_in_group("gems").size()
	_update_gem_hud()
	# listen for late-spawned gems
	get_tree().node_added.connect(func(n): if n.is_in_group("gems"): gems_total += 1; _update_gem_hud())

func _update_gem_hud() -> void:
	if _gem_label != null:
		_gem_label.text = "GEMS %d/%d" % [gems_collected, gems_total] if gems_total > 0 else ""
		_gem_label.visible = gems_total > 0

func can_finish() -> bool:
	return gems_total == 0 or gems_collected >= gems_total

func gem_collected(_gem: Node) -> void:
	gems_collected += 1
	_update_gem_hud()
	SFX.play_checkpoint(self) # reuse checkpoint ding for gems
	if _won == false and gems_collected >= gems_total and gems_total > 0:
		# optional feedback when last gem taken
		var tw := create_tween()
		tw.tween_property(_gem_label, "scale", Vector2(1.25, 1.25), 0.12)
		tw.tween_property(_gem_label, "scale", Vector2(1, 1), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func set_spawn(world_pos: Vector2) -> void:
	spawn_point = world_pos + Vector2(0, -20.0)

func respawn(player: Node2D) -> void:
	var offset := Vector2.ZERO
	if String(player.name) == "Player2":
		offset = Vector2(40, 0)
	player.global_position = spawn_point + offset
	if "velocity" in player:
		player.velocity = Vector2.ZERO

func respawn_both() -> void:
	# For now instakill: both back to checkpoint. Later: decrement hearts (3)
	for p in get_tree().get_nodes_in_group("players"):
		if p is Node2D:
			respawn(p)

func on_goal() -> void:
	if _won:
		return
	_won = true
	_banner.visible = true
	_banner.modulate.a = 0.0
	_banner.scale = Vector2(0.6, 0.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_banner, "modulate:a", 1.0, 0.4)
	tw.tween_property(_banner, "scale", Vector2(1, 1), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	SFX.play_goal(self)
	for p in get_tree().get_nodes_in_group("players"):
		if p is Node2D:
			Juice.spawn_confetti(self, p.global_position + Vector2(0, -16))

func _physics_process(_delta: float) -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if p is Node2D and p.global_position.y > 500.0:
			respawn(p)
