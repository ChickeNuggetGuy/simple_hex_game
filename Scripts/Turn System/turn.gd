extends Node
class_name Turn

@export var turn_segments : Array[TurnSegment]


func process(turn_manager : TurnManager):
	for turn_segment in turn_segments:
		if not turn_segment:
			continue
		
		await turn_segment.execute()
	
	turn_manager.request_end_of_turn()
