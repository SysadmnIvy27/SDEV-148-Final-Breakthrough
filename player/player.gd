class_name Player
extends CharacterBody3D

@onready var neck = $neck
@onready var chest_ray: RayCast3D = $ChestRay
@onready var step_ray: RayCast3D = $StepRay
@onready var server_sync : MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var player_input : PlayerInputSyncronizer = $InputSynchronizer
@onready var inventory_controller: Node = $inventory_controller

@export var current_speed = 5.0
@export var deceleration = 2.0
@export var mouse_sensivity = GameGlobals.mouse_sens
@export var lock_movement = false
@export var lock_interaction = false
@export var inventory_manager : GameInventoryManager
@export var player_id: int = 1:
	set(value):
		player_id = value
		$InputSynchronizer.set_multiplayer_authority(value)
	
	
const walk_speed = 5.0
const sprint_speed = 8.0
const jump_velocity = 4.5
const step_assist = 2.0
var motion := Vector2()
var drone : Node
	
func _ready() -> void:
	if not multiplayer.is_server():
		set_process(false)
	GameGlobals.mouse_is_controling = true
	player_input.inventory_manager = inventory_manager
	
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		apply_input(delta)

func apply_input(delta):
	# player movement
	motion = player_input.motion
	var dir := (transform.basis * Vector3(motion.x, 0, motion.y)).normalized()
	
	# Get the input direction and handle the movement/deceleration.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if player_input.jumping == true and is_on_floor() and not lock_movement:
		jump.rpc()
		player_input.jumping = false
	if player_input.sprinting == true and is_on_floor() and not lock_movement:
		sprint.rpc()
	else:
		current_speed = walk_speed
	#if not chest_ray.is_colliding() and step_ray.is_colliding() and Input.is_action_pressed("forward") and not lock_movement:
	#	position.y += 1
	if is_on_floor() and not lock_movement:
		if motion:
			velocity.x = dir.x * current_speed
			velocity.z = dir.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, deceleration)
			velocity.z = move_toward(velocity.z, 0, deceleration)
	
	move_and_slide()

@rpc("call_local")
func jump():
	velocity.y = jump_velocity
	
@rpc("call_local")
func sprint():
	current_speed = sprint_speed
	player_input.sprinting = false
