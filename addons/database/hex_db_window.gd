@tool
extends Control
class_name HexDBWindow

const PREF_DB_PATH := "hex_strategy/last_db_path"

var _database: HexDatabase
var _selected_resource: Resource
var _current_db_path := ""

var _unit_list: ItemList
var _structure_list: ItemList
var _path_label: Label
var _editor_container: VBoxContainer
var _tab_container: TabContainer

func _ready() -> void:
	_layout_ui()
	if ProjectSettings.has_setting(PREF_DB_PATH):
		var last_path = str(ProjectSettings.get_setting(PREF_DB_PATH))
		if FileAccess.file_exists(last_path):
			open_database(last_path)

func _layout_ui() -> void:
	for child in get_children():
		child.queue_free()

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	var toolbar := HBoxContainer.new()
	main_vbox.add_child(toolbar)

	var btn_load := Button.new()
	btn_load.text = "Load DB"
	btn_load.pressed.connect(_on_load_pressed)
	toolbar.add_child(btn_load)

	var btn_rescan := Button.new()
	btn_rescan.text = "Force Rescan Files"
	btn_rescan.modulate = Color.CYAN
	btn_rescan.pressed.connect(_on_force_rescan)
	toolbar.add_child(btn_rescan)

	_path_label = Label.new()
	_path_label.text = "No Database Loaded"
	_path_label.modulate = Color.GRAY
	toolbar.add_child(_path_label)

	var h_split := HSplitContainer.new()
	h_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(h_split)

	_tab_container = TabContainer.new()
	_tab_container.custom_minimum_size = Vector2(350, 0)
	h_split.add_child(_tab_container)

	_unit_list = _create_list_view("Units", "UnitData")
	_structure_list = _create_list_view("Structures", "StructureData")

	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_split.add_child(right_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(scroll)

	_editor_container = VBoxContainer.new()
	_editor_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_editor_container)

	var btn_save := Button.new()
	btn_save.text = "Save Selected Item"
	btn_save.custom_minimum_size = Vector2(0, 40)
	btn_save.pressed.connect(_save_current_resource)
	right_panel.add_child(btn_save)

func _create_list_view(p_name: String, p_base_type: String) -> ItemList:
	var container := VBoxContainer.new()
	container.name = p_name
	_tab_container.add_child(container)

	var btn_add := MenuButton.new()
	btn_add.text = "+ Add New " + p_name
	btn_add.flat = false
	btn_add.get_popup().about_to_popup.connect(_fill_add_menu.bind(btn_add, p_base_type))
	container.add_child(btn_add)

	var list := ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# This ensures the list is actually visible
	list.custom_minimum_size = Vector2(0, 200) 
	list.item_selected.connect(_on_resource_selected.bind(list))
	container.add_child(list)
	return list

func open_database(p_path: String) -> void:
	_database = load(p_path)
	if _database:
		_current_db_path = p_path
		_path_label.text = p_path
		_path_label.modulate = Color.WHITE
		ProjectSettings.set_setting(PREF_DB_PATH, p_path)
		ProjectSettings.save()
		_on_force_rescan()

func _on_force_rescan() -> void:
	if _database:
		_database.populate_all()
		# Critical: Save the database so the changes persist
		ResourceSaver.save(_database, _current_db_path) 
		refresh_lists()

func refresh_lists() -> void:
	if not _database: return
	
	print("[HexUI] Refreshing lists. Unit count in DB: ", _database.units.size())
	
	_unit_list.clear()
	var u_keys = _database.units.keys()
	u_keys.sort()
	for id in u_keys:
		var u = _database.units[id]
		if u:
			var d_name = u.object_name if not u.object_name.is_empty() else u.resource_path.get_file()
			var idx = _unit_list.add_item(d_name)
			_unit_list.set_item_metadata(idx, u)

	_structure_list.clear()
	var s_keys = _database.structures.keys()
	s_keys.sort()
	for id in s_keys:
		var s = _database.structures[id]
		if s:
			var d_name = s.object_name if not s.object_name.is_empty() else s.resource_path.get_file()
			var idx = _structure_list.add_item(d_name)
			_structure_list.set_item_metadata(idx, s)

func _on_resource_selected(p_index: int, p_list: ItemList) -> void:
	_selected_resource = p_list.get_item_metadata(p_index)
	for child in _editor_container.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "Editing: " + _selected_resource.resource_path.get_file()
	header.modulate = Color.GOLD
	_editor_container.add_child(header)

	EditorInterface.edit_resource(_selected_resource)

func _save_current_resource() -> void:
	if _selected_resource:
		ResourceSaver.save(_selected_resource)
		_on_force_rescan()

func _fill_add_menu(p_menu_btn: MenuButton, p_base_type: String) -> void:
	var popup = p_menu_btn.get_popup()
	popup.clear()
	var all_classes = ProjectSettings.get_global_class_list()
	var filtered = []
	for c in all_classes:
		if _is_type_of(c["class"], p_base_type):
			filtered.append(c)
	for i in range(filtered.size()):
		popup.add_item(filtered[i]["class"])
	for connection in popup.id_pressed.get_connections():
		popup.id_pressed.disconnect(connection.callable)
	popup.id_pressed.connect(func(id: int): _create_new_resource(filtered[id]["class"], p_base_type))

func _create_new_resource(p_target_class: String, p_base_type: String) -> void:
	if not _database: return
	var script_path := ""
	for c in ProjectSettings.get_global_class_list():
		if c["class"] == p_target_class:
			script_path = c["path"]
			break
	if script_path.is_empty(): return
	var res = load(script_path).new()
	var folder = _database.unit_directory if p_base_type == "UnitData" else _database.structure_directory
	var f_name = "New_" + p_target_class + "_" + str(Time.get_ticks_msec()) + ".tres"
	var full_path = folder.path_join(f_name)
	ResourceSaver.save(res, full_path)
	_on_force_rescan()

func _is_type_of(p_current: String, p_base: String) -> bool:
	if p_current == p_base: return true
	var class_list = ProjectSettings.get_global_class_list()
	var check_name = p_current
	while not check_name.is_empty():
		var found_parent := false
		for c in class_list:
			if c["class"] == check_name:
				if c["base"] == p_base: return true
				check_name = c["base"]
				found_parent = true
				break
		if not found_parent or check_name == "Resource": break
	return false

func _on_load_pressed() -> void:
	var fd = EditorFileDialog.new()
	fd.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	fd.access = EditorFileDialog.ACCESS_RESOURCES
	fd.filters = PackedStringArray(["*.tres", "*.res"])
	fd.file_selected.connect(open_database)
	add_child(fd)
	fd.popup_centered_ratio(0.5)
