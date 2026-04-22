extends Node
class_name TeamHolder


var team_number : int = -1
@export var team_name : String

@export var _active_units : Array[Unit] = []


func _init(team : int, team_name : String = "New Team") -> void:
	team_number = team
	self.team_name = team_name


func add_unit(unit : Unit):
	if not unit:
		push_error("Unit was null")
		return
	
	if _active_units.has(unit):
		push_error("Unit already in team!")
		return
	
	unit.team_afliliation = team_number
	_active_units.append(unit)
	add_child(unit)

func remove_unit(unit: Unit):
	if not _active_units.has(unit):
		return
	
	_active_units.erase(unit)
	unit.queue_free()
