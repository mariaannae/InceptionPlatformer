extends Label

signal time_up
const COUNTDOWN_SECONDS := 30
var _timer: Timer
var _timer_started: bool = false
var _stored_time_left: float = 0.0  # Store remaining time when pausing

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
	if _timer and _timer_started and not _timer.is_stopped():
		# Store the remaining time before pausing
		_stored_time_left = _timer.time_left
		_timer.paused = true
		print("Timer paused with %.1f seconds left" % _stored_time_left)

func unpause_timer() -> void:
	if _timer and _timer_started:
		if _timer.is_stopped() and _stored_time_left > 0:
			# Timer was stopped, restart with stored time
			print("Restarting timer with stored time: %.1f seconds" % _stored_time_left)
			_timer.wait_time = _stored_time_left
			_timer.start()
			_stored_time_left = 0.0
		else:
			# Normal unpause
			_timer.paused = false
			print("Timer unpaused")

func reset_timer() -> void:
	"""Reset the timer back to its initial state"""
	if _timer:
		_timer.stop()
		_timer_started = false
		_update_text()
		print("Timer reset!")

func restart_timer() -> void:
	"""Restart the timer from the beginning"""
	if _timer:
		_timer.stop()
		_timer.wait_time = COUNTDOWN_SECONDS
		_timer.start()
		_timer_started = true
		_update_text()
		print("Timer restarted!")

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
