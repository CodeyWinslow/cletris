extends Node2D

const Rules = preload("res://scripts/core/cletris_rules.gd")

const BOARD_ORIGIN := Vector2(24, 84)
const CELL := 32.0
const CONTROL_TOP := 650.0
const COLORS := [Color("000000"), Color("38bdf8"), Color("818cf8"), Color("fb923c"), Color("facc15"), Color("4ade80"), Color("e879f9"), Color("fb7185")]

var rules = Rules.new()
var gravity_elapsed := 0.0
var gravity_seconds := 0.65

func _ready() -> void:
	rules.new_game(20260824)
	queue_redraw()

func _process(delta: float) -> void:
	if not rules.game_over:
		gravity_elapsed += delta
		if gravity_elapsed >= gravity_seconds:
			gravity_elapsed = 0.0
			rules.step_down()
			queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
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
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch(event.position)

func _handle_touch(position: Vector2) -> void:
	if rules.game_over:
		rules.new_game(rules.seed)
		queue_redraw()
		return
	if position.y < CONTROL_TOP:
		return
	if position.x < 144:
		rules.try_move(Vector2i.LEFT)
	elif position.x < 288:
		rules.try_move(Vector2i.RIGHT)
	elif position.y < 710:
		rules.try_rotate_clockwise()
	else:
		rules.hard_drop()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(432, 768)), Color("07111f"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 42), "CLETRIS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("e0f2fe"))
	draw_string(ThemeDB.fallback_font, Vector2(252, 34), "SCORE %06d" % rules.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("94a3b8"))
	draw_string(ThemeDB.fallback_font, Vector2(252, 57), "LINES %03d" % rules.lines, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("94a3b8"))
	draw_rect(Rect2(BOARD_ORIGIN - Vector2(4, 4), Vector2(CletrisRules.BOARD_WIDTH * CELL + 8, CletrisRules.BOARD_HEIGHT * CELL + 8)), Color("10233a"), true)
	for y in range(CletrisRules.BOARD_HEIGHT):
		for x in range(CletrisRules.BOARD_WIDTH):
			_draw_cell(Vector2i(x, y), rules.board[y][x])
	if not rules.game_over:
		for cell in rules.active_cells():
			_draw_cell(cell, rules.piece_value(rules.active.id))
	_draw_controls()
	if rules.game_over:
		draw_rect(Rect2(35, 330, 362, 94), Color(0.02, 0.06, 0.12, 0.94), true)
		draw_string(ThemeDB.fallback_font, Vector2(96, 370), "STACK LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("f8fafc"))
		draw_string(ThemeDB.fallback_font, Vector2(72, 400), "Tap anywhere to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("7dd3fc"))

func _draw_cell(cell: Vector2i, value: int) -> void:
	var rect := Rect2(BOARD_ORIGIN + Vector2(cell) * CELL, Vector2.ONE * (CELL - 2.0))
	if value == 0:
		draw_rect(rect, Color("0b1b2e"), true)
		draw_rect(rect, Color("122b47"), false, 1.0)
	else:
		draw_rect(rect, COLORS[value], true)
		draw_line(rect.position + Vector2(3, 3), rect.position + Vector2(rect.size.x - 4, 3), Color(1, 1, 1, 0.55), 2.0)

func _draw_controls() -> void:
	var labels := ["LEFT", "RIGHT", "ROTATE", "DROP"]
	var rects := [Rect2(12, CONTROL_TOP, 99, 106), Rect2(119, CONTROL_TOP, 99, 106), Rect2(226, CONTROL_TOP, 94, 52), Rect2(328, CONTROL_TOP, 92, 106)]
	for index in rects.size():
		var rect: Rect2 = rects[index]
		draw_rect(rect, Color("12304d"), true)
		draw_rect(rect, Color("38bdf8"), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, rect.size.y * 0.58), labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e0f2fe"))
