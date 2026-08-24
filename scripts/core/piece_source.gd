class_name CletrisPieceSource
extends RefCounted

const PIECES := ["I", "J", "L", "O", "S", "T", "Z"]

var _state: int
var _bag: Array[String] = []

func _init(seed: int) -> void:
	_state = seed & 0x7fffffff
	if _state == 0:
		_state = 1

func next_piece() -> String:
	if _bag.is_empty():
		_refill_bag()
	return _bag.pop_back()

func _refill_bag() -> void:
	_bag.assign(PIECES)
	for index in range(_bag.size() - 1, 0, -1):
		var swap_index := _next_random() % (index + 1)
		var saved := _bag[index]
		_bag[index] = _bag[swap_index]
		_bag[swap_index] = saved

func _next_random() -> int:
	_state = (_state * 1103515245 + 12345) & 0x7fffffff
	return _state
