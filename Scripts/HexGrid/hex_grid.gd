@tool
extends Manager
class_name HexGrid

@export var width: int = 24
@export var height: int = 24
@export var chunk_size: int = 4

@export var cell_dictionary : Dictionary[String, Mesh]

@export var generator: HexMapGenerator = HexMapGenerator.new()

var chunk_count_x: int
var chunk_count_z: int
var cells: Array[HexCell] = []
var chunks: Array[HexGridChunk] = []
var ground_body: StaticBody3D

const _VARIANT_SUFFIXES: Array[String] = [
	# Rivers
	"river_end",
	"river_straight",
	"river_sharp",
	"river_curve",
	# Roads
	"road_1",
	"road_2_straight",
	"road_2_sharp",
	"road_2_curve",
	"road_3_y",
	"road_3_t",
	"road_3_k",
	"road_4_x",
	"road_4_y",
	"road_4_z",
	"road_5",
	"road_6",
]

# Biomes you actually use. Add more here later (e.g. "sand", "forest").
const _BIOMES: Array[String] = ["base_cell"]

func _populate_cell_dictionary_keys() -> void:
	# Always-present base keys.
	if not cell_dictionary.has("water"):
		cell_dictionary["water"] = null
	for biome in _BIOMES:
		if not cell_dictionary.has(biome):
			cell_dictionary[biome] = null
		for suffix in _VARIANT_SUFFIXES:
			var key := "%s_%s" % [biome, suffix]
			if not cell_dictionary.has(key):
				cell_dictionary[key] = null
func _ready() -> void:
	if Engine.is_editor_hint():
		_ensure_dictionary_keys()


func _ensure_dictionary_keys() -> void:
	var changed := false

	if not cell_dictionary.has("water"):
		cell_dictionary["water"] = null
		changed = true

	for biome in _BIOMES:
		if not cell_dictionary.has(biome):
			cell_dictionary[biome] = null
			changed = true
		for suffix in _VARIANT_SUFFIXES:
			var key := "%s_%s" % [biome, suffix]
			if not cell_dictionary.has(key):
				cell_dictionary[key] = null
				changed = true

	if changed:
		notify_property_list_changed()

func get_manager_name() -> String: return "HexGrid"

func _setup():
	chunk_count_x = ceili(float(width) / chunk_size)
	chunk_count_z = ceili(float(height) / chunk_size)

	cells.resize(width * height)
	chunks.resize(chunk_count_x * chunk_count_z)

func _execute():
	_setup_ground_collider()
	_create_chunks()
	_create_cells()
	generator.generate(self)
	_build_chunks()


func _create_chunks() -> void:
	for z in range(chunk_count_z):
		for x in range(chunk_count_x):
			var chunk := HexGridChunk.new(cell_dictionary)
			chunk.name = "Chunk (%d,%d)" % [x, z]

			var chunk_pos := Vector3.ZERO
			chunk_pos.x = (x * chunk_size) * (HexMetrics.inner_radius * 2.0)
			chunk_pos.z = (z * chunk_size) * (HexMetrics.outer_radius * 1.5)
			chunk.position = chunk_pos

			chunks[z * chunk_count_x + x] = chunk
			add_child(chunk)

func _create_cells() -> void:
	var i: int = 0
	for z in range(height):
		for x in range(width):
			create_cell(x, z, i)
			
			i += 1

func create_cell(x: int, z: int, i: int) -> void:
	var pos: Vector3
	pos.x = (x + (z & 1) * 0.5) * (HexMetrics.inner_radius * 2.0)
	pos.z = z * (HexMetrics.outer_radius * 1.5)
	# elevation will be set by the generator
	pos.y = 0.0

	var cell := HexCell.new()


	if x > 0:
		cell.set_neighbor(Enums.HexDirection.W, cells[i - 1])
	if z > 0:
		if (z & 1) == 0:
			cell.set_neighbor(Enums.HexDirection.SE, cells[i - width])
			if x > 0:
				cell.set_neighbor(Enums.HexDirection.SW, cells[i - width - 1])
		else:
			cell.set_neighbor(Enums.HexDirection.SW, cells[i - width])
			if x < width - 1:
				cell.set_neighbor(Enums.HexDirection.SE, cells[i - width + 1])

	var chunk_x: int = x / chunk_size
	var chunk_z: int = z / chunk_size
	var chunk := chunks[chunk_z * chunk_count_x + chunk_x]
	cell.position = pos - chunk.position
	chunk.add_cell(cell)
	cell.setup(x, z, pos, 0)
	cells[i] = cell

func _build_chunks() -> void:
	for chunk in chunks:
		chunk.build()

