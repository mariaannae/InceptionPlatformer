extends Label

signal time_up
const COUNTDOWN_SECONDS := 30
var _timer: Timer

func _ready() -> void:
	call_deferred("_init_timer")

func _init_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = COUNTDOWN_SECONDS
	_timer.timeout.connect(_on_timeout)
	add_child.call_deferred(_timer)
	_timer.call_deferred("start")
	_update_text()

func _process(_dt: float) -> void:
	_update_text()

func _update_text() -> void:
	if _timer == null:
		return
	var remain := int(ceil(max(_timer.time_left, 0.0)))
	var mm := floori(remain / 60.0)
	var ss := remain - mm * 60
	text = "%02d:%02d" % [mm, ss]

func _on_timeout() -> void:
	text = "00:00"
	emit_signal("time_up")
