extends Node
@export var volume_db: float = -10.0

const _PATHS := ["res://Musics/BGM.mp3"]
var _player: AudioStreamPlayer

func _ready() -> void:
	if _player != null:
		return

	var stream: AudioStream = null
	for p in _PATHS:
		if ResourceLoader.exists(p):
			stream = load(p)
			break
	if stream == null:
		push_warning("BGM not found. Tried: %s" % [_PATHS])
		return

	_player = AudioStreamPlayer.new()
	_player.name = "BGMPlayer"
	_player.stream = stream
	_player.volume_db = volume_db
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	else:
		_player.finished.connect(func(): _player.play())

	if not _player.playing:
		_player.play()

func set_volume_db(v: float) -> void:
	volume_db = v
	if _player:
		_player.volume_db = v
