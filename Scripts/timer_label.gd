extends Label

signal time_up
const COUNTDOWN_SECONDS := 30
var _timer: Timer
var _timer_started: bool = false

func _ready() -> void:
	call_deferred("_init_timer")

func _init_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = COUNTDOWN_SECONDS
	_timer.timeout.connect(_on_timeout)
	add_child.call_deferred(_timer)
	# Don't start timer automatically anymore
	_update_text()

func start_timer() -> void:
	if not _timer_started and _timer:
		_timer.start()
		_timer_started = true
		print("Timer started!")

func pause_timer() -> void:
	if _timer and not _timer.is_stopped():
		_timer.paused = true

func unpause_timer() -> void:
	if _timer and not _timer.is_stopped():
		_timer.paused = false

func reset_timer() -> void:
	"""Reset the timer back to its initial state"""
	if _timer:
		_timer.stop()
		_timer_started = false
		_update_text()
		print("Timer reset!")

func _process(_dt: float) -> void:
	_update_text()

func _update_text() -> void:
	if _timer == null:
		return
	# If timer hasn't started yet, show the full countdown time
	var remain: int
	if not _timer_started:
		remain = COUNTDOWN_SECONDS
	else:
		remain = int(ceil(max(_timer.time_left, 0.0)))
	var mm := floori(remain / 60.0)
	var ss := remain - mm * 60
	text = "%02d:%02d" % [mm, ss]

func _on_timeout() -> void:
	text = "00:00"
	emit_signal("time_up")
