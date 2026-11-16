extends HBoxContainer

@onready var location: Label = $Location
@onready var world_type: Label = $World_Type
@onready var player_count: Label = $Player_Count
@onready var join_button: Button = $Join_Button
@onready var removal_timeout: Timer = $removal_timeout

@export var ip : String
@export var game_type : String
@export var max_players : int
@export var num_players : int
@export var persistant : bool

signal join_game

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	location.text = ip
	world_type.text = ("Game Type: " + game_type)
	player_count.text = str(str(num_players) + " / " + str(max_players))
	if !persistant:
		removal_timeout.timeout.connect(_on_removal_timeout_timeout)
		removal_timeout.start()
	
func update_info(data):
	location.text = data["ip"]
	world_type.text = ("Game Type: " + data["GameType"])
	player_count.text = str(str(int(data["current_players"])) + " / " + str(int(data["max_players"])))
	removal_timeout.start()
	
func _on_join_button_pressed() -> void:
	join_game.emit(ip, game_type)

func _on_removal_timeout_timeout() -> void:
	queue_free()
