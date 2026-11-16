extends Node3D

const Player_scene : PackedScene = preload("res://player/player.tscn")
const items : Array = ["debug_item", "debug_item", "debug_item"]
var game_info : Dictionary
var broadcast_peer : PacketPeerUDP = PacketPeerUDP.new()
var send_port : int = 6981
var max_players : int = 5
var num_players : int

@onready var spawned_nodes: Node3D = $Spawned_Nodes
@onready var player_spawn: Marker3D = $Player_spawn
@onready var inventory_manager: Node = $Game_Managers/inventory_manager
@onready var item_spawner: MultiplayerSpawner = $MultiplayerSpawnerItems
@export var game_type : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_spawnable_items()
	if multiplayer.is_server():
		game_info = {"GameType" : game_type, "max_players" : max_players, "current_players" : num_players}
		# setup broadcast peer
		broadcast_peer.set_broadcast_enabled(true)
		broadcast_peer.set_dest_address("255.255.255.255",send_port)
		ping()
		# adding player
		add_player(1,player_spawn)
		add_items()
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(rem_player)
	else:
		set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func add_player(id, marker : Marker3D = null):
	var target_pod = get_pod()
	if target_pod != null:
		marker = target_pod.spawn_marker
	else:
		marker = player_spawn
	var player : Player = Player_scene.instantiate()
	player.name = str(id)
	player.inventory_manager = inventory_manager
	player.player_id = id
	player.global_transform = marker.global_transform
	spawned_nodes.add_child(player)
	print("Player Joined")
	if marker != player_spawn:
		target_pod.spawned_player = player
		print("Pod triggered")
		target_pod._on_player_join()
	num_players += 1
	#print(player.global_transform) for debug
	#print(player_spawn.global_transform) for debug
	
func rem_player(id):
	if !is_multiplayer_authority(): return
	#print("Removing player with id: ", id) for debug
	for child in spawned_nodes.get_children():
		if child.name.to_int() == id:
			child.queue_free()
			num_players -= 1

func get_pod():
	for pod in $Spawn_Points.get_children():
		if pod.spawnable == true:
			return pod
	return null

func add_items():
	for item in items:
		var item_scene = Itemregistry.item_dict[item]["packed_scene"].instantiate()
		item_scene.global_transform = player_spawn.global_transform
		spawned_nodes.add_child(item_scene, true)

func add_spawnable_items():
	for item in Itemregistry.item_dict:
		item_spawner.add_spawnable_scene(Itemregistry.item_dict[item]["path"])

func ping():
	while true:
		await get_tree().create_timer(3).timeout
		game_info = {"GameType" : game_type, "max_players" : max_players, "current_players" : num_players}
		var serialized_info = JSON.stringify(game_info).to_utf8_buffer()
		broadcast_peer.put_packet(serialized_info)
		print("ping: " + str(game_info))
