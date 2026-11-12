extends Node3D

@export var spawnable : bool = true
@export var spawn_marker : Marker3D
@export var spawned_player : CharacterBody3D
@export var anim : AnimationPlayer
@export var interior_collision : Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_join():
	spawnable = false
	spawned_player.lock_movement = true
	await get_tree().create_timer(4).timeout
	anim.play(&"open")
	await anim.animation_finished
	spawned_player.lock_movement = false
	await get_tree().create_timer(4).timeout
	spawned_player = null
	
func _on_player_leave():
	pass
