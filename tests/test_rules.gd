extends SceneTree

const Rules = preload("res://scripts/core/cletris_rules.gd")
const PieceSource = preload("res://scripts/core/piece_source.gd")

var failures := 0

func _init() -> void:
	test_seeded_sequences()
	test_collision_and_rotation()
	test_locking_clearing_and_scoring()
	test_game_over()
	if failures == 0:
		print("PASS: deterministic rules tests")
		quit(0)
	else:
		push_error("FAIL: %d deterministic rules test(s)" % failures)
		quit(1)

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func test_seeded_sequences() -> void:
	var first = PieceSource.new(12345)
	var second = PieceSource.new(12345)
	var third = PieceSource.new(54321)
	var sequence_a: Array[String] = []
	var sequence_b: Array[String] = []
	var sequence_c: Array[String] = []
	for _index in range(14):
		sequence_a.append(first.next_piece())
		sequence_b.append(second.next_piece())
		sequence_c.append(third.next_piece())
	expect(sequence_a == sequence_b, "equal seeds must produce equal sequences")
	expect(sequence_a != sequence_c, "different seeds should produce a different sequence")
	var seen := {}
	for piece in sequence_a.slice(0, 7):
		seen[piece] = true
	expect(seen.size() == 7, "a bag must include all seven pieces")

func test_collision_and_rotation() -> void:
	var rules = Rules.new()
	rules.new_game(1)
	expect(not rules.can_place("O", Vector2i(-2, 0), 0), "piece may not cross the left wall")
	expect(not rules.can_place("O", Vector2i(8, 0), 0), "piece may not cross the right wall")
	rules.board[1][4] = 1
	expect(not rules.can_place("O", Vector2i(3, 0), 0), "piece may not overlap locked cells")
	rules.new_game(1)
	rules.spawn_piece("I")
	rules.active.position = Vector2i(8, 0)
	expect(not rules.try_rotate_clockwise(), "invalid wall rotation must be rejected")
	rules.active.position = Vector2i(3, 0)
	expect(rules.try_rotate_clockwise(), "valid rotation must succeed")

func test_locking_clearing_and_scoring() -> void:
	var rules = Rules.new()
	rules.new_game(1)
	for x in range(Rules.BOARD_WIDTH):
		if x < 3 or x > 6:
			rules.board[19][x] = 1
	rules.active = {"id": "I", "position": Vector2i(3, 18), "rotation": 0}
	rules.lock_active()
	expect(rules.lines == 1, "completed row must clear")
	expect(rules.score == 100, "one cleared row must score 100")
	expect(rules.board[19].all(func(value: int) -> bool: return value == 0), "cleared row must be empty")

func test_game_over() -> void:
	var rules = Rules.new()
	rules.new_game(1)
	rules.board[0][4] = 1
	rules.spawn_piece("O")
	expect(rules.game_over, "blocked spawn must end the game")
