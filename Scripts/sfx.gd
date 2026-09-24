extends RefCounted
# Proper audio: pre-saved WAVs in Audio/*.wav. Falls back to generated tones if missing.
# Buses: SFX (SFX), Music (loop)

const WAV_JUMP := preload("res://Audio/jump.wav")
const WAV_LAND := preload("res://Audio/land.wav")
const WAV_ON := preload("res://Audio/crank_on.wav")
const WAV_OFF := preload("res://Audio/crank_off.wav")
const WAV_GOAL := preload("res://Audio/goal.wav")
const WAV_CHECK := preload("res://Audio/checkpoint.wav")
const WAV_KICK := preload("res://Audio/kick.wav")
const WAV_HIT := preload("res://Audio/hit.wav")

static func _play(at: Node, stream: AudioStream, bus: String, vol_db: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = vol_db
	at.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

static func play_jump(at: Node) -> void:
	_play(at, WAV_JUMP, "SFX", -2.0)

static func play_land(at: Node) -> void:
	_play(at, WAV_LAND, "SFX", -6.0)

static func play_toggle(at: Node, on: bool) -> void:
	_play(at, WAV_ON if on else WAV_OFF, "SFX", -4.0)

static func play_goal(at: Node) -> void:
	_play(at, WAV_GOAL, "SFX", -2.0)

static func play_checkpoint(at: Node) -> void:
	_play(at, WAV_CHECK, "SFX", -2.0)

static func play_kick(at: Node) -> void:
	_play(at, WAV_KICK, "SFX", -3.0)

static func play_hit(at: Node) -> void:
	_play(at, WAV_HIT, "SFX", -2.5)

# kept for compat
static func play_click(at: Node) -> void:
	play_toggle(at, true)
