extends Node3D
class_name HexCell


var terrain_type: StringName = &"base_cell"
var coordinates: HexCoordinates
var is_underwater : bool:
	get:
		return terrain_type == "water"

var _path_from: HexCell

var path_from: HexCell:
	get:
		return _path_from
	set(value):
		_path_from = value


var _elevation: int

var elevation: int:
	get:
		return _elevation
	set(value):
		if _elevation == value:
			return
		_elevation = value

		# Calculate the actual float height
		var vert_height : float = _elevation * HexMetrics.elevation_step
		
		# Update the actual 3D Node position 
		position.y = vert_height
		
		# Update the cached world_position variable
		world_position.y = vert_height

		# River validation
		if has_outgoing_river:
			var out_n := get_neighbor(outgoing_river)
			if out_n and _elevation < out_n.elevation:
				remove_outgoing_river()
		if has_inccoming_river:
			var in_n := get_neighbor(incoming_river)
			if in_n and _elevation > in_n.elevation:
				remove_incoming_river()
		
		for i : int in range(roads.size()):
			if roads[i] and get_elevation_difference(i) > 1:
				set_road(i, false)
				
		if chunk:
			refresh()

var distance: int = -1

var world_position : Vector3

var chunk : HexGridChunk

@export var neighbors : Array[HexCell] = [
	null,null,null,null,null,null
]
@export var hex_highlight : Sprite3D

var turn_label: Label3D

var _urban_level: int
var _farm_level: int
var _plant_level: int

@export_range(0, 3) var urban_level: int:
	get: return _urban_level
	set(v):
		if _urban_level == v: return
		_urban_level = v
		refresh()

@export_range(0, 3) var farm_level: int:
	get: return _farm_level
	set(v):
		if _farm_level == v: return
		_farm_level = v
		refresh()

@export_range(0, 3) var plant_level: int:
	get: return _plant_level
	set(v):
		if _plant_level == v: return
		_plant_level = v
		refresh()

#region River Variables
var _has_incoming_river : bool
var _has_outgoing_river: bool
var _incoming_river : Enums.HexDirection
var _outgoing_river : Enums.HexDirection

var has_inccoming_river : bool :
	get:
		return _has_incoming_river
	set (value):
		_has_incoming_river = value

var has_outgoing_river : bool:
	get:
		return _has_outgoing_river
	set (value):
		_has_outgoing_river = value

var incoming_river : Enums.HexDirection :
	get:
		return _incoming_river
	set (value):
		_incoming_river = value

var outgoing_river : Enums.HexDirection:
	get:
		return _outgoing_river
	set (value):
		_outgoing_river = value

var has_river : bool:
	get:
		return _has_incoming_river or _has_outgoing_river;

var has_river_begin_or_end : bool:
	get:
		return _has_incoming_river != _has_outgoing_river;
#endregion

var roads : Array[bool] = [false,false,false,false,false,false,]

var  has_roads : bool:
		get:
			for i in range(roads.size()):
				if roads[i]:
					return true
			return false


var _walkable : bool = true

var current_hex_objects : Array[HexObject] = []


func setup(x: int, z: int, world_pos: Vector3, elev: int, walkable: bool = true) -> void:
	world_position = world_pos
	var cube_x = x - ((z - (z & 1)) / 2)
	coordinates = HexCoordinates.new(cube_x, z)
	
	name = "Hex Cell (%d,%d)" % [x, z]
	_walkable = walkable
	
	# Set elevation using the setter to trigger position updates
	self.elevation = elev
	
	# hex highlighting setup
	if not hex_highlight:
		hex_highlight = Sprite3D.new()
		add_child(hex_highlight)
	
	if not turn_label:
		turn_label = Label3D.new()
		add_child(turn_label)
	

	turn_label.position = Vector3(0, 0.2, 0) 
	
	hex_highlight.texture = HexMetrics.hex_highlight_texture
	hex_highlight.global_rotation_degrees.x = 90
	hex_highlight.scale = Vector3(0.85, 0.85, 1)
	hex_highlight.position = Vector3(0, 0.1, 0)
	
	disable_highlight()
	
	if not is_underwater and not has_river:
		chunk.features.add_feature(self)


func set_chunk(c : HexGridChunk):
	chunk = c


func refresh():
	chunk.refresh()


func refresh_self_only():
	chunk.refresh()

func get_neighbor (direction : Enums.HexDirection) -> HexCell:
	return neighbors[direction];


