extends Resource
class_name HexMapGenerator

# Tunables
@export var seed: int = 0
@export var elevation_frequency: float = 0.08
@export var moisture_frequency: float = 0.12
@export var water_level: float = -0.15      # noise value below this => water
@export var max_elevation: int = 5           # land cells scale 0..max_elevation
@export var river_count: int = 8
@export var road_chance: float = 0.35        # chance to try a road per land cell

var _elev_noise: FastNoiseLite
var _moist_noise: FastNoiseLite
var _rng: RandomNumberGenerator

func generate(grid: HexGrid) -> void:
	_rng = RandomNumberGenerator.new()
	if seed == 0:
		_rng.randomize()
	else:
		_rng.seed = seed

	_elev_noise = FastNoiseLite.new()
	_elev_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_elev_noise.frequency = elevation_frequency
	_elev_noise.seed = _rng.randi()

	_moist_noise = FastNoiseLite.new()
	_moist_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_moist_noise.frequency = moisture_frequency
	_moist_noise.seed = _rng.randi()

	_assign_terrain(grid)
	_create_rivers(grid)
	_create_roads(grid)


func _assign_terrain(grid: HexGrid) -> void:
	for cell in grid.cells:
		var cx: int = cell.coordinates.x
		var cz: int = cell.coordinates.z
		var e: float = _elev_noise.get_noise_2d(cx, cz)  # -1..1

		if e < water_level:
			cell.terrain_type = &"water"
			cell.elevation = 0
		else:
			cell.terrain_type = &"base_cell"
			# Remap (water_level..1) => (0..max_elevation)
			var t: float = (e - water_level) / (1.0 - water_level)
			cell.elevation = clampi(roundi(t * max_elevation), 0, max_elevation)
		
		
		if not cell.is_underwater:
		# Example: if it's high elevation, make it woodsy
			if cell.elevation > 3:
				cell.plant_level = _rng.randi_range(1, 3)
			# Random chance for a farm
			elif _rng.randf() > 0.8:
				cell.farm_level = _rng.randi_range(1, 2)

func _create_rivers(grid: HexGrid) -> void:
	# Pick the highest non-water cells as river sources; flow downhill to water.
	var candidates: Array[HexCell] = []
	for cell in grid.cells:
		if not cell.is_underwater and cell.elevation >= max(1, max_elevation - 1):
			candidates.append(cell)
	candidates.shuffle()

	var made := 0
	for source in candidates:
		if made >= river_count:
			break
		if _carve_river(source):
			made += 1


func _carve_river(source: HexCell) -> bool:
	var current := source
	var visited := {}
	var steps := 0
	var max_steps := 64

	while steps < max_steps:
		visited[current] = true
		steps += 1

		# Collect valid downhill/flat neighbors
		var options: Array = []  # [neighbor, dir]
		for dir in range(6):
			var n: HexCell = current.get_neighbor(dir)
			if n == null or visited.has(n):
				continue
			if n.elevation <= current.elevation:
				# Don't flow back into an existing river edge
				if current.has_river_through_edge(dir):
					continue
				options.append([n, dir])

		if options.is_empty():
			return steps > 2  # accept short rivers if they reach somewhere

		var pick: Array = options[_rng.randi() % options.size()]
		var neighbor: HexCell = pick[0]
		var dir: int = pick[1]

		# Outgoing river from current toward dir
		current.has_outgoing_river = true
		current.outgoing_river = dir
		neighbor.has_inccoming_river = true
		neighbor.incoming_river = Enums.opposite(dir)

		# Rivers remove roads on that edge
		current.roads[dir] = false
		neighbor.roads[Enums.opposite(dir)] = false

		if neighbor.is_underwater:
			return true

		current = neighbor

	return true


func _create_roads(grid: HexGrid) -> void:
	for cell in grid.cells:
		if cell.is_underwater:
			continue
		if _rng.randf() > road_chance:
			continue

		for dir in range(6):
			var n: HexCell = cell.get_neighbor(dir)
			if n == null or n.is_underwater:
				continue
			if cell.has_river_through_edge(dir):
				continue
			if cell.get_elevation_difference(dir) > 1:
				continue
			# ~50% chance per eligible edge so roads aren't on every side
			if _rng.randf() < 0.5:
				cell.roads[dir] = true
				n.roads[Enums.opposite(dir)] = true
