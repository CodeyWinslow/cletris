class_name CletrisRules
extends RefCounted

const PieceSource = preload("res://scripts/core/piece_source.gd")

const BOARD_WIDTH := 10
const BOARD_HEIGHT := 20
const SPAWN_POSITION := Vector2i(3, 0)
const SCORE_BY_CLEAR := [0, 100, 300, 500, 800]

const SHAPES := {
	"I": [[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)], [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]],
	"J": [[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)], [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)], [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]],
	"L": [[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)], [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]],
	"O": [[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)]],
	"S": [[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)], [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]],
	"T": [[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)], [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)], [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]],
	"Z": [[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)], [Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]]
}

var board: Array = []
var score := 0
var lines := 0
var game_over := false
var active := {}
var next_piece_id := ""
var seed := 1
var source

func new_game(new_seed: int = 1) -> void:
	seed = new_seed
	board.clear()
	for _row in range(BOARD_HEIGHT):
		var row: Array[int] = []
		row.resize(BOARD_WIDTH)
		row.fill(0)
		board.append(row)
	score = 0
	lines = 0
	game_over = false
	active = {}
	next_piece_id = ""
	source = PieceSource.new(seed)
	spawn_next()

func spawn_next() -> void:
	if next_piece_id.is_empty():
		next_piece_id = source.next_piece()
	spawn_piece(next_piece_id)
	next_piece_id = source.next_piece()

func spawn_piece(piece_id: String) -> void:
	active = {"id": piece_id, "position": SPAWN_POSITION, "rotation": 0}
	if not can_place(piece_id, SPAWN_POSITION, 0):
		game_over = true

func can_place(piece_id: String, position: Vector2i, rotation: int) -> bool:
	for offset in cells_for(piece_id, rotation):
		var cell: Vector2i = position + offset
		if cell.x < 0 or cell.x >= BOARD_WIDTH or cell.y < 0 or cell.y >= BOARD_HEIGHT:
			return false
		if board[cell.y][cell.x] != 0:
			return false
	return true

func cells_for(piece_id: String, rotation: int) -> Array:
	var rotations: Array = SHAPES[piece_id]
	return rotations[rotation % rotations.size()]

func active_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if active.is_empty():
		return result
	for offset in cells_for(active.id, active.rotation):
		result.append(active.position + offset)
	return result

func try_move(delta: Vector2i) -> bool:
	if game_over or active.is_empty():
		return false
	var target: Vector2i = active.position + delta
	if can_place(active.id, target, active.rotation):
		active.position = target
		return true
	return false

func try_rotate_clockwise() -> bool:
	if game_over or active.is_empty():
		return false
	var rotations: Array = SHAPES[active.id]
	var target_rotation: int = (active.rotation + 1) % rotations.size()
	if can_place(active.id, active.position, target_rotation):
		active.rotation = target_rotation
		return true
	return false

func try_rotate_counterclockwise() -> bool:
	if game_over or active.is_empty():
		return false
	var rotations: Array = SHAPES[active.id]
	var target_rotation: int = (active.rotation - 1 + rotations.size()) % rotations.size()
	if can_place(active.id, active.position, target_rotation):
		active.rotation = target_rotation
		return true
	return false

func step_down() -> bool:
	if try_move(Vector2i.DOWN):
		return true
	lock_active()
	return false

func hard_drop() -> void:
	while try_move(Vector2i.DOWN):
		pass
	lock_active()

func lock_active() -> void:
	if game_over or active.is_empty():
		return
	for cell in active_cells():
		board[cell.y][cell.x] = piece_value(active.id)
	var cleared := clear_complete_lines()
	if cleared > 0:
		lines += cleared
		score += SCORE_BY_CLEAR[cleared]
	spawn_next()

func clear_complete_lines() -> int:
	var survivors: Array = []
	var cleared := 0
	for row in board:
		if row.all(func(value: int) -> bool: return value != 0):
			cleared += 1
		else:
			survivors.append(row)
	while survivors.size() < BOARD_HEIGHT:
		var empty: Array[int] = []
		empty.resize(BOARD_WIDTH)
		empty.fill(0)
		survivors.push_front(empty)
	board = survivors
	return cleared

func piece_value(piece_id: String) -> int:
	return ["I", "J", "L", "O", "S", "T", "Z"].find(piece_id) + 1
