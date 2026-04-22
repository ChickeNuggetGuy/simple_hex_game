@abstract
extends AnimatableBody3D
class_name HexObject

@export var visual : Node3D
@export var team_afliliation : int
@export var object_data : HexObjectData

var _hex_cell : HexCell
var hex_cell : HexCell:
	get:
		return _hex_cell
	set(value):
		set_hex_cell(value, true)


signal hex_cell_changed(hex_cell : HexCell)

func setup_call(team : TeamHolder):
	team.add_unit(self)
	
	for comp in object_data.components:
		comp.setup_call(self)
	_setup()


@abstract func _setup()


func set_hex_cell(value : HexCell, update_position : bool):
	_hex_cell = value
	position = hex_cell.world_position
	
	hex_cell_changed.emit(_hex_cell)
