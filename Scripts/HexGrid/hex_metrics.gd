extends Node
class_name HexMetrics


const outer_radius : float = 1.125;
const inner_radius : float = outer_radius * 0.866025404;
const elevation_step: float = 0.25  

const hex_highlight_texture : Texture2D = preload("res://cell-outline.png")

static var corners : Array[Vector3] = [
	Vector3(0, 0, outer_radius),
	Vector3(inner_radius, 0, 0.5 * outer_radius),
	Vector3(inner_radius, 0, -0.5 * outer_radius),
	Vector3(0, 0, -outer_radius),
	Vector3(-inner_radius, 0, -0.5 * outer_radius),
	Vector3(-inner_radius, 0, 0.5 * outer_radius)
]


static func get_edge_type ( elevation1 : int, elevation2 : int) -> Enums.HexEdgeType:
	if elevation1 == elevation2:
		return Enums.HexEdgeType.Flat

	var delta : int = elevation2 - elevation1
	if delta == 1 or delta == -1:
		return Enums.HexEdgeType.Slope;
	
	return Enums.HexEdgeType.Cliff;
