extends Action
class_name MoveStepAction

func get_action_name() -> String: return "MoveStepAction"

func get_valid_hex_cells(unit : Unit, hex_grid : HexGrid) -> Array[HexCell]:
	return hex_grid.get_cells_in_radius(unit.hex_cell, 1, true)

func execute(unit: Unit, action_data : Dictionary):
	var target_cell = action_data.get("target_cell")
	var tween = unit.get_tree().create_tween()
	# Update visual position
	tween.tween_property(unit, "position", target_cell.world_position, 0.2)
	await tween.finished
	# Logic update
	unit.set_hex_cell(target_cell, true)

func construct_action(unit : Unit, target_cell : HexCell, hex_grid : HexGrid) -> Dictionary:
	return { "unit": unit, "target_cell": target_cell }

func _action_complete(unit: Unit, action_data : Dictionary):
	pass


func calculate_costs(unit: Unit, action_data : Dictionary) -> Dictionary:
	return {}
