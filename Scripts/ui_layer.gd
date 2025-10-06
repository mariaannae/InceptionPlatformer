extends CanvasLayer

@export var death_check_enabled: bool = true
@export var death_y_threshold: float = 500.0
@export var dissolve_overlay_path: NodePath = ^"../DissolveOverlay"
@export var dream_scene_path: NodePath = ^".."
@export var dissolve_duration: float = 1.5
@onready var timer_label: Label = $TimerPanel/TimerLabel

@export var yawn_volume_db: float = 2.0
const _YAWN_PATHS := ["res://Musics/yawn.mp3"]
var _yawn: AudioStreamPlayer

var _popup: Control
var _next_btn: Button
var _popup_open := false
var _player: Node2D
var _ending_in_progress := false

# Entry point – defer UI setup to avoid "parent busy" errors.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_init_popup")
	
	if get_tree().has_meta("post_reload_regen") and bool(get_tree().get_meta("post_reload_regen")):
		get_tree().set_meta("post_reload_regen", null)

# Build popup UI, hook timer signal, and start wiring goal nodes.
func _init_popup() -> void:
	_popup = _build_popup("You wake up!")
	_popup.visible = false
	_popup.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child.call_deferred(_popup)

	if is_instance_valid(timer_label) and timer_label.has_signal("time_up"):
		timer_label.connect("time_up", Callable(self, "_on_time_up"))
		
	call_deferred("_wire_goals")
	call_deferred("_connect_player_to_timer")

func _connect_player_to_timer() -> void:
	var player := _get_player()
	if player and player.has_signal("first_movement"):
		if not player.is_connected("first_movement", Callable(timer_label, "start_timer")):
			player.connect("first_movement", Callable(timer_label, "start_timer"))
			print("Connected player first movement to timer start")

# Per-frame: check fall-death while no popup is open.
func _process(_dt: float) -> void:
	if not _popup_open and death_check_enabled and not _ending_in_progress:
		_check_fall_death()

# Handle keyboard input for popup shortcuts.
func _input(event: InputEvent) -> void:
	if not _popup_open:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_R:
			_on_next_pressed()
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()

# Countdown finished → dissolve then show popup.
func _on_time_up() -> void:
	_dissolve_and_popup("Time is up!\nYou wake up remembering nothing!")

# Popup button: unpause and reload current scene.
func _on_next_pressed() -> void:
	get_tree().paused = false
	_ending_in_progress = false
	get_tree().set_meta("post_reload_regen", true)
	get_tree().reload_current_scene()

func _get_dream_scene() -> Node:
	var n := get_node_or_null(dream_scene_path)
	return n

# Detect if player fell below threshold and end the run.
func _check_fall_death() -> void:
	var p := _get_player()
	if p == null:
		return
	if p.global_position.y > death_y_threshold:
		_dissolve_and_popup("You are dead in dream!\nYou wake up from a nightmare!")

# Find and cache the Player node (path first, then by name).
func _get_player() -> Node2D:
	if is_instance_valid(_player):
		return _player
	var root := get_tree().current_scene
	if root:
		var by_path := root.get_node_or_null("SubViewportContainer/SubViewport/GameWorld/Player")
		if by_path and by_path is Node2D:
			_player = by_path
			return _player
		var by_name := root.find_child("Player", true, false)
		if by_name and by_name is Node2D:
			_player = by_name
			return _player
	return null

# Scan current tree and future nodes; wire goals once created.
func _wire_goals() -> void:
	var root := get_tree().current_scene
	if root:
		_wire_goals_recursive(root)
	if not get_tree().is_connected("node_added", Callable(self, "_maybe_wire_goal")):
		get_tree().connect("node_added", Callable(self, "_maybe_wire_goal"))

# DFS: attempt wiring for each child node.
func _wire_goals_recursive(n: Node) -> void:
	for c in n.get_children():
		_maybe_wire_goal(c)
		_wire_goals_recursive(c)

