extends Node
class_name HexCoordinates
var _x : int
var _y : int
var _z : int



@export var x: int:
	get:
		return _x


@export var y: int:
	get:
		return _y


@export var z: int:
	get:
		return _z


func _init(x_value : int, z_value : int) -> void:
	_x = x_value
	_z = z_value


func DistanceTo (other : HexCoordinates) -> int:
	return ((other.x - x if x < other.x else x - other.x) +
	(other.y - y if y < other.y  else y - other.y) +
	( other.z - z if z < other.z else z - other.z)) / 2
