extends Manager
class_name UnitManager

@export var unit_scene : PackedScene
@export var test_unit_data : UnitData 

var _selected_unit : Unit

signal selected_unit_changed(new_unit : Unit, old_unit : Unit)

func get_manager_name() -> String: return "UnitManager"

func _setup():
	pass


func _execute():
	var hex_grid : HexGrid = GameManager.get_manager("HexGrid")
	var team_manager : TeamManager = GameManager.get_manager("TeamManager")
	var camera_controller : CameraController = GameManager.get_manager("CameraController")
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	
	if test_unit_data == null:
		push_error("UnitManager: test_unit_data is null. Check the Inspector!")
		return

	if hex_grid and team_manager and camera_controller and unit_manager:
		for i : int in team_manager._teams.keys():
			var hex_cell : HexCell = hex_grid.get_random_cell(true)
			if not hex_cell:
				continue
			var unit : Unit = test_spawn_unit(test_unit_data.duplicate(true) as UnitData, hex_cell, i)			
			if i == team_manager.player_team and unit:
				unit_manager.set_selected_unit(unit)



func test_spawn_unit(unit_data : UnitData, hex_cell: HexCell, team_affiliation : int) -> Unit:
	#if not unit_data:
		#push_error("unit data was null!")
		#return
	
	if not hex_cell:
		push_error("hex cell was null!")
		return null
	
	if not unit_data:
		push_error("unit_data was null!")
		return null
	
	var team_manager : TeamManager = GameManager.get_manager("TeamManager")
	if not team_manager:
		push_error("team_manager was null!")
		return null
	
	var team : TeamHolder = team_manager.get_team_holder(team_affiliation)
	if not team:
		push_error("team was null!")
		return null
	
	
	var test_unit_node =	unit_scene.instantiate()
	var test_unit : Unit = test_unit_node as Unit
	
	if not test_unit:
		push_error("test unit was null")
		return null
	
	test_unit.object_data = unit_data
	test_unit.setup_call(team)
	hex_cell.try_add_hex_object(test_unit, true )
	return test_unit


func remove_unit(unit : Unit, team_holder : TeamHolder):
	if not unit:
		return
	
	if not team_holder:
		push_error("team_holder is null!")
		return
	
	if unit == get_selected_unit():
		set_selected_unit(null)
	
	team_holder.remove_unit(unit)

func get_selected_unit() -> Unit: return _selected_unit

func set_selected_unit(unit : Unit):
	var old_unit : Unit = _selected_unit
	if unit:
		print("Selected unit: ", unit.object_data.object_name)
	_selected_unit = unit
	selected_unit_changed.emit(_selected_unit, old_unit)
