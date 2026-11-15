extends Node

var item_dict = {}
var default_path = "res://entities/items/"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for dir in DirAccess.get_directories_at(default_path):
		var files_path = default_path + dir
		for file in DirAccess.get_files_at(files_path):
			if file.ends_with(".tscn"):
				var scene_path = default_path + dir + "/" + file
				var pack_scene = load(scene_path)
				var scene = pack_scene.instantiate()
				item_dict[scene.item_name] = scene.attributes
				item_dict[scene.item_name]["texture"] = scene.icon
				item_dict[scene.item_name]["packed_scene"] = pack_scene
				item_dict[scene.item_name]["path"] = scene_path
				scene.queue_free()
	print(item_dict)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
