extends Node2D

const Rules = preload("res://scripts/core/cletris_rules.gd")

const BOARD_ORIGIN := Vector2(24, 84)
const CELL := 32.0
const PREVIEW_BOX := Rect2(352, 32, 72, 64)
const PREVIEW_CELL := 14.0
const PAUSE_BUTTON := Rect2(352, 104, 72, 36)
const PAUSE_OVERLAY := Rect2(Vector2.ZERO, Vector2(432, 768))
const PAUSE_RESUME_BUTTON := Rect2(80, 420, 272, 52)
const PAUSE_MENU_BUTTON := Rect2(80, 488, 272, 52)
const MENU_PLAY_BUTTON := Rect2(96, 304, 240, 60)
const MENU_CREDITS_BUTTON := Rect2(96, 388, 240, 52)
const CREDITS_BACK_BUTTON := Rect2(96, 620, 240, 52)
const TAP_MAX_TRAVEL := 20.0
const HORIZONTAL_DRAG_STEP := 24.0
const SLAM_SWIPE_DISTANCE := 72.0
const HOLD_DELAY := 0.2
const HOLD_GRAVITY_SECONDS := 0.06
const COLORS := [Color("000000"), Color("38bdf8"), Color("818cf8"), Color("fb923c"), Color("facc15"), Color("4ade80"), Color("e879f9"), Color("fb7185")]

enum AppScreen { MAIN_MENU, GAME, CREDITS }

var rules = Rules.new()
var screen := AppScreen.MAIN_MENU
var gravity_elapsed := 0.0
var gravity_seconds := 0.65
var touch_active := false
var touch_start := Vector2.ZERO
var touch_elapsed := 0.0
var horizontal_drag_remainder := 0.0
var touch_is_dragging := false
var paused := false

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if screen != AppScreen.GAME or paused or rules.game_over:
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
		_handle_key(event.keycode)
		return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)

func _handle_key(keycode: int) -> void:
	if screen == AppScreen.MAIN_MENU:
		if keycode == KEY_ENTER or keycode == KEY_KP_ENTER or keycode == KEY_SPACE:
			_start_game()
		elif keycode == KEY_C:
			_show_credits()
		return
	if screen == AppScreen.CREDITS:
		if keycode == KEY_ESCAPE or keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			_show_main_menu()
		return
	if keycode == KEY_P or keycode == KEY_ESCAPE:
		_toggle_pause()
		return
	if paused:
		if keycode == KEY_M:
			_show_main_menu()
		return
	if keycode == KEY_LEFT:
		rules.try_move(Vector2i.LEFT)
	elif keycode == KEY_RIGHT:
		rules.try_move(Vector2i.RIGHT)
	elif keycode == KEY_UP:
		rules.try_rotate_clockwise()
	elif keycode == KEY_DOWN:
		rules.step_down()
	elif keycode == KEY_SPACE:
		rules.hard_drop()
	elif keycode == KEY_R:
		rules.new_game(rules.seed)
	gravity_elapsed = 0.0
	queue_redraw()

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if screen == AppScreen.MAIN_MENU:
		if event.pressed and MENU_PLAY_BUTTON.has_point(event.position):
			_start_game()
		elif event.pressed and MENU_CREDITS_BUTTON.has_point(event.position):
			_show_credits()
		return
	if screen == AppScreen.CREDITS:
		if event.pressed and CREDITS_BACK_BUTTON.has_point(event.position):
			_show_main_menu()
		return
	if event.pressed:
		if paused and PAUSE_RESUME_BUTTON.has_point(event.position):
			_toggle_pause()
			return
		if paused and PAUSE_MENU_BUTTON.has_point(event.position):
			_show_main_menu()
			return
		if not paused and not rules.game_over and PAUSE_BUTTON.has_point(event.position):
			_toggle_pause()
			return
		if paused:
			return
		if rules.game_over:
			_start_game()
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
	if screen != AppScreen.GAME or rules.game_over:
		return
	paused = not paused
	_cancel_touch_gesture()
	queue_redraw()

func _start_game() -> void:
	rules.new_game(20260824)
	gravity_elapsed = 0.0
	paused = false
	_cancel_touch_gesture()
	screen = AppScreen.GAME
	queue_redraw()

func _show_main_menu() -> void:
	paused = false
	_cancel_touch_gesture()
	rules = Rules.new()
	gravity_elapsed = 0.0
	screen = AppScreen.MAIN_MENU
	queue_redraw()

