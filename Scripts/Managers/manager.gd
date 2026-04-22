@abstract 
extends Node
class_name Manager

var _is_busy : bool = false

signal is_busy_changed(value : bool)

func _init() -> void:
	add_to_group("managers")

func setup_call():
	_is_busy = true
	await _setup()
	_is_busy = false


func execute_call():
	_is_busy = true
	await _execute()
	_is_busy = false

@abstract func get_manager_name() -> String
@abstract func _setup()
@abstract func _execute()



func get_is_busy() -> bool: return _is_busy


func set_is_busy(value : bool):
	if _is_busy == value:
		return
	
	_is_busy = value
	is_busy_changed.emit(_is_busy)
