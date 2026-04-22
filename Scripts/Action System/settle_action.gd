extends Action
class_name SettleAction


func get_action_name() -> String: return "SettleAction"

func get_valid_hex_cells(unit : Unit, hex_grid : HexGrid) -> Array[HexCell]:
	var all_cells = hex_grid.get_cells_in_radius(unit.hex_cell, 4, true)
	all_cells.erase(unit.hex_cell)
	
	var valid_cells : Array[HexCell] =[]
	for cell in all_cells:
		var path = hex_grid.find_path(unit.hex_cell, cell, 4)
		if path.is_empty():
			continue
		valid_cells.append(cell)
	return valid_cells


func execute(unit: Unit, action_data : Dictionary):
	var path : Array = action_data.get("path", [])
	var move_action : Action = unit.object_data.try_get_unit_action("MoveAction")
	
	if not move_action:
		push_error("Unit tried to MoveAction but has no move_action!")
		return

	# Chain the actions
	var move_data = move_action.construct_action(unit, action_data.get("target_cell"), GameManager.get_manager("HexGrid"))
	# Execute and await each step sequentially
	await move_action.execute(unit, move_data)
	move_action.action_complete_call(unit, move_data)


func calculate_costs(unit: Unit, action_data : Dictionary) -> Dictionary:
	return {}


func construct_action(unit : Unit, target_cell : HexCell, hex_grid : HexGrid) -> Dictionary:
	var path = hex_grid.find_path(unit.hex_cell, target_cell, 4)
	
	return {
		"unit": unit,
		"target_cell": target_cell,
		"path": path
	}


func _action_complete(unit: Unit, action_data : Dictionary):
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	var team_manager : TeamManager = GameManager.get_manager("TeamManager")
	if not unit_manager or not team_manager:
		return
	
	var team_holder : TeamHolder = team_manager.get_team_holder(unit.team_afliliation)
	unit_manager.remove_unit(unit, team_holder)
