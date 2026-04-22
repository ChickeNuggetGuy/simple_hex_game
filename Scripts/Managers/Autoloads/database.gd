@tool
extends Resource
class_name HexDatabase

@export_group("Paths")
@export_dir var unit_directory: String = "res://Data/Units/"
@export_dir var structure_directory: String = "res://Data/Structures/"

@export_group("Data Storage")
@export var units: Dictionary[int, UnitData] = {}
@export var structures: Dictionary[int, StructureData] = {}

func populate_all() -> void:
	print("[HexDatabase] Rescan started with ID assignment...")
	_scan_folder(unit_directory, units, "UnitData")
	_scan_folder(structure_directory, structures, "StructureData")
	emit_changed()
	print("[HexDatabase] Rescan finished. All IDs synced.")

func _scan_folder(path: String, dict: Dictionary, target_type: String) -> void:
	dict.clear()
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
		return

	var dir = DirAccess.open(path)
	if not dir: return

	# 1. Collect all valid resource paths
	var file_paths: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			file_paths.append(path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	# 2. SORT Alphabetically to ensure consistent ID mapping across all machines
	file_paths.sort()

	# 3. Load and assign IDs
	for i in range(file_paths.size()):
		var full_path = file_paths[i]
		var res = ResourceLoader.load(full_path, "", ResourceLoader.CACHE_MODE_REPLACE)
		
		if _is_matching_type(res, target_type):
			# If the ID is wrong or unassigned, update and save the resource file
			if res.object_id != i:
				res.object_id = i
				ResourceSaver.save(res, full_path)
				print("  -> Fixed ID for: ", file_name, " to ", i)
			
			dict[i] = res

func _is_matching_type(res: Resource, type_name: String) -> bool:
	if not res: return false
	var script = res.get_script()
	if not script: return false
	
	var current_script = script
	while current_script:
		if current_script.get_global_name() == type_name:
			return true
		current_script = current_script.get_base_script()
	
	return res.is_class(type_name)
