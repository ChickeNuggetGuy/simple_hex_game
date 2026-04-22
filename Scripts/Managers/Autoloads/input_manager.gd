extends Manager
class_name InputManager

const RAY_LENGTH = 1000.0

@export var coordinates_label: Label3D
@export var unit_data : UnitData

@export var unit_speed : int = 24 

var _selected_unit: Unit = null
var selected_cell : HexCell
var from_cell : HexCell

var shift_pressed : bool = false

signal selected_unit_changed(selected_unit : Unit)

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
	# If we hit a Unit (or a HexObject that is a Unit)
	if not result.is_empty() and result.collider is Unit:
		set_selected_unit(result.collider)
		var start_cell = hex_grid.get_cell_from_position(_selected_unit.global_position)
		
		# Optional: Highlight the movement range immediately upon selection
		hex_grid.search(start_cell, null, _selected_unit.unit_data.move_speed)
		
		
	else:
		# Clicked empty space or non-unit: Deselect
		set_selected_unit(null)
		# Clear highlights
		for cell in hex_grid.cells:
			cell.disable_highlight()

func _handle_right_click(result: Dictionary, hex_grid: HexGrid):
	var team_manager : TeamManager = GameManager.get_manager("TeamManager")
	if not team_manager:
		push_error("team manager not found!")
		return
	if _selected_unit == null:
		print("No unit selected to find a path for.")
		return
	
	if _selected_unit.team_afliliation != team_manager.player_team:
		print("No player unit selected to find a path for." + str(_selected_unit.team_afliliation )
		+ str( team_manager.player_team))
		return	

	if not result.is_empty():
		var target_cell := hex_grid.get_cell_from_position(result.position)
		var start_cell := _selected_unit.hex_cell
		
		if target_cell and start_cell:
			hex_grid.find_path(
				start_cell, 
				target_cell, 
				_selected_unit.unit_data.move_speed
			)
			
			# Update UI
			coordinates_label.text = "Target: %d, %d\nTurns: %d" % [
				target_cell.coordinates.x, 
				target_cell.coordinates.z,
				(target_cell.distance / _selected_unit.unit_data.move_speed) + 1
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


func set_selected_unit(unit : Unit):
	if unit:
		print("Selected unit: ", unit.unit_data.object_name)
	_selected_unit = unit
	selected_unit_changed.emit(_selected_unit)