# If a node looks like a goal, add to group and bind body_entered.
func _maybe_wire_goal(n: Node) -> void:
	if not (n is Area2D):
		return

	var name_lc := String(n.name).to_lower()
	var looks_like_goal := name_lc == "goal" or name_lc.contains("goal")
	var in_goal_group := n.has_method("is_in_group") and n.is_in_group("goal")
	if not (looks_like_goal or in_goal_group):
		return

	if not in_goal_group and n.has_method("add_to_group"):
		n.add_to_group("goal")

	if n.has_signal("body_entered"):
		if not n.is_connected("body_entered", Callable(self, "_on_goal_body_entered")):
			n.connect("body_entered", Callable(self, "_on_goal_body_entered"))

# Goal reached by the player → dissolve then show success popup.
func _on_goal_body_entered(body: Node) -> void:
	var p := _get_player()
	var is_player := (body == p) \
		or (body and body.name == "Player") \
		or (body and body.has_method("is_in_group") and body.is_in_group("player"))
	if not is_player:
		return
	_dissolve_and_popup("You have successfully found it!\nYou wake up from a sweet dream!")

# Generic popup display and pause the game.
func _show_popup(title_text: String) -> void:
	if _popup_open:
		return
	_popup_open = true
	if is_instance_valid(_popup):
		var title := _popup.get_node_or_null("CenterContainer/Panel/VBox/Title") as Label
		if title:
			title.text = title_text
		_popup.visible = true
	get_tree().paused = true

# End sequence: dissolve the scene first, then open popup.
func _dissolve_and_popup(title_text: String) -> void:
	if _popup_open:
		return
	_ending_in_progress = true
	
	# Pause the timer during death/success screens
	if timer_label and timer_label.has_method("pause_timer"):
		timer_label.pause_timer()
	
	# Disable flying mode when ending
	_disable_flying_mode()

	var overlay := _get_dissolve_overlay()
	if overlay and overlay.material:
		get_tree().paused = true
		overlay.visible = true
		_play_yawn_sfx()
		var mat := overlay.material
		mat.set_shader_parameter("dissolve_progress", 0.0)

		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(mat, "shader_parameter/dissolve_progress", 1.0, dissolve_duration)
		await tw.finished
	else:
		get_tree().paused = true

	_show_popup(title_text)

# Disable flying mode on the player
func _disable_flying_mode() -> void:
	var player := _get_player()
	if player and player.has_method("set_flying_mode"):
		player.set_flying_mode(false)
		print(">>> Flying mode DISABLED (level ending) <<<")

# Resolve dissolve overlay (ColorRect) via exported NodePath.
func _get_dissolve_overlay() -> ColorRect:
	var node := get_node_or_null(dissolve_overlay_path)
	if node and node is ColorRect:
		return node as ColorRect
	return null

# Build the popup UI dynamically (panel + title + button).
func _build_popup(initial_title: String) -> Control:
	var root := Control.new()
	root.name = "TimeoutPopup"
	root.anchor_left = 0
	root.anchor_top = 0
	root.anchor_right = 1
	root.anchor_bottom = 1

	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.anchor_left = 0
	center.anchor_top = 0
	center.anchor_right = 1
	center.anchor_bottom = 1
	root.add_child(center)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(540, 240)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24
	vbox.offset_top = 24
	vbox.offset_right = -24
	vbox.offset_bottom = -24
	panel.add_child(vbox)

	var title := Label.new()
	title.name = "Title"
	title.text = initial_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	var h := HBoxContainer.new()
	h.name = "ButtonRow"
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(h)

	_next_btn = Button.new()
	_next_btn.name = "NextButton"
	_next_btn.text = "  To the next dream  "
	_next_btn.size_flags_horizontal = 0
	_next_btn.custom_minimum_size = Vector2.ZERO
	_next_btn.pressed.connect(_on_next_pressed)
	_next_btn.add_theme_font_size_override("font_size", 24)
	h.add_child(_next_btn)

	return root

# Play the ending yawn SFX once.
func _play_yawn_sfx() -> void:
	if _yawn == null:
		_yawn = AudioStreamPlayer.new()
		_yawn.name = "YawnSFX"
		add_child(_yawn)
		
	var stream: AudioStream = null
	for p in _YAWN_PATHS:
		if ResourceLoader.exists(p):
			stream = load(p)
			break
	if stream == null:
		push_warning("Yawn SFX not found. Tried: %s" % [_YAWN_PATHS])
		return
	_yawn.stream = stream
	_yawn.volume_db = yawn_volume_db
	_yawn.play()
