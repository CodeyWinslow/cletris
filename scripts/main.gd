extends Node2D

const Rules = preload("res://scripts/core/cletris_rules.gd")

const BOARD_ORIGIN := Vector2(24, 84)
const CELL := 32.0
const PREVIEW_BOX := Rect2(352, 32, 72, 64)
const PREVIEW_CELL := 14.0
const PAUSE_BUTTON := Rect2(352, 104, 72, 36)
const PAUSE_OVERLAY := Rect2(Vector2.ZERO, Vector2(432, 768))
const TAP_MAX_TRAVEL := 20.0
const HORIZONTAL_DRAG_STEP := 24.0
const SLAM_SWIPE_DISTANCE := 72.0
const HOLD_DELAY := 0.2
const HOLD_GRAVITY_SECONDS := 0.06
const COLORS := [Color("000000"), Color("38bdf8"), Color("818cf8"), Color("fb923c"), Color("facc15"), Color("4ade80"), Color("e879f9"), Color("fb7185")]

var rules = Rules.new()
var gravity_elapsed := 0.0
var gravity_seconds := 0.65
var touch_active := false
var touch_start := Vector2.ZERO
var touch_elapsed := 0.0
var horizontal_drag_remainder := 0.0
var touch_is_dragging := false
var paused := false

func _ready() -> void:
	rules.new_game(20260824)
	queue_redraw()

func _process(delta: float) -> void:
	if paused or rules.game_over:
		return
	if touch_active:
		touch_elapsed += delta
	gravity_elapsed += delta
	var fall_interval := HOLD_GRAVITY_SECONDS if touch_active and not touch_is_dragging and touch_elapsed >= HOLD_DELAY else gravity_seconds
	if gravity_elapsed >= fall_interval:
		gravity_elapsed = 0.0
		rules.step_down()
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
			_toggle_pause()
			return
		if paused:
			return
		if event.keycode == KEY_LEFT:
			rules.try_move(Vector2i.LEFT)
		elif event.keycode == KEY_RIGHT:
			rules.try_move(Vector2i.RIGHT)
		elif event.keycode == KEY_UP:
			rules.try_rotate_clockwise()
		elif event.keycode == KEY_DOWN:
			rules.step_down()
		elif event.keycode == KEY_SPACE:
			rules.hard_drop()
		elif event.keycode == KEY_R:
			rules.new_game(rules.seed)
		queue_redraw()
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if not rules.game_over and PAUSE_BUTTON.has_point(event.position):
			_toggle_pause()
			return
		if paused:
			return
		if rules.game_over:
			rules.new_game(rules.seed)
			paused = false
			queue_redraw()
			return
		touch_active = true
		touch_start = event.position
		touch_elapsed = 0.0
		horizontal_drag_remainder = 0.0
		touch_is_dragging = false
		return
	if paused or not touch_active:
		return
	touch_active = false
	if not touch_is_dragging and touch_elapsed < HOLD_DELAY:
		if touch_start.x < get_viewport_rect().size.x * 0.5:
			rules.try_rotate_counterclockwise()
		else:
			rules.try_rotate_clockwise()
	queue_redraw()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if paused or not touch_active or rules.game_over:
		return
	var displacement := event.position - touch_start
	if displacement.y >= SLAM_SWIPE_DISTANCE and abs(displacement.y) > abs(displacement.x):
		touch_active = false
		rules.hard_drop()
		queue_redraw()
		return
	if abs(displacement.x) >= TAP_MAX_TRAVEL:
		touch_is_dragging = true
		horizontal_drag_remainder += event.relative.x
		while abs(horizontal_drag_remainder) >= HORIZONTAL_DRAG_STEP:
			var direction := 1 if horizontal_drag_remainder > 0.0 else -1
			rules.try_move(Vector2i(direction, 0))
			horizontal_drag_remainder -= direction * HORIZONTAL_DRAG_STEP
		queue_redraw()

func _toggle_pause() -> void:
	if rules.game_over:
		return
	paused = not paused
	_cancel_touch_gesture()
	queue_redraw()

