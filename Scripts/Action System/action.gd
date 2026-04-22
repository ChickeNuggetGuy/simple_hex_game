@abstract
extends Resource
class_name Action

@export var show_in_ui : bool = true
var sub_actions : Array[Dictionary] = [] 

@abstract func get_action_name() -> String
@abstract func get_valid_hex_cells(unit : Unit, hex_grid : HexGrid) -> Array[HexCell]
@abstract func execute(unit: Unit, action_data : Dictionary)
@abstract func calculate_costs(unit: Unit, action_data : Dictionary) -> Dictionary
@abstract func construct_action(unit : Unit, target_cell : HexCell, hex_grid : HexGrid) -> Dictionary


func action_complete_call(unit: Unit, action_data : Dictionary):
	sub_actions.clear()
	_action_complete(unit, action_data)

@abstract func _action_complete(unit: Unit, action_data : Dictionary)
