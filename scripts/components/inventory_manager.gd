extends Node

@onready var owner_entity = get_parent()
@export var slots = 8
@export var debug = false
@export var inventory = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# inventory setup
	for slot in slots:
		var slot_id = "slot" + str(slot)
		inventory[slot_id] = {}
		inventory[slot_id]["item"] = ""
		inventory[slot_id]["amount"] = 0
	if debug:
		print(owner_entity.name)
		print(inventory)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@rpc("authority","call_remote")
func add_item(item : Node) -> bool:
	if item.item_name in Itemregistry.item_dict: # checks to see if the item exists in the game items dictionary
		var added_item = false
		for slot in inventory:
			if inventory[slot]["item"] == item.item_name and not added_item:
				inventory[slot]["amount"] += 1
				added_item = true
				if debug:
					print(inventory)
				return true
		if not added_item:
			for slot in inventory:
				if inventory[slot]["item"] == "":
					inventory[slot]["item"] = item.item_name
					inventory[slot]["amount"] += 1
					if debug:
						print(inventory)
					return true
	print("Inventory full")
	if debug:
		print(inventory)
	return false
