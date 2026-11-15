extends Node
class_name base_pickup

@export var item_name = ""
@export var attributes = {}
@export var icon : Texture2D

@rpc("any_peer","call_local")
func pickup(entity):
	entity.add_item(item_name)
	queue_free()
	
func on_use(_entity):
	push_warning("on_use() is undefined for" + item_name + "and will do nothing when used, please redefine.")