func _show_credits() -> void:
	_cancel_touch_gesture()
	screen = AppScreen.CREDITS
	queue_redraw()

func _cancel_touch_gesture() -> void:
	touch_active = false
	touch_elapsed = 0.0
	horizontal_drag_remainder = 0.0
	touch_is_dragging = false

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(432, 768)), Color("07111f"))
	if screen == AppScreen.MAIN_MENU:
		_draw_main_menu()
	elif screen == AppScreen.CREDITS:
		_draw_credits()
	else:
		_draw_game()

func _draw_main_menu() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(24, 188), "CLETRIS", HORIZONTAL_ALIGNMENT_CENTER, 384, 48, Color("e0f2fe"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 230), "PROCEDURAL FALLING-BLOCK PUZZLE", HORIZONTAL_ALIGNMENT_CENTER, 384, 13, Color("64748b"))
	_draw_shell_button(MENU_PLAY_BUTTON, "PLAY", Color("0e7490"))
	_draw_shell_button(MENU_CREDITS_BUTTON, "CREDITS", Color("172554"))

func _draw_credits() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(24, 130), "CREDITS", HORIZONTAL_ALIGNMENT_CENTER, 384, 32, Color("e0f2fe"))
	draw_string(ThemeDB.fallback_font, Vector2(48, 240), "CLETRIS", HORIZONTAL_ALIGNMENT_CENTER, 336, 24, Color("7dd3fc"))
	draw_string(ThemeDB.fallback_font, Vector2(48, 282), "An original procedural puzzle game", HORIZONTAL_ALIGNMENT_CENTER, 336, 16, Color("cbd5e1"))
	draw_string(ThemeDB.fallback_font, Vector2(48, 318), "Built with deterministic GDScript rules", HORIZONTAL_ALIGNMENT_CENTER, 336, 14, Color("94a3b8"))
	_draw_shell_button(CREDITS_BACK_BUTTON, "BACK", Color("172554"))

func _draw_game() -> void:
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
		_draw_ghost_piece()
		for cell in rules.active_cells():
			_draw_cell(cell, rules.piece_value(rules.active.id))
	if rules.game_over:
		draw_rect(Rect2(35, 330, 362, 94), Color(0.02, 0.06, 0.12, 0.94), true)
		draw_string(ThemeDB.fallback_font, Vector2(96, 370), "STACK LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("f8fafc"))
		draw_string(ThemeDB.fallback_font, Vector2(72, 400), "Tap anywhere to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("7dd3fc"))
	elif paused:
		_draw_pause_overlay()
	if not rules.game_over and not paused:
		_draw_pause_button()

func _draw_pause_button() -> void:
	_draw_shell_button(PAUSE_BUTTON, "PAUSE", Color("172554"))

func _draw_pause_overlay() -> void:
	draw_rect(PAUSE_OVERLAY, Color(0.01, 0.03, 0.08, 0.82), true)
	draw_string(ThemeDB.fallback_font, Vector2(0, 348), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 432, 32, Color("f8fafc"))
	_draw_shell_button(PAUSE_RESUME_BUTTON, "RESUME", Color("7c3aed"))
	_draw_shell_button(PAUSE_MENU_BUTTON, "MAIN MENU", Color("172554"))

func _draw_shell_button(rect: Rect2, label: String, fill: Color) -> void:
	draw_rect(rect, fill, true)
	draw_rect(rect, Color("a5b4fc"), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15, Color("f8fafc"))

func _draw_ghost_piece() -> void:
	if rules.active.is_empty():
		return
	var landing_position: Vector2i = rules.active.position
	while rules.can_place(rules.active.id, landing_position + Vector2i.DOWN, rules.active.rotation):
		landing_position += Vector2i.DOWN
	var value := rules.piece_value(rules.active.id)
	for offset in rules.cells_for(rules.active.id, rules.active.rotation):
		_draw_ghost_cell(landing_position + offset, value)

func _draw_ghost_cell(cell: Vector2i, value: int) -> void:
	var rect := Rect2(BOARD_ORIGIN + Vector2(cell) * CELL, Vector2.ONE * (CELL - 2.0))
	var color: Color = COLORS[value]
	color.a = 0.2
	draw_rect(rect, color, true)
	color.a = 0.8
	draw_rect(rect, color, false, 2.0)

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
