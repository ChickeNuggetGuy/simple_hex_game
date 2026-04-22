extends Action
class_name MoveAction

@export var move_speed : int = 25

func get_action_name() -> String: return "MoveAction"

func get_valid_hex_cells(unit : Unit, hex_grid : HexGrid) -> Array[HexCell]:
	var all_cells = hex_grid.get_cells_in_radius(unit.hex_cell, move_speed / 5, true)
	all_cells.erase(unit.hex_cell)
	
	var valid_cells : Array[HexCell] =[]
	for cell in all_cells:
		var path = hex_grid.find_path(unit.hex_cell, cell, move_speed)
		if path.is_empty():
			continue
		valid_cells.append(cell)
	return valid_cells

func execute(unit: Unit, action_data : Dictionary):
	var path : Array = action_data.get("path", [])
	var step_action : Action = unit.object_data.try_get_unit_action("MoveStepAction")
	
	if not step_action:
		push_error("Unit tried to MoveAction but has no MoveStepAction!")
		return

	# Chain the actions
	for cell in path:
		# We construct the data for the sub-action
		var step_data = step_action.construct_action(unit, cell, GameManager.get_manager("HexGrid"))
		# Execute and await each step sequentially
		await step_action.execute(unit, step_data)
		step_action.action_complete_call(unit, step_data)

func construct_action(unit : Unit, target_cell : HexCell, hex_grid : HexGrid) -> Dictionary:
	var path = hex_grid.find_path(unit.hex_cell, target_cell, move_speed)
	return {
		"unit": unit,
		"target_cell": target_cell,
		"path": path
	}

func _action_complete(unit: Unit, action_data : Dictionary):
	pass


func calculate_costs(unit: Unit, action_data : Dictionary) -> Dictionary:
	return {}
