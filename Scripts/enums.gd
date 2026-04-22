extends Node
class_name Enums

enum HexDirection {
	NE, E, SE, SW, W, NW
}

static func opposite (direction :  HexDirection ) -> HexDirection:
	return (direction + 3) if direction < 3  else (direction - 3);




enum HexEdgeType {
	Flat, Slope, Cliff
}
