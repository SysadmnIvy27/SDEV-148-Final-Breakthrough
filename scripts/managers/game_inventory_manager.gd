class_name GameInventoryManager
extends Node

@export var spawnpath : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@rpc("any_peer")
func pickup_entity(entity_name : String, target_entity : Node):
	print("Item request recieved")
	var entity
	for child in spawnpath.get_children():
		if child.name == entity_name:
			entity = child
	if entity.is_inside_tree() and entity.is_in_group("items"):
		var item_collected = target_entity.inventory_controller.add_item(entity)
		if item_collected:
			entity.queue_free()