func set_neighbor ( direction : Enums.HexDirection, cell: HexCell) -> void:
	neighbors[direction] = cell;
	cell.neighbors[Enums.opposite(direction)] = self;


#region Hex Highlighting
func disable_highlight():
	if hex_highlight:
		hex_highlight.hide()


func enable_highlight(hex_grid : HexGrid, color : Color = Color.WHITE):
	if hex_highlight:
		hex_highlight.modulate = color
		hex_highlight.show()
		
		hex_grid.highlighted_cells.append(self)
#endregion

#region River Functions
func has_river_through_edge (direction : Enums.HexDirection) -> bool:
	return (_has_incoming_river && _incoming_river == direction or
		_has_outgoing_river && _outgoing_river == direction)


func remove_incoming_river () -> void:
	if not has_inccoming_river:
		return

	_has_incoming_river = false;
	refresh_self_only();

	var neighbor : HexCell = get_neighbor(incoming_river);
	neighbor.has_outgoing_river = false;
	neighbor.refresh_self_only();

func remove_outgoing_river ():
	if not has_outgoing_river:
		return
	
	has_outgoing_river = false
	refresh_self_only()

	var neighbor : HexCell = get_neighbor(outgoing_river)
	neighbor.has_inccoming_river = false
	neighbor.refresh_self_only()


func remove_river () -> void:
	remove_outgoing_river()
	remove_incoming_river()


func set_outgoing_river (direction : Enums.HexDirection)-> void:
	if has_outgoing_river and outgoing_river == direction:
		return

	var neighbor : HexCell = get_neighbor(direction)
	if not neighbor or elevation < neighbor.elevation:
		return

	remove_outgoing_river();
	if has_inccoming_river and incoming_river == direction:
		remove_incoming_river()
	
	_has_outgoing_river = true
	_outgoing_river = direction


	neighbor.remove_incoming_river()
	neighbor.has_inccoming_river = true
	neighbor.incoming_river = Enums.opposite(direction)

	set_road(direction, false)
#endregion


func has_road_through_edge (direction : Enums.HexDirection) -> bool:
	return roads[direction]


func remove_roads() -> void:
	for i in range(neighbors.size()):
		if roads[i]:
			roads[i] = false
			neighbors[i].roads[Enums.opposite(i)] = false
			neighbors[i].refresh_self_only()
			refresh_self_only()


func add_road ( direction : Enums.HexDirection) -> void:
	if not roads[direction] and not has_river_through_edge(direction) and get_elevation_difference(direction) <= 1:
		set_road(direction, true)


func set_road ( index : int, state : bool):
		roads[index] = state
		neighbors[index].roads[Enums.opposite(index)] = state
		neighbors[index].refresh_self_only()
		refresh_self_only()


func update_distance_label(speed: int):
	if distance == -1:
		turn_label.hide()
	else:
		turn_label.show()
		var turn = (distance - 1) / speed
		turn_label.text = str(turn)

func is_position_safe(offset: Vector3) -> bool:
	# Convert the offset to a direction/angle
	var angle = atan2(offset.x, offset.z)
	# Map angle to 0..5 HexDirection
	var dir = int(floor(remap(angle, -PI, PI, 0, 6))) % 6
	
	# If the cell has a road in that direction, it's not safe
	if has_road_through_edge(dir):
		return false
	# If the cell has a river in that direction, it's not safe
	if has_river_through_edge(dir):
		return false
		
	return true

func get_elevation_difference ( direction: Enums.HexDirection)-> int:
	var neighbor : HexCell = get_neighbor(direction as int)
	if neighbor:
		var difference : int = elevation - neighbor.elevation
		return difference if difference >= 0 else -difference
	else:
		return -1



func input_pickable() -> bool:
	return true


func  get_edge_type (direction : Enums.HexDirection)-> Enums.HexEdgeType:
	return HexMetrics.get_edge_type(
		elevation, neighbors[direction].elevation
	)


func get_edge_type_other_cell (otherCell: HexCell) -> Enums.HexEdgeType:
	return HexMetrics.get_edge_type(
			elevation, otherCell.elevation
		)

func set_walakble(value : bool):
	_walkable = value


func try_add_hex_object(hex_object : HexObject, adjust_position : bool) -> bool:
	if current_hex_objects.has(hex_object):
		return false
	
	if adjust_position:
		hex_object.position = world_position
	
	hex_object.hex_cell = self
	current_hex_objects.append(hex_object)
	return true 
