extends Control

#const debug_level_Path : String = "res://levels/testing_level/testing_lvl.tscn"
var gamepath : String
const game_types = {"debug" : {"path" : "res://levels/testing_level/testing_lvl.tscn"}}

@onready var menu = $menu
@onready var loading = $loading
@onready var loading_bar: ProgressBar = $loading/VBoxContainer/Loading_Bar
@onready var timer_load: Timer = $Timer_Load
@onready var ip_textbox: LineEdit = $menu/VBoxContainer/ip_textbox

@onready var serverlist: VBoxContainer = $servers/servers/Server_list/ScrollContainer/serverlist

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
			dict["ip"] = data.get_packet_ip()
			var added_server = false
			for child in serverlist.get_children():
				if child.name == ("server_" + dict["ip"]):
					added_server = true
			if !added_server:
				add_entry(dict)
			print(dict)

func _on_debug_level_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	menu.hide()
	loading.show()
	peer.create_server(game_port, max_clients)
	gamepath = game_types["debug"]["path"]
	ResourceLoader.load_threaded_request(gamepath,"",true)

func _on_connect_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_textbox.text, game_port)
	menu.hide()
	loading.show()
	if !gamepath:
		gamepath = game_types["debug"]["path"]
	ResourceLoader.load_threaded_request(gamepath,"",true)

func _on_timer_load_timeout() -> void:
	multiplayer.multiplayer_peer = peer
	emit_signal("start_game",ResourceLoader.load_threaded_get(gamepath))

func add_entry(data): # data = game_info = {"GameType" : game_type, "max_players" : max_players, "current_players" : num_players, "ip" : ip_address}
	# making required controls
	var connection_box = HBoxContainer.new()
	var host_label = Label.new()
	var type_label = Label.new()
	var player_count = Label.new()
	var connect_button = Button.new()
	# setting up container
	connection_box.name = ("server_" + data["ip"])
	host_label.text = data["ip"]
	type_label.text = data["GameType"]
	player_count.text = (data["current_players"] + " / " + data["max_players"])
	#player_count.
