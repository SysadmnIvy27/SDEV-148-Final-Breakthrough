class_name PlayerInputSyncronizer
extends MultiplayerSynchronizer

@export var motion := Vector2()
@export var jumping : bool
@export var sprinting : bool
@export var player_first_load : bool = false
@export var camera : Camera3D
@export var player : Node
@export var neck : Node3D
@export var interact_ray : RayCast3D
@export var color_rect: ColorRect
@export var helper_label : Label
@export var inventory_controller : Node
@export var inventory_manager : GameInventoryManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_multiplayer_authority() == multiplayer.get_unique_id(): #
		camera.make_current()
		if !player_first_load:
			color_rect.show()
			var load_tween = get_tree().create_tween()
			load_tween.tween_property(color_rect, "modulate", Color(0.0, 0.0, 0.0, 0.0), 3.0)
			await load_tween.finished
			player_first_load = true
	else:
		set_process(false)
		set_process_input(false)
		color_rect.hide()
		helper_label.hide()
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player.lock_movement: return
	motion = Input.get_vector("left", "right", "forward", "backward").normalized()
	if Input.is_action_just_pressed("jump"):
		jump.rpc()
	if motion and Input.is_action_pressed("sprint"):
		sprint.rpc()
	else:
		sprinting = false
	if interact_ray.is_colliding() and interact_ray.get_collider().is_in_group("items"):
		helper_label.show()
		if Input.is_action_just_pressed("interact"):
			var entity_name : String = interact_ray.get_collider().name
			if multiplayer.is_server():
				pickup_request(entity_name)
			else:
				pickup_request.rpc_id(1,entity_name)
#			inventory_manager.pickup_entity.rpc(entity, player)
	else:
		helper_label.hide()
	
	
func _input(event: InputEvent) -> void:
	if player.lock_movement: return
	if event is InputEventMouseMotion and GameGlobals.mouse_is_controling:
		# mouse movement
		neck.rotate_x(deg_to_rad(-event.relative.y * GameGlobals.mouse_sens))
		get_node(^"..").rotate_y(deg_to_rad(-event.relative.x * GameGlobals.mouse_sens))
		neck.rotation_degrees.x = clampf(neck.rotation_degrees.x,-90,90)
	
	
@rpc("call_local")
func jump():
	jumping = true
	
@rpc("call_local")
func sprint():
	sprinting = true

@rpc("any_peer")
func pickup_request(entity_name : String):
	print("Item call")
	inventory_manager.pickup_entity(entity_name, player)
