extends Control

var gamepath : String
const game_types = {"debug" : {"path" : "res://levels/testing_level/testing_lvl.tscn"}}

# menu ui elements
@onready var menu = $menu
@onready var loading = $loading
@onready var loading_bar: ProgressBar = $loading/VBoxContainer/Loading_Bar
@onready var timer_load: Timer = $Timer_Load
# multiplayer ui elements
@onready var servers: Control = $servers
@onready var serverlist: VBoxContainer = $servers/servers/Server_list/ScrollContainer/serverlist

@export var entry_scene : PackedScene

signal start_game

var peer : MultiplayerPeer =  OfflineMultiplayerPeer.new()
var listen_peer = PacketPeerUDP.new()
var ip_address = "127.0.0.1"
var game_port : int = 42069
var listen_port : int = 6981
var max_clients : int = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	listen_peer.bind(listen_port)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if loading.visible:
		var progress : Array = []
		var status = ResourceLoader.load_threaded_get_status(gamepath ,progress)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			loading_bar.value = progress[0] * 100
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			loading_bar.value = 100.0
			set_process(false)
			timer_load.start()
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			print("An error occured")
			loading.hide()
			menu.show()
			listen_peer.close()
	else:
		if listen_peer.get_available_packet_count() > 0:
			var data = listen_peer.get_packet()
			var parsed_string = data.get_string_from_utf8()
			var dict = JSON.parse_string(parsed_string)
			dict["ip"] = listen_peer.get_packet_ip()
			print(dict)
			var added_server = false
			for child in serverlist.get_children():
				if child.ip == dict["ip"]:
					child.update_info(dict)
					added_server = true
			if !added_server:
				add_entry(dict)

func _on_debug_level_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	menu.hide()
	loading.show()
	peer.create_server(game_port, max_clients)
	gamepath = game_types["debug"]["path"]
	ResourceLoader.load_threaded_request(gamepath,"",true)

func _on_connect_pressed() -> void:
	menu.hide()
	servers.show()

func _on_timer_load_timeout() -> void:
	multiplayer.multiplayer_peer = peer
	emit_signal("start_game",ResourceLoader.load_threaded_get(gamepath))

func add_entry(data): # data = game_info = {"GameType" : game_type, "max_players" : max_players, "current_players" : num_players, "ip" : ip_address}
	var entry = entry_scene.instantiate()
	entry.ip = data["ip"]
	entry.game_type = data["GameType"]
	entry.num_players = data["current_players"]
	entry.max_players = data["max_players"]
	entry.join_game.connect(join_game)
	serverlist.add_child(entry)

func join_game(ip : String, gametype : String):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, game_port)
	menu.hide()
	servers.hide()
	loading.show()
	gamepath = game_types[gametype]["path"]
	ResourceLoader.load_threaded_request(gamepath,"",true)


func _on_back_button_pressed() -> void:
	servers.hide()
	menu.show()
