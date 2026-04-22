extends Node3D
class_name HexFeatureManager

## Scenes for different feature types. 
## Assign multiple variations in the inspector for variety.
@export_group("Feature Collections")
@export var urban_prefabs: Array[PackedScene] = []
@export var farm_prefabs: Array[PackedScene] = []
@export var plant_prefabs: Array[PackedScene] = []

## How far from the center features can spawn (0.0 to 1.0)
@export var spawn_radius: float = 0.6

var feature_container: Node3D

func _init() -> void:
	name = "Feature Manager"
	# Ensure container exists at start
	_create_container()

func clear() -> void:
	if feature_container:
		feature_container.queue_free()
	_create_container()

func _create_container() -> void:
	feature_container = Node3D.new()
	add_child(feature_container)
	feature_container.name = "Feature_Container"

## The main entry point called by HexGridChunk during build()
func add_feature(cell: HexCell) -> void:
	# Don't place features in water
	if cell.is_underwater:
		return

	# Urban features take priority, then Farm, then Plants
	if cell.urban_level > 0:
		_spawn_feature_collection(cell, urban_prefabs, cell.urban_level)
	elif cell.farm_level > 0:
		_spawn_feature_collection(cell, farm_prefabs, cell.farm_level)
	elif cell.plant_level > 0:
		_spawn_feature_collection(cell, plant_prefabs, cell.plant_level)

## Iterates based on the 'level' and attempts to find safe spots
func _spawn_feature_collection(cell: HexCell, prefabs: Array[PackedScene], level: int) -> void:
	if prefabs.is_empty():
		return

	# Level 1 spawns 1 object, Level 2 spawns 2, Level 3 spawns 3
	for i in range(level):
		var prefab = prefabs.pick_random()
		
		# Pick a random offset within the hex
		var attempt_limit = 5
		var placed = false
		
		for attempt in range(attempt_limit):
			var offset = _get_random_offset()
			
			if _is_position_safe(cell, offset):
				_instance_feature(prefab, cell.world_position + offset)
				placed = true
				break

func _instance_feature(prefab: PackedScene, world_pos: Vector3) -> void:
	var instance = prefab.instantiate() as Node3D
	feature_container.add_child(instance)
	instance.global_position = world_pos
	
	# Give it a random rotation for natural looks
	instance.rotation.y = randf_range(0, TAU)
	
	# Small random scale variation
	var s = randf_range(0.9, 1.1)
	instance.scale = Vector3(s, s, s)

## Helper to get a random point inside the hex radius
func _get_random_offset() -> Vector3:
	var angle = randf_range(0, TAU)
	var distance = randf_range(0, HexMetrics.inner_radius * spawn_radius)
	return Vector3(cos(angle) * distance, 0, sin(angle) * distance)

## Logic to ensure we don't spawn on top of roads or rivers
func _is_position_safe(cell: HexCell, offset: Vector3) -> bool:
	# Convert the local offset angle into a HexDirection (0-5)
	# atan2 returns -PI to PI
	var angle = atan2(offset.x, offset.z) 
	
	# Map angle to the 6 hex directions
	# Direction 0 is typically North/North-East in these coordinate systems
	var dir_index = int(floor(remap(angle, -PI, PI, 0, 6))) % 6
	var direction = dir_index as Enums.HexDirection
	
	# Check if the cell has a road or river in this specific wedge of the hex
	if cell.has_road_through_edge(direction):
		return false
	if cell.has_river_through_edge(direction):
		return false
		
	return true

## Required by your existing Chunk logic
func apply() -> void:
	# Currently we instantiate immediately, so apply is just a placeholder
	pass
