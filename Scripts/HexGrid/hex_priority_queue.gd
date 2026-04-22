extends RefCounted
class_name HexPriorityQueue

# Binary min-heap of HexCell, ordered by cell.distance.
# Supports "decrease-key" lazily: when popping, skip entries whose
# stored priority no longer matches the cell's current distance.

var _heap: Array = []  # Array of [priority:int, cell:HexCell]

func is_empty() -> bool:
	return _heap.is_empty()

func size() -> int:
	return _heap.size()

func enqueue(cell: HexCell, priority: int) -> void:
	_heap.append([priority, cell])
	_sift_up(_heap.size() - 1)

func dequeue() -> HexCell:
	# Skip stale entries (cell's distance changed after it was enqueued).
	while not _heap.is_empty():
		var top: Array = _heap[0]
		var last: Array = _heap.pop_back()
		if not _heap.is_empty():
			_heap[0] = last
			_sift_down(0)
		var priority: int = top[0]
		var cell: HexCell = top[1]
		if cell.distance == priority:
			return cell
		# else stale — keep popping
	return null

func _sift_up(i: int) -> void:
	while i > 0:
		var parent: int = (i - 1) >> 1
		if _heap[i][0] < _heap[parent][0]:
			var tmp = _heap[i]
			_heap[i] = _heap[parent]
			_heap[parent] = tmp
			i = parent
		else:
			return

func _sift_down(i: int) -> void:
	var n := _heap.size()
	while true:
		var l := 2 * i + 1
		var r := 2 * i + 2
		var smallest := i
		if l < n and _heap[l][0] < _heap[smallest][0]:
			smallest = l
		if r < n and _heap[r][0] < _heap[smallest][0]:
			smallest = r
		if smallest == i:
			return
		var tmp = _heap[i]
		_heap[i] = _heap[smallest]
		_heap[smallest] = tmp
		i = smallest