func _cancel_touch_gesture() -> void:
	touch_active = false
	touch_elapsed = 0.0
	horizontal_drag_remainder = 0.0
	touch_is_dragging = false

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(432, 768)), Color("07111f"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 42), "CLETRIS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("e0f2fe"))
	draw_string(ThemeDB.fallback_font, Vector2(196, 34), "SCORE %06d" % rules.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("94a3b8"))
	draw_string(ThemeDB.fallback_font, Vector2(196, 57), "LINES %03d" % rules.lines, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("94a3b8"))
	draw_string(ThemeDB.fallback_font, Vector2(358, 23), "NEXT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("94a3b8"))
	_draw_next_preview()
	draw_string(ThemeDB.fallback_font, Vector2(24, 73), "TAP ROTATES · HOLD FALLS · DRAG MOVES · SWIPE SLAMS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("64748b"))
	draw_rect(Rect2(BOARD_ORIGIN - Vector2(4, 4), Vector2(Rules.BOARD_WIDTH * CELL + 8, Rules.BOARD_HEIGHT * CELL + 8)), Color("10233a"), true)
	for y in range(Rules.BOARD_HEIGHT):
		for x in range(Rules.BOARD_WIDTH):
			_draw_cell(Vector2i(x, y), rules.board[y][x])
	if not rules.game_over:
		for cell in rules.active_cells():
			_draw_cell(cell, rules.piece_value(rules.active.id))
	if rules.game_over:
		draw_rect(Rect2(35, 330, 362, 94), Color(0.02, 0.06, 0.12, 0.94), true)
		draw_string(ThemeDB.fallback_font, Vector2(96, 370), "STACK LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("f8fafc"))
		draw_string(ThemeDB.fallback_font, Vector2(72, 400), "Tap anywhere to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("7dd3fc"))
	elif paused:
		_draw_pause_overlay()
	if not rules.game_over:
		_draw_pause_button()

func _draw_pause_button() -> void:
	var fill := Color("7c3aed") if paused else Color("172554")
	var label := "RESUME" if paused else "PAUSE"
	draw_rect(PAUSE_BUTTON, fill, true)
	draw_rect(PAUSE_BUTTON, Color("a5b4fc"), false, 1.0)
	draw_string(ThemeDB.fallback_font, PAUSE_BUTTON.position + Vector2(0, 23), label, HORIZONTAL_ALIGNMENT_CENTER, PAUSE_BUTTON.size.x, 11, Color("f8fafc"))

func _draw_pause_overlay() -> void:
	draw_rect(PAUSE_OVERLAY, Color(0.01, 0.03, 0.08, 0.82), true)
	draw_string(ThemeDB.fallback_font, Vector2(0, 348), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 432, 32, Color("f8fafc"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 378), "Tap RESUME to continue", HORIZONTAL_ALIGNMENT_CENTER, 432, 16, Color("c4b5fd"))

func _draw_next_preview() -> void:
	draw_rect(PREVIEW_BOX, Color("0b1b2e"), true)
	draw_rect(PREVIEW_BOX, Color("122b47"), false, 1.0)
	if rules.next_piece_id.is_empty():
		return
	var offsets: Array = rules.cells_for(rules.next_piece_id, 0)
	var minimum := Vector2i(4, 4)
	var maximum := Vector2i.ZERO
	for offset in offsets:
		var cell: Vector2i = offset
		minimum = Vector2i(min(minimum.x, cell.x), min(minimum.y, cell.y))
		maximum = Vector2i(max(maximum.x, cell.x), max(maximum.y, cell.y))
	var shape_size := maximum - minimum + Vector2i.ONE
	var shape_pixel_size := Vector2(shape_size) * PREVIEW_CELL
	var shape_origin := PREVIEW_BOX.position + (PREVIEW_BOX.size - shape_pixel_size) * 0.5
	var value := rules.piece_value(rules.next_piece_id)
	for offset in offsets:
		var preview_cell: Vector2i = offset
		var rect := Rect2(shape_origin + Vector2(preview_cell - minimum) * PREVIEW_CELL, Vector2.ONE * (PREVIEW_CELL - 2.0))
		_draw_preview_cell(rect, value)

func _draw_cell(cell: Vector2i, value: int) -> void:
	var rect := Rect2(BOARD_ORIGIN + Vector2(cell) * CELL, Vector2.ONE * (CELL - 2.0))
	if value == 0:
		draw_rect(rect, Color("0b1b2e"), true)
		draw_rect(rect, Color("122b47"), false, 1.0)
	else:
		_draw_preview_cell(rect, value)

func _draw_preview_cell(rect: Rect2, value: int) -> void:
	draw_rect(rect, COLORS[value], true)
	draw_line(rect.position + Vector2(3, 3), rect.position + Vector2(rect.size.x - 4, 3), Color(1, 1, 1, 0.55), 2.0)
