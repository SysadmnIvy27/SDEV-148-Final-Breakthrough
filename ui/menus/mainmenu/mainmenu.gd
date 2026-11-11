extends Control

const debug_level_Path : String = "res://levels/testing_level/testing_lvl.tscn"

@onready var menu = $menu
@onready var loading = $loading
@onready var loading_bar: ProgressBar = $loading/VBoxContainer/Loading_Bar
@onready var timer_load: Timer = $Timer_Load
@onready var ip_textbox: LineEdit = $menu/VBoxContainer/ip_textbox

signal start_game

var peer : MultiplayerPeer =  OfflineMultiplayerPeer.new()
var ip_address = "127.0.0.1"
var port = 42069
var max_clients = 4
var resource : ResourceLoader

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if loading.visible:
		var progress : Array = []
		var status = ResourceLoader.load_threaded_get_status(debug_level_Path,progress)
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
			

func _on_debug_level_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	menu.hide()
	loading.show()
	peer.create_server(port, max_clients)
	ResourceLoader.load_threaded_request(debug_level_Path,"",true)

func _on_connect_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_textbox.text,port)
	menu.hide()
	loading.show()
	ResourceLoader.load_threaded_request(debug_level_Path,"",true)

func _on_timer_load_timeout() -> void:
	multiplayer.multiplayer_peer = peer
	emit_signal("start_game",ResourceLoader.load_threaded_get(debug_level_Path))
