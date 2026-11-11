extends Node

@export var mainmenu : PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_scene_to_packed(mainmenu)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func new_game(packscene : PackedScene):
	call_deferred("change_scene_to_packed",packscene)

func change_scene_to_packed(packscene : PackedScene):
	var node : Node = packscene.instantiate()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_child(node)
	if node.has_signal(&"start_game"):
		node.start_game.connect(new_game)
