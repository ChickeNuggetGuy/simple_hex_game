extends Node3D
class_name HexGridChunk

var cells: Array[HexCell] = []
var cell_dictionary: Dictionary
var multi_mesh_instances: Dictionary = {}


var features: HexFeatureManager 

const _ROAD_PATTERNS: Array = [
	# [mask, type_suffix]
	[0b000001, "road_1"],             # single edge at dir 0
	[0b001001, "road_2_straight"],    # 0 and 3 (opposite)
	[0b000011, "road_2_sharp"],       # 0 and 1 (adjacent)
	[0b000101, "road_2_curve"],       # 0 and 2 (skip one)
	[0b010101, "road_3_y"],           # 0, 2, 4 (every other)
	[0b001011, "road_3_t"],           # 0, 1, 3
	[0b000111, "road_3_k"],           # 0, 1, 2 (three adjacent)
	[0b011011, "road_4_x"],           # 0,1,3,4
	[0b010111, "road_4_y"],           # 0,1,2,4
	[0b001111, "road_4_z"],           # 0,1,2,3 (four adjacent) <- missing
	[0b011111, "road_5"],             # missing dir 5
	[0b111111, "road_6"],             # all
]

# Rotate a 6-bit mask left by r (wrapping).
static func _rotate_mask(mask: int, r: int) -> int:
	r = r % 6
	return ((mask << r) | (mask >> (6 - r))) & 0b111111

# Given a road mask, return { "type": String, "rotation": int } or null if no roads.
func _road_pattern(mask: int) -> Dictionary:
	if mask == 0:
		return {}
	for entry in _ROAD_PATTERNS:
		var base_mask: int = entry[0]
		var suffix: String = entry[1]
		for r in range(6):
			if _rotate_mask(base_mask, r) == mask:
				return {"type": suffix, "rotation": r}
	# Shouldn't happen if patterns cover all 63 nonzero masks, but just in case:
	push_warning("No road pattern found for mask %d" % mask)
	return {"type": "road_1", "rotation": 0}



func _init(cell_dict: Dictionary) -> void:
	if not features:
		features = HexFeatureManager.new()
		add_child(features)
	features.clear()
	cell_dictionary = cell_dict

func add_cell(cell: HexCell) -> void:
	cell.set_chunk(self)
	cells.append(cell)
	add_child(cell)


func build() -> void:

	for mmi in multi_mesh_instances.values():
		mmi.queue_free()
	multi_mesh_instances.clear()

	# Bucket by (type, rotation). Key is "type|rotation".
	var buckets: Dictionary = {}
	for cell in cells:
		var info := _classify(cell)
		var type: StringName = info.type
		var rotation: int = info.rotation
		var key := "%s|%d" % [type, rotation]
		if not buckets.has(key):
			buckets[key] = {"type": type, "rotation": rotation, "cells": []}
		buckets[key].cells.append(cell)

	for key in buckets.keys():
		var bucket: Dictionary = buckets[key]
		var type: StringName = bucket.type
		var rotation: int = bucket.rotation
		var bucket_cells: Array = bucket.cells

		if not cell_dictionary.has(type):
			push_warning("No mesh for terrain type: %s" % type)
			continue

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = cell_dictionary[type]
		mm.instance_count = bucket_cells.size()

		var rot_basis := Basis(Vector3.UP, deg_to_rad(rotation * 60.0))
		for i in bucket_cells.size():
			var t := Transform3D()
			t.basis = rot_basis
			t.origin = bucket_cells[i].position
			mm.set_instance_transform(i, t)

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)
		multi_mesh_instances[key] = mmi
	# Clear existing features
	features.clear()

	# Add features for each cell
	for cell in cells:
		features.add_feature(cell)
	
	features.apply()

func _classify(cell: HexCell) -> Dictionary:
	var biome: StringName = cell.terrain_type

	if cell.is_underwater:
		return {"type": &"water", "rotation": 0}

	# Rivers
	if cell.has_river:
		var in_dir: int = cell.incoming_river if cell.has_inccoming_river else -1
		var out_dir: int = cell.outgoing_river if cell.has_outgoing_river else -1

		if cell.has_river_begin_or_end:
			var d: int = in_dir if in_dir != -1 else out_dir
			return {"type": _k(biome, "river_end"), "rotation": d}

		var diff: int = (out_dir - in_dir + 6) % 6
		match diff:
			3:
				return {"type": _k(biome, "river_straight"), "rotation": in_dir % 3}
			1, 5:
				return {"type": _k(biome, "river_sharp"), "rotation": in_dir}
			2, 4:
				return {"type": _k(biome, "river_curve"), "rotation": in_dir}

	# Roads
	if cell.has_roads:
		var mask := 0
		for d in range(6):
			if cell.roads[d]:
				mask |= 1 << d
		var info := _road_pattern(mask)
		return {"type": _k(biome, info.type), "rotation": info.rotation}

	# Plain
	return {"type": biome, "rotation": 0}


func _k(biome: StringName, suffix: String) -> StringName:
	return StringName("%s_%s" % [biome, suffix])



func refresh() -> void:
	build()
