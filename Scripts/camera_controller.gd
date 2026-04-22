extends Manager
class_name CameraController

@export var main_camera : Camera3D
@export var transposer : Node3D
@export var camera_dictionary : Dictionary[String, PhantomCamera3D]

@export var move_speed: float = 10.0

@export var zoom_speed : float = 3
@export var min_follow_offset : Vector3
@export var max_follow_offset : Vector3
@export var zoom_smoothing: float = 8.0

var target_follow_offset: Vector3
var orbit_yaw_deg: float = 0.0
var orbit_pitch_deg: float = -25.0
var orbit_distance: float = 8.0


func get_manager_name() -> String: return "CameraController"

func _setup():
	var main_phantom_camera: PhantomCamera3D = camera_dictionary.get("main")
	if main_phantom_camera:
		target_follow_offset = main_phantom_camera.follow_offset

func _execute():
	var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
	if unit_manager and not unit_manager.selected_unit_changed.is_connected(selected_unit_changed):
		unit_manager.selected_unit_changed.connect(selected_unit_changed)
		


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == Key.KEY_F:
			var unit_manager : UnitManager = GameManager.get_manager("UnitManager")
			if unit_manager and unit_manager.get_selected_unit():
				focus_hex_object(unit_manager.get_selected_unit())

func _physics_process(delta: float) -> void:
	_transposer_movement(delta)
	_transposer_zoom(delta)


func _transposer_movement(delta : float):
	var move_dir := Vector3.ZERO

	var yaw_rad := deg_to_rad(orbit_yaw_deg)
	var forward := -Vector3.FORWARD.rotated(Vector3.UP, yaw_rad)
	var right := Vector3.RIGHT.rotated(Vector3.UP, yaw_rad)

	if Input.is_action_pressed("camera_right"):
		move_dir += right
	if Input.is_action_pressed("camera_left"):
		move_dir -= right
	if Input.is_action_pressed("camera_forward"):
		move_dir -= forward
	if Input.is_action_pressed("camera_backward"):
		move_dir += forward

	if move_dir != Vector3.ZERO:
		transposer.position += move_dir.normalized() * move_speed * delta


func _transposer_zoom(delta: float):
	var zoom_input = Input.get_axis( "camera_zoom_in","camera_zoom_out")

	if zoom_input != 0:
		if Input.is_action_pressed("shift_held"):
			target_follow_offset.y += zoom_input * zoom_speed * delta
			target_follow_offset.y = clampf(
				target_follow_offset.y,
				min_follow_offset.y,
				max_follow_offset.y
			)
		else:
			target_follow_offset.z += zoom_input * zoom_speed * delta
			target_follow_offset.z = clampf(
				target_follow_offset.z,
				min_follow_offset.z,
				max_follow_offset.z
			)

	var main_phantom_camera: PhantomCamera3D = camera_dictionary.get("main")
	if main_phantom_camera:
		main_phantom_camera.follow_offset = main_phantom_camera.follow_offset.lerp(
			target_follow_offset, 1.0 - exp(-zoom_smoothing * delta)
		)


func focus_hex_object(object : HexObject):
	if not object:
		return
	
	transposer.position = object.hex_cell.world_position


func selected_unit_changed(unit : Unit, old_unit : Unit ):
	if unit:
		focus_hex_object(unit)
