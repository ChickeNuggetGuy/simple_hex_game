extends Manager
class_name InputManager

const RAY_LENGTH = 1000.0

@export var coordinates_label: Label3D
@export var unit_data : UnitData

@export var unit_speed : int = 24 

var selected_cell : HexCell
var from_cell : HexCell

var shift_pressed : bool = false



func get_manager_name() -> String: return "InputManager"

func _execute():
	pass

func _setup():
	if not coordinates_label:
		coordinates_label = Label3D.new()
		add_child(coordinates_label)
		coordinates_label.transform.origin.y = 0.5
		coordinates_label.rotation_degrees.x = -90
		coordinates_label.font_size = 32

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var hex_grid: HexGrid = GameManager.get_manager("HexGrid")
		if not hex_grid: return

		# 1. RAYCAST
		var result = _perform_raycast(event.position)
		
		# 2. LEFT CLICK: Selection
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(result, hex_grid)
			
		# 3. RIGHT CLICK: Pathfinding
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(result, hex_grid)


func _handle_left_click(result: Dictionary, hex_grid: HexGrid):
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	var team_manager : TeamManager = GameManager.get_manager("TeamManager")
	var action_manager : UnitActionManager = GameManager.get_manager("UnitActionManager")
	
	if result.is_empty(): return

	# 1. Handle clicking on a UNIT
	if result.collider is Unit:
		var unit : Unit = result.collider
		if unit_manager and team_manager:
			if unit.team_afliliation == team_manager.player_team:
				unit_manager.set_selected_unit(unit)
		return

	# 2. Handle clicking on a CELL
	var cell : HexCell = hex_grid.get_cell_from_position(result.position)
	if cell:
		selected_cell = cell # Update the stored selected cell
		
		# CHECK FOR ACTION EXECUTION IMMEDIATELY
		if unit_manager and action_manager:
			var selected_unit = unit_manager.get_selected_unit()
			var selected_action = action_manager.selected_action
			
			if selected_unit and selected_action:
				# If we have a unit and an action ready, execute it on this cell NOW
				action_manager.execute_action(selected_unit, cell, selected_action)
			else:
				# Otherwise, just highlight the cell as usual
				for c in hex_grid.cells:
					c.disable_highlight()
				set_selected_cell(hex_grid, cell)


func _handle_right_click(result: Dictionary, hex_grid: HexGrid):
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	var team_manager : TeamManager = GameManager.get_manager("TeamManager")
	if not team_manager:
		push_error("team manager not found!")
		return
	if unit_manager and unit_manager.get_selected_unit() == null:
		print("No unit selected to find a path for.")
		return
	
	if unit_manager and unit_manager.get_selected_unit().team_afliliation != team_manager.player_team:
		print("No player unit selected to find a path for." + str(unit_manager.get_selected_unit().team_afliliation )
		+ str( team_manager.player_team))
		return	

	if not result.is_empty():
		var target_cell := hex_grid.get_cell_from_position(result.position)
		var start_cell := unit_manager.get_selected_unit().hex_cell
		
		if target_cell and start_cell:
			hex_grid.find_path(
				start_cell, 
				target_cell, 
				unit_manager.get_selected_unit().unit_data.move_speed
			)
			
			# Update UI
			coordinates_label.text = "Target: %d, %d\nTurns: %d" % [
				target_cell.coordinates.x, 
				target_cell.coordinates.z,
				(target_cell.distance / unit_manager.get_selected_unit().unit_data.move_speed) + 1
			]
			coordinates_label.global_position = target_cell.world_position

func _perform_raycast(mouse_pos: Vector2) -> Dictionary:
	var camera_controller : CameraController = GameManager.get_manager("CameraController")
	var camera3d = camera_controller.main_camera
	var space_state = get_tree().root.get_world_3d().direct_space_state
	
	var from = camera3d.project_ray_origin(mouse_pos)
	var to = from + camera3d.project_ray_normal(mouse_pos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# Ensure the ray can hit the Unit's collision shape
	query.collide_with_bodies = true
	
	return space_state.intersect_ray(query)


func set_selected_cell(hex_grid : HexGrid,value : HexCell):
	selected_cell = value
	if selected_cell:
		selected_cell.enable_highlight(hex_grid, Color.WHITE)
