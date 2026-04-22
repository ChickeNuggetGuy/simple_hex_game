extends Manager
class_name  UnitActionManager


var selected_action : Action


signal selected_action_changed(current_action : Action)
signal action_completed(completed_action : Action)

func get_manager_name() -> String: return "UnitActionManager"


func _setup():
	pass


func _execute():
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	
	if not unit_manager or unit_manager.get_selected_unit() == null:
		return
	
	if not unit_manager.selected_unit_changed.is_connected(unit_manager_selected_unit_changed):
		unit_manager.selected_unit_changed.connect(unit_manager_selected_unit_changed)
	
	
	unit_manager_selected_unit_changed(unit_manager.get_selected_unit(), null)




func execute_action(unit : Unit, target_cell : HexCell, action : Action):
	if _is_busy: return 
	
	if not can_execute_action(unit, target_cell, action):
		return
	
	var hex_grid : HexGrid = GameManager.get_manager("HexGrid")
	_is_busy = true
	
	# Construct the data
	var action_data : Dictionary = action.construct_action(unit, target_cell, hex_grid)
	
	# Execute 
	await action.execute(unit, action_data)
	
	# Finalize
	action_completed_call(action, unit, action_data)
	_is_busy = false

func action_completed_call(action : Action, unit : Unit, action_data : Dictionary):
	var hex_grid : HexGrid = GameManager.get_manager("HexGrid")
	
	action.action_complete_call(unit, action_data)
	
	action_completed.emit(action)
	
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	if not is_instance_valid(unit) or unit.is_queued_for_deletion():
		# If the unit is gone, clear highlights and stop.
		hex_grid.clear_highlighted_cells()
		selected_action = null 
		return

	# 3. Only highlight if this unit is still the active, selected unit
	if unit_manager.get_selected_unit() == unit:
		highlight_action_cells(unit, action, hex_grid)
	else:
		hex_grid.clear_highlighted_cells()

func can_execute_action(unit : Unit, target_cell : HexCell, action : Action) -> bool:
	if not unit:
		push_error("Unit is null!")
		return false
	
	if not target_cell:
		push_error("target_cell is null!")
		return false
	
	if not action:
		push_error("action is null!")
		return false
	
	var hex_grid : HexGrid  = GameManager.get_manager("HexGrid")
	if not hex_grid:
		push_error("Hex grid null!")
		return false
	
	var valid_cells : Array[HexCell] = action.get_valid_hex_cells(unit, hex_grid)
	print(str(valid_cells.size()))
	if valid_cells.is_empty() or not valid_cells.has(target_cell):
		print("Target Cell not valid")
		return false
	
	
	#TODO Check any action Costs!
	return true



func set_selected_action(action : Action):
	var hex_grid : HexGrid = GameManager.get_manager("HexGrid")
	
	if action == null:
		hex_grid.clear_highlighted_cells()
		return
	
	if selected_action == action:
		return
	
	
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	if not unit_manager:
		push_error("Unit manager not found!")
		return
	
	var selected_unit : Unit = unit_manager.get_selected_unit()
	if not selected_unit:
		push_error("Unit not found!")
		return
	
	print("Set selected action")
	selected_action = action
	selected_action_changed.emit(selected_action)
	highlight_action_cells(selected_unit, action,GameManager.get_manager("HexGrid"))


func highlight_action_cells(unit : Unit, action : Action, hex_grid : HexGrid):
	# If anything is missing, clear the grid and exit
	if not action or not unit or not hex_grid or unit.is_queued_for_deletion():
		if hex_grid:
			hex_grid.clear_highlighted_cells()
		return
	
	var valid_cells = action.get_valid_hex_cells(unit, hex_grid)
	
	# Always clear old highlights before drawing new ones
	hex_grid.clear_highlighted_cells() 
	
	if not valid_cells.is_empty():
		hex_grid.highlight_cells(valid_cells, Color.WHITE, true)


func unit_manager_selected_unit_changed(new_unit : Unit, old_unit : Unit):
	if new_unit == null:
		set_selected_action(null)
		return
	if not new_unit.object_data is UnitData:
		return
	var unit_data : UnitData = new_unit.object_data as UnitData
	var action : Action = unit_data.try_get_unit_action("MoveAction")

	if action:
		print("AAAHAHAH")
		set_selected_action(action)