func _setup_ground_collider() -> void:
	ground_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := WorldBoundaryShape3D.new()
	shape.plane = Plane(Vector3.UP, 0.0)
	col.shape = shape
	ground_body.add_child(col)
	add_child(ground_body)

func get_cell_from_position(world_pos: Vector3) -> HexCell:
	var coords := HexGrid.from_position(world_pos)
	var offset_x := coords.x + coords.z / 2
	var index := offset_x + coords.z * width
	if index >= 0 and index < cells.size():
		return cells[index]
	return null

static func from_position(pos: Vector3) -> HexCoordinates:
	var x: float = pos.x / (HexMetrics.inner_radius * 2.0)
	var y: float = -x
	var offset: float = pos.z / (HexMetrics.outer_radius * 3.0)
	x -= offset
	y -= offset

	var iX: int = roundi(x)
	var iY: int = roundi(y)
	var iZ: int = roundi(-x - y)

	if iX + iY + iZ != 0:
		var dX: float = abs(x - iX)
		var dY: float = abs(y - iY)
		var dZ: float = abs(-x - y - iZ)
		if dX > dY and dX > dZ:
			iX = -iY - iZ
		elif dZ > dY:
			iZ = -iX - iY

	return HexCoordinates.new(iX, iZ)


func find_path(from_cell: HexCell, to_cell: HexCell, speed: int) -> void:
	search(from_cell, to_cell, speed)

func search(from_cell: HexCell, to_cell: HexCell, speed: int) -> void:
	for i in range(cells.size()):
		cells[i].distance = -1
		cells[i].path_from = null
		cells[i].disable_highlight()

	var frontier := HexPriorityQueue.new()
	from_cell.distance = 0
	frontier.enqueue(from_cell, 0)

	while not frontier.is_empty():
		var current: HexCell = frontier.dequeue()
		if current == null: break
		if current == to_cell: break

		for dir in range(6):
			var neighbor: HexCell = current.get_neighbor(dir)
			if neighbor == null or neighbor.is_underwater: continue

			var edge_type := current.get_edge_type_other_cell(neighbor)
			if edge_type == Enums.HexEdgeType.Cliff: continue

			# Calculate base movement cost
			var move_cost: int
			if current.has_road_through_edge(dir):
				move_cost = 1
			else:
				# Use plant_level as a penalty (as seen in Part 9)
				move_cost = 5 if edge_type == Enums.HexEdgeType.Flat else 10
				move_cost += neighbor.plant_level * 2 
			
			# PART 17 TURN LOGIC:
			# Calculate which turn this move would end on
			var distance: int = current.distance + move_cost
			var turn := (distance - 1) / speed
			var current_turn := (current.distance - 1) / speed
			
			# If we cross a turn boundary, we "waste" the remaining points 
			# of the previous turn and start the new turn with the full move cost.
			if turn > current_turn:
				distance = turn * speed + move_cost

			if neighbor.distance == -1 or distance < neighbor.distance:
				neighbor.distance = distance
				neighbor.path_from = current
				frontier.enqueue(neighbor, distance)

	_highlight_path(from_cell, to_cell, speed)

func _highlight_path(from_cell: HexCell, to_cell: HexCell, speed: int):
	from_cell.enable_highlight(Color.BLUE)
	if to_cell and to_cell.distance != -1:
		to_cell.enable_highlight(Color.RED)
		var current := to_cell.path_from
		while current != null and current != from_cell:
			# Blue for reachable this turn, White for later turns
			if current.distance <= speed:
				current.enable_highlight(Color.CYAN)
			else:
				current.enable_highlight(Color.WHITE)
			current = current.path_from


func show_range(from_cell: HexCell, speed: int, max_turns: int = 1):
	# Reset and run search
	search(from_cell, null, speed) # Setting to_cell to null searches everything
	
	var max_distance = speed * max_turns
	
	for cell in cells:
		if cell.distance != -1 and cell.distance <= max_distance:
			if cell.distance <= speed:
				cell.enable_highlight(Color.BLUE) # Turn 1
			else:
				cell.enable_highlight(Color.SLATE_BLUE) # Turn 2+
		else:
			cell.disable_highlight()


func get_random_cell(only_walkable: bool = false) -> HexCell:
	if cells.is_empty():
		return null

	if not only_walkable:
		return cells.pick_random()

	# Optimization: Try picking randomly 50 times first (fast)
	for i in range(50):
		var cell = cells.pick_random()
		if not cell.is_underwater:
			return cell

	# Fallback: If we didn't find one (e.g. mostly water map), 
	# filter the list once to get all valid options.
	var walkable_cells = cells.filter(func(c): return not c.is_underwater)
	
	if walkable_cells.is_empty():
		push_warning("get_random_cell: No walkable cells found in grid.")
		return null
		
	return walkable_cells.pick_random()
