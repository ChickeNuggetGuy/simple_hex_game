extends Manager

var _managers : Dictionary [String, Manager]


func _ready() -> void:
	
	call_deferred("setup_call")


func get_manager_name() -> String: return "GameManager"

func _setup():
	var managers = get_tree().get_nodes_in_group("managers")
	
	if managers.is_empty():
		push_error("No managers found in scene!")
		return
	
	for manager_node in managers:
		if manager_node is Manager:
			add_manager(manager_node) 
	
	call_deferred("execute_call")
	

func _execute():
	for manager_key in _managers:
		var manager : Manager = _managers[manager_key]
		
		if manager == self:
			#needed to prevent infinite recursion!
			continue
		print("GameManager: Setting up: " + manager.get_manager_name())
		await manager.setup_call()

	for manager_key in _managers:
		var manager : Manager = _managers[manager_key]
		
		if manager == self:
			#needed to prevent infinite recursion!
			continue
		print("GameManager: executing: " + manager.get_manager_name())
		await manager.execute_call()



func add_manager(manager : Manager):
	if _managers.has(manager.get_manager_name()):
		push_error("Manager with name: " + manager.get_manager_name() + " already exists!")
		return
	
	_managers[manager.get_manager_name()] = manager


func get_manager(manager_name : String) -> Manager:
	if not _managers.has(manager_name):
		return null
	
	return _managers.get(manager_name)
