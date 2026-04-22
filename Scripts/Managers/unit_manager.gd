extends Manager
class_name UnitManager

@export var _test_unit_scene : PackedScene

func get_manager_name() -> String: return "UnitManager"

func _setup():
	pass


func _execute():
	var hex_grid : HexGrid = GameManager.get_manager("HexGrid")
	var team_manager : TeamManager = GameManager.get_manager("TeamManager")
	var camera_controller : CameraController = GameManager.get_manager("CameraController")
	var input_manager : InputManager = GameManager.get_manager("InputManager")

	if hex_grid and team_manager and camera_controller and input_manager:
		for i : int in team_manager._teams.keys():
			var hex_cell : HexCell = hex_grid.get_random_cell(true)
			if not hex_cell:
				continue
			var unit : Unit = test_spawn_unit(UnitData.generate_random_unit_data(), hex_cell,i)
			if i == team_manager.player_team and unit:
				input_manager.set_selected_unit(unit)



func test_spawn_unit(unit_data : UnitData, hex_cell: HexCell, team_affiliation : int) -> Unit:
	#if not unit_data:
		#push_error("unit data was null!")
		#return
	
	if not hex_cell:
		push_error("hex cell was null!")
		return null
	
	if not _test_unit_scene:
		push_error("_test_unit_scene was null!")
		return null
	
	var team_manager : TeamManager = GameManager.get_manager("TeamManager")
	if not team_manager:
		push_error("team_manager was null!")
		return null
	
	var team : TeamHolder = team_manager.get_team_holder(team_affiliation)
	if not team:
		push_error("team was null!")
		return null
	
	
	var test_unit_node = _test_unit_scene.instantiate()
	var test_unit : Unit = test_unit_node as Unit
	
	if not test_unit:
		push_error("test unit was null")
		return null
	
	test_unit.unit_data = unit_data
	test_unit.setup_call(team)
	hex_cell.try_add_hex_object(test_unit, true )
	return test_unit
