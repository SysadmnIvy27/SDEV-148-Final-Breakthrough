extends Node3D

const Player_scene : PackedScene = preload("res://player/player.tscn")
@onready var spawned_nodes: Node3D = $Spawned_Nodes
@onready var player_spawn: Marker3D = $Player_spawn


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		add_player(1,player_spawn)
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(rem_player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func add_player(id, marker : Marker3D = null):
	var target_pod = get_pod()
	if target_pod != null:
		marker = target_pod.spawn_marker
	else:
		marker = player_spawn
	var player : CharacterBody3D = Player_scene.instantiate()
	player.name = str(id)
	player.player_id = id
	player.global_transform = marker.global_transform
	spawned_nodes.add_child(player)
	print("Player Joined")
	if marker != player_spawn:
		target_pod.spawned_player = player
		print("Pod triggered")
		target_pod._on_player_join()
	#print(player.global_transform) for debug
	#print(player_spawn.global_transform) for debug
	
func rem_player(id):
	if !is_multiplayer_authority(): return
	#print("Removing player with id: ", id) for debug
	for child in spawned_nodes.get_children():
		if child.name.to_int() == id:
			child.queue_free()

func get_pod():
	for pod in $Spawn_Points.get_children():
		if pod.spawnable == true:
			return pod
	return null
	
